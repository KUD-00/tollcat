import Foundation
import MeterCore

/// Bring / Posten Norge 发票归档（`GET /invoicearchive/api/invoices/{customerNumber}.json`）。
///
/// 文档：https://developer.bring.com/api/invoice/
/// 认证：`X-Mybring-API-Uid` + `X-Mybring-API-Key` + `X-Bring-Client-URL`。
/// Host：`www.mybring.com`。
/// 金额：`totalAmount`（回退 `amount`）+ `currency`；日期 `invoiceDate`（常为 `dd.mm.yyyy`）。
/// 凭据：`email` + `apiKey` + `accountID`（customerNumber）。贷项单可为负，按符号计入净支出。
public struct BringBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.bring }
    public static let apiHost = "www.mybring.com"
    public static let clientURL = "https://tollcat.app"

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar
    public var rateSource: SharedExchangeRates

    public init(
        httpClient: any HTTPClient,
        now: @escaping @Sendable () -> Date,
        calendar: Calendar,
        rateSource: SharedExchangeRates
    ) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
        self.rateSource = rateSource
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let email = try RequiredCredential.value(.email, in: credential, providerID: .bring)
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .bring)
        let customer = try RequiredCredential.value(.accountID, in: credential, providerID: .bring)
        let headers = [
            "X-Mybring-API-Uid": email,
            "X-Mybring-API-Key": apiKey,
            "X-Bring-Client-URL": Self.clientURL,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let from: Date
        let to: Date
        if horizon == .availableHistory {
            let lookback = max(1, Self.descriptor.historyLookbackMonths)
            from = calendar.date(byAdding: .month, value: -(lookback - 1), to: current.start) ?? current.start
            to = current.endInclusive
        } else {
            from = current.start
            to = current.endInclusive
        }

        let invoices = try await loadInvoices(
            customer: customer,
            from: from,
            to: to,
            headers: headers
        )
        for inv in invoices {
            let amount = inv.totalAmount?.value ?? inv.amount?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe(inv.currency, providerID: .bring)
            let stamp = inv.invoiceDate.flatMap { Self.parseBringDate($0, calendar: calendar) }
                ?? inv.dueDate.flatMap { Self.parseBringDate($0, calendar: calendar) }
                ?? current.start
            let label = inv.invoiceNumber ?? inv.type ?? "invoice"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: inv.type ?? inv.status ?? "invoice",
                        label: label,
                        amountUSD: Money(usd: amount)
                    )
                )
            } else if horizon == .availableHistory {
                daily.addPastMonth(
                    start: stamp,
                    amount: Money(usd: amount),
                    current: current,
                    calendar: calendar
                )
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .bring
        )
        return Snapshot(
            providerID: .bring,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: converted.money,
            dailyUSD: currencies.scaled(daily.snapshotDaily, by: converted.usdPerUnit),
            converted: currencies.needsConversionNote ? converted : nil,
            lines: lines.snapshot
        )
    }

    private func loadInvoices(
        customer: String,
        from: Date,
        to: Date,
        headers: [String: String]
    ) async throws -> [Invoice] {
        let url = ProviderURL.https(
            host: Self.apiHost,
            path: "/invoicearchive/api/invoices/\(customer).json",
            query: [
                URLQueryItem(name: "fromDate", value: Self.formatBringDate(from, calendar: calendar)),
                URLQueryItem(name: "toDate", value: Self.formatBringDate(to, calendar: calendar)),
            ]
        )
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .bring
        )
        if let env = try? ProviderHTTP.decode(Envelope.self, from: data, providerID: .bring) {
            return env.invoices ?? []
        }
        return try ProviderHTTP.decode([Invoice].self, from: data, providerID: .bring)
    }

    /// `dd.mm.yyyy` 或 ISO / `yyyy-MM-dd`。
    static func parseBringDate(_ raw: String, calendar: Calendar) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let iso = BillingDateParser.parse(trimmed, calendar: calendar) {
            return iso
        }
        let parts = trimmed.split(separator: ".")
        guard parts.count >= 3,
              let day = Int(parts[0]),
              let month = Int(parts[1]),
              let year = Int(parts[2].prefix(4)) else {
            return nil
        }
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
            .map { calendar.startOfDay(for: $0) }
    }

    static func formatBringDate(_ date: Date, calendar: Calendar) -> String {
        let y = calendar.component(.year, from: date)
        let m = calendar.component(.month, from: date)
        let d = calendar.component(.day, from: date)
        return String(format: "%02d.%02d.%04d", d, m, y)
    }

    struct Envelope: Decodable, Sendable {
        var invoices: [Invoice]?
        var status: String?
    }

    struct Invoice: Decodable, Sendable {
        var amount: FlexibleDecimal?
        var totalAmount: FlexibleDecimal?
        var currency: String?
        var invoiceDate: String?
        var dueDate: String?
        var invoiceNumber: String?
        var type: String?
        var status: String?
    }
}
