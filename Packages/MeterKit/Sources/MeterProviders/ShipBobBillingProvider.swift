import Foundation
import MeterCore

/// ShipBob 履约账单发票（`GET /2026-07/invoices`）。
///
/// 文档：https://developer.shipbob.com/guides/billing
/// 认证：`Authorization: Bearer <PAT>`（需 `billing_read` scope）。
/// Host：`api.shipbob.com`。
/// 金额：`amount` + `currency_code`。按 `invoice_date` 归入本月；只累计正金额（排除 Payment 贷记）。
public struct ShipBobBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.shipbob }
    public static let apiHost = "api.shipbob.com"
    public static let apiVersion = "2026-07"
    static let maxPages = 20

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
        let token: String
            if let primary = try? RequiredCredential.value(.personalAccessToken, in: credential, providerID: .shipbob) {
                token = primary
            } else {
                token = try RequiredCredential.value(.apiKey, in: credential, providerID: .shipbob)
            }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let lookbackStart: Date = {
            var comps = calendar.dateComponents([.year, .month], from: current.start)
            comps.month = (comps.month ?? 1) - 11
            return calendar.date(from: comps) ?? current.start
        }()
        let fromDate = horizon == .availableHistory ? lookbackStart : current.start
        let toDate = current.endInclusive

        var page = 1
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let batch = try await loadInvoices(
                from: fromDate,
                to: toDate,
                page: page,
                headers: headers
            )
            if batch.isEmpty { break }
            for inv in batch {
                let amount = inv.amount?.value ?? 0
                guard amount > 0 else { continue }
                try currencies.observe(inv.currency_code, providerID: .shipbob)
                let stamp = inv.invoice_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = inv.invoice_type
                    ?? inv.invoice_id.map(String.init)
                    ?? "invoice"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: "invoice",
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
            if batch.count < 100 { break }
            page += 1
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .shipbob
        )
        return Snapshot(
            providerID: .shipbob,
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
        from: Date,
        to: Date,
        page: Int,
        headers: [String: String]
    ) async throws -> [Invoice] {
        let url = Self.invoicesURL(from: from, to: to, page: page)
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .shipbob
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .shipbob) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .shipbob)
        return envelope.items ?? envelope.invoices ?? envelope.data ?? []
    }

    static func invoicesURL(from: Date, to: Date, page: Int) -> URL {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        fmt.dateFormat = "yyyy-MM-dd"
        return ProviderURL.https(
            host: apiHost,
            path: "/\(apiVersion)/invoices",
            query: [
                URLQueryItem(name: "FromDate", value: fmt.string(from: from)),
                URLQueryItem(name: "ToDate", value: fmt.string(from: to)),
                URLQueryItem(name: "Page", value: String(page)),
                URLQueryItem(name: "PageSize", value: "100"),
            ]
        )
    }

    struct InvoiceList: Decodable, Sendable {
        var items: [Invoice]?
        var invoices: [Invoice]?
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var invoice_id: Int?
        var invoice_date: String?
        var invoice_type: String?
        var amount: FlexibleDecimal?
        var currency_code: String?
    }
}
