import Foundation
import MeterCore

/// Domeneshop 本月发票合计（金额 + 币种，通常 NOK）。
///
/// 文档：`GET https://api.domeneshop.no/v0/invoices` → `amount` + `currency`。
/// 认证：HTTP Basic，`token:secret`（`accessKeyID` + `secretAccessKey`）。
/// 仅过去 3 年发票；用 `issued_date`（回退 `paid_date` / `due_date`）归入月份。
public struct DomeneshopBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.domeneshop }

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
        let token = try RequiredCredential.value(.accessKeyID, in: credential, providerID: .domeneshop)
        let secret = try RequiredCredential.value(.secretAccessKey, in: credential, providerID: .domeneshop)
        let headers = [
            "Authorization": "Basic \(ProviderOAuth.basicValue(id: token, secret: secret))",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadInvoices(headers: headers)
        for invoice in invoices {
            try currencies.observe(invoice.currency, providerID: .domeneshop)
            let amount = invoice.amount?.value ?? 0
            guard amount != 0 else { continue }
            let stamp = invoice.issued_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? invoice.paid_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? invoice.due_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            if current.contains(stamp) {
                currentTotal += amount
                let label = invoice.type?.trimmed ?? "invoice"
                lines.add(
                    SpendLine(
                        category: invoice.status?.trimmed ?? "invoice",
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

        let converted = try currencies.convert(currentTotal, rates: rateSource.current, providerID: .domeneshop)
        return Snapshot(
            providerID: .domeneshop,
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

    private func loadInvoices(headers: [String: String]) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.listURL,
            headers: headers,
            client: httpClient,
            providerID: .domeneshop
        )
        return try ProviderHTTP.decode([Invoice].self, from: data, providerID: .domeneshop)
    }

    static let listURL = ProviderURL.https(
        host: "api.domeneshop.no",
        path: "/v0/invoices"
    )

    struct Invoice: Decodable, Sendable {
        var id: FlexibleDecimal?
        var type: String?
        var amount: FlexibleDecimal?
        var currency: String?
        var due_date: String?
        var issued_date: String?
        var paid_date: String?
        var status: String?
        var url: String?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
