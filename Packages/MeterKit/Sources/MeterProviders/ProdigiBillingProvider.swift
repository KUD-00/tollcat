import Foundation
import MeterCore

/// Prodigi 本月订单收费合计。
///
/// 文档：`GET /v4.0/orders`
/// 认证：`X-API-Key`。
///
/// `charges[].totalCost.amount` + `currency`；Refund 类 charge 是负数/冲减。
/// Quote 不是实付，不进合计。
public struct ProdigiBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.prodigi }
    public static let pageSize = 50
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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .prodigi)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        var total = Decimal(0)
        var currencies = CurrencyAccumulator()
        var skip = 0
        var pages = 0

        while pages < Self.maxPages {
            pages += 1
            let data = try await ProviderHTTP.get(
                url: Self.ordersURL(from: window.start, to: window.nextStart, top: Self.pageSize, skip: skip),
                headers: ["X-API-Key": apiKey],
                client: httpClient,
                providerID: .prodigi
            )
            let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .prodigi)
            let orders = payload.orders ?? []
            for order in orders {
                for charge in order.charges ?? [] {
                    guard let amount = charge.totalCost?.amount?.value else { continue }
                    try currencies.observe(charge.totalCost?.currency, providerID: .prodigi)
                    total += amount
                }
            }
            if orders.count < Self.pageSize { break }
            skip += Self.pageSize
        }

        let converted = try currencies.convert(total, rates: rateSource.current, providerID: .prodigi)
        return Snapshot(
            providerID: .prodigi,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: converted.money,
            converted: currencies.needsConversionNote ? converted : nil
        )
    }

    static func ordersURL(from: Date, to: Date, top: Int, skip: Int) -> URL {
        let fmt = ISO8601DateFormatter()
        return ProviderURL.https(
            host: "api.prodigi.com",
            path: "/v4.0/orders",
            query: [
                URLQueryItem(name: "createdFrom", value: fmt.string(from: from)),
                URLQueryItem(name: "createdTo", value: fmt.string(from: to)),
                URLQueryItem(name: "top", value: String(top)),
                URLQueryItem(name: "skip", value: String(skip)),
            ]
        )
    }

    struct Envelope: Decodable, Sendable {
        var orders: [Order]?
    }

    struct Order: Decodable, Sendable {
        var id: String?
        var charges: [Charge]?
    }

    struct Charge: Decodable, Sendable {
        var id: String?
        var type: String?
        var totalCost: MoneyAmount?
    }

    struct MoneyAmount: Decodable, Sendable {
        var amount: FlexibleDecimal?
        var currency: String?
    }
}
