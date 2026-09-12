import Foundation
import MeterCore

/// Servers.com 账户发票（`GET /v1/billing/invoices`）。
///
/// 文档：https://www.servers.com/docs/api-reference/invoice/list-invoices/
/// 认证：`Authorization: Bearer <JWT>`（Portal → Identity and Access → API tokens）。
/// Host：`api.servers.com`。
/// 金额：`total_due` + `currency`（ISO 4217）。只累计 `type == invoice` 且正金额（排除 credit_note）。
public struct ServersComBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.serverscom }
    public static let apiHost = "api.servers.com"
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
        if let primary = try? RequiredCredential.value(.personalAccessToken, in: credential, providerID: .serverscom) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .serverscom)
        }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
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

        var page = 1
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let batch = try await loadInvoices(from: fromDate, to: current.endInclusive, page: page, headers: headers)
            if batch.isEmpty { break }
            for inv in batch {
                if let kind = inv.type?.lowercased(), kind == "credit_note" { continue }
                let amount = inv.total_due?.value ?? 0
                guard amount > 0 else { continue }
                try currencies.observe(inv.currency, providerID: .serverscom)
                let stamp = inv.date.flatMap { BillingDateParser.parse($0, calendar: calendar) } ?? current.start
                let label = inv.number.map(String.init) ?? inv.id ?? "invoice"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: inv.status ?? "invoice",
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
            providerID: .serverscom
        )
        return Snapshot(
            providerID: .serverscom,
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
            url: url, headers: headers, client: httpClient, providerID: .serverscom
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .serverscom) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .serverscom)
        return envelope.invoices ?? envelope.data ?? envelope.items ?? []
    }

    static func invoicesURL(from: Date, to: Date, page: Int) -> URL {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        fmt.dateFormat = "yyyy-MM-dd"
        return ProviderURL.https(
            host: apiHost,
            path: "/v1/billing/invoices",
            query: [
                URLQueryItem(name: "type", value: "invoice"),
                URLQueryItem(name: "start_date", value: fmt.string(from: from)),
                URLQueryItem(name: "end_date", value: fmt.string(from: to)),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: "100"),
                URLQueryItem(name: "sorting", value: "date"),
                URLQueryItem(name: "direction", value: "DESC"),
            ]
        )
    }

    struct InvoiceList: Decodable, Sendable {
        var invoices: [Invoice]?
        var data: [Invoice]?
        var items: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var number: Int?
        var parent_id: String?
        var status: String?
        var date: String?
        var type: String?
        var total_due: FlexibleDecimal?
        var currency: String?
    }
}
