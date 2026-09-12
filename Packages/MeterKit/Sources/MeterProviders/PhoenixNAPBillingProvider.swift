import Foundation
import MeterCore

/// phoenixNAP 客户发票（`GET /invoices`）。
///
/// 文档：https://developers.phoenixnap.com/docs/invoicing/1/overview
/// OpenAPI 模型：`amount` + `currency`（EUR/USD），`sentOn` 归入本月。
/// 认证：OAuth2 client_credentials（BMC realm）→ Bearer；scope `invoices.read`。
/// Host：`api.phoenixnap.com`；换票：`auth.phoenixnap.com`。
/// 凭据：`clientID` + `clientSecret`（BMC API Client）。
public struct PhoenixNAPBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.phoenixnap }
    public static let apiHost = "api.phoenixnap.com"
    static let maxPages = 20
    static let pageSize = 100

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
        let clientID = try RequiredCredential.value(.clientID, in: credential, providerID: .phoenixnap)
        let clientSecret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .phoenixnap)
        let token = try await ProviderOAuth.clientCredentialsToken(
            url: Self.tokenURL,
            basic: (id: clientID, secret: clientSecret),
            form: [
                "grant_type": "client_credentials",
                "scope": "invoices.read",
            ],
            client: httpClient,
            providerID: .phoenixnap
        )
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var offset = 0
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let batch = try await loadInvoices(offset: offset, headers: headers)
            if batch.isEmpty { break }
            for inv in batch {
                let amount = inv.amount?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(inv.currency, providerID: .phoenixnap)
                let stamp = inv.sentOn.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.dueDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = inv.number ?? inv.id ?? "invoice"
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
            if batch.count < Self.pageSize { break }
            offset += Self.pageSize
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .phoenixnap
        )
        return Snapshot(
            providerID: .phoenixnap,
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
        offset: Int,
        headers: [String: String]
    ) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL(offset: offset),
            headers: headers,
            client: httpClient,
            providerID: .phoenixnap
        )
        let page = try ProviderHTTP.decode(PaginatedInvoices.self, from: data, providerID: .phoenixnap)
        return page.results ?? []
    }

    static let tokenURL = ProviderURL.https(
        host: "auth.phoenixnap.com",
        path: "/auth/realms/BMC/protocol/openid-connect/token"
    )

    static func invoicesURL(offset: Int) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/invoicing/v1/invoices",
            query: [
                URLQueryItem(name: "limit", value: String(pageSize)),
                URLQueryItem(name: "offset", value: String(offset)),
                URLQueryItem(name: "sortField", value: "sentOn"),
                URLQueryItem(name: "sortDirection", value: "DESC"),
            ]
        )
    }

    struct PaginatedInvoices: Decodable, Sendable {
        var results: [Invoice]?
        var limit: Int?
        var offset: Int?
        var total: Int?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var number: String?
        var currency: String?
        var amount: FlexibleDecimal?
        var outstandingAmount: FlexibleDecimal?
        var status: String?
        var sentOn: String?
        var dueDate: String?
    }
}
