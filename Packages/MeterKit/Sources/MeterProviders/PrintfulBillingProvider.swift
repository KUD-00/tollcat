import Foundation
import MeterCore

/// Printful 本月履约成本合计。
///
/// 文档：`GET /orders`（v1）每单 `costs.total` + `costs.currency`
/// 认证：`Authorization: Bearer <token>`。
///
/// 只计 Printful 向商户收取的 `costs`（不是 `retail_costs`）。按 `created` 落在本月的订单相加。
public struct PrintfulBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.printful }
    public static let maxPages = 20
    public static let pageSize = 100

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
        let token = try RequiredCredential.value(.apiKey, in: credential, providerID: .printful)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var total = Decimal(0)
        var offset = 0
        var pages = 0

        while pages < Self.maxPages {
            pages += 1
            let data = try await ProviderHTTP.get(
                url: Self.ordersURL(offset: offset),
                headers: [
                    "Authorization": "Bearer \(token)",
                ],
                client: httpClient,
                providerID: .printful
            )
            let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .printful)
            let orders = payload.result ?? []
            var sawOlder = false
            for order in orders {
                let created = order.created.map { Date(timeIntervalSince1970: TimeInterval($0)) }
                if let created, created < window.start {
                    sawOlder = true
                    continue
                }
                if let created, created >= window.nextStart { continue }
                guard let amount = order.costs?.total?.value else { continue }
                try currencies.observe(order.costs?.currency, providerID: .printful)
                total += amount
            }
            let paging = payload.paging
            offset += orders.count
            let totalItems = paging?.total ?? 0
            if orders.isEmpty || offset >= totalItems || sawOlder { break }
        }

        let converted = try currencies.convert(total, rates: rateSource.current, providerID: .printful)
        return Snapshot(
            providerID: .printful,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: converted.money,
            converted: currencies.needsConversionNote ? converted : nil
        )
    }

    static func ordersURL(offset: Int) -> URL {
        ProviderURL.https(
            host: "api.printful.com",
            path: "/orders",
            query: [
                URLQueryItem(name: "limit", value: String(pageSize)),
                URLQueryItem(name: "offset", value: String(offset)),
            ]
        )
    }

    struct Envelope: Decodable, Sendable {
        var result: [Order]?
        var paging: Paging?
    }

    struct Paging: Decodable, Sendable {
        var total: Int?
    }

    struct Order: Decodable, Sendable {
        var id: FlexibleDecimal?
        var created: Int?
        var costs: Costs?
    }

    struct Costs: Decodable, Sendable {
        var total: FlexibleDecimal?
        var currency: String?
    }
}
