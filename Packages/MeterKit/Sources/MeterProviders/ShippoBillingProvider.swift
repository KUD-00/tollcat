import Foundation
import MeterCore

/// Shippo 本月已购标签运费合计。
///
/// 文档：`GET /transactions?expand=rate`（可按 `object_created_gte` / `object_created_lt` 窗）
/// 认证：`Authorization: ShippoToken <API_TOKEN>`。
///
/// 展开后的 `rate.amount` + `rate.currency` 按币种折美元后相加。
public struct ShippoBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.shippo }
    public static let maxPages = 20

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
        let now = now()
        let token = try RequiredCredential.value(.apiKey, in: credential, providerID: .shippo)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var total = Decimal(0)
        var page = 1
        var pages = 0

        while pages < Self.maxPages {
            pages += 1
            let data = try await ProviderHTTP.get(
                url: Self.transactionsURL(page: page, window: window),
                headers: [
                    "Authorization": "ShippoToken \(token)",
                ],
                client: httpClient,
                providerID: .shippo
            )
            let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .shippo)
            let results = payload.results ?? []
            for tx in results {
                guard let amount = tx.rate?.amount?.value else { continue }
                try currencies.observe(tx.rate?.currency, providerID: .shippo)
                total += amount
            }
            let next = payload.next
            if results.isEmpty || next == nil || next?.isEmpty == true { break }
            page += 1
        }

        let converted = try currencies.convert(total, rates: rateSource.current, providerID: .shippo)
        return Snapshot(
            providerID: .shippo,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: converted.money,
            converted: currencies.needsConversionNote ? converted : nil
        )
    }

    static func transactionsURL(page: Int, window: CalendarMonthWindow) -> URL {
        let fmt = ISO8601DateFormatter()
        return ProviderURL.https(
            host: "api.goshippo.com",
            path: "/transactions",
            query: [
                URLQueryItem(name: "expand", value: "rate"),
                URLQueryItem(name: "object_created_gte", value: fmt.string(from: window.start)),
                URLQueryItem(name: "object_created_lt", value: fmt.string(from: window.nextStart)),
                URLQueryItem(name: "results", value: "100"),
                URLQueryItem(name: "page", value: String(page)),
            ]
        )
    }

    struct Envelope: Decodable, Sendable {
        var results: [Transaction]?
        var next: String?
    }

    struct Transaction: Decodable, Sendable {
        var object_id: String?
        var rate: Rate?
    }

    struct Rate: Decodable, Sendable {
        var amount: FlexibleDecimal?
        var currency: String?
    }
}
