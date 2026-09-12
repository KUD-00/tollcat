import Foundation
import MeterCore

/// Gelato 本月订单实付合计。
///
/// 文档：`POST /v4/orders:search` + `GET /v4/orders/{id}`
/// 认证：`X-API-KEY`。
///
/// 先按本月 `orderedAt` 搜订单，再读每单 `receipts`：`purchase` 计入，`refund` 冲减；
/// 金额优先 `totalInclVat`，否则 `total`，按 receipt 币种折美元。
public struct GelatoBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.gelato }
    public static let maxOrders = 50

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .gelato)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let headers = [
            "X-API-KEY": apiKey,
            "Content-Type": "application/json",
        ]
        let body = try JSONSerialization.data(withJSONObject: [
            "orderTypes": ["order"],
            "orderedAtMin": Self.iso8601(window.start),
            "orderedAtMax": Self.iso8601(window.nextStart),
        ])
        let searchData = try await ProviderHTTP.post(
            url: Self.searchURL,
            headers: headers,
            body: body,
            client: httpClient,
            providerID: .gelato
        )
        let search = try ProviderHTTP.decode(SearchEnvelope.self, from: searchData, providerID: .gelato)
        let orders = Array((search.orders ?? []).prefix(Self.maxOrders))

        var total = Decimal(0)
        var currencies = CurrencyAccumulator()
        for summary in orders {
            guard let id = summary.id, !id.isEmpty else { continue }
            let orderData = try await ProviderHTTP.get(
                url: Self.orderURL(id: id),
                headers: headers,
                client: httpClient,
                providerID: .gelato
            )
            let order = try ProviderHTTP.decode(Order.self, from: orderData, providerID: .gelato)
            for receipt in order.receipts ?? [] {
                let amount = receipt.totalInclVat?.value ?? receipt.total?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(receipt.currency, providerID: .gelato)
                let type = (receipt.transactionType ?? "").lowercased()
                if type == "refund" {
                    total -= amount
                } else if type.isEmpty || type == "purchase" {
                    total += amount
                }
            }
        }

        let converted = try currencies.convert(total, rates: rateSource.current, providerID: .gelato)
        return Snapshot(
            providerID: .gelato,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: converted.money,
            converted: currencies.needsConversionNote ? converted : nil
        )
    }

    static let searchURL = URL(string: "https://order.gelatoapis.com/v4/orders:search")!

    static func orderURL(id: String) -> URL {
        URL(string: "https://order.gelatoapis.com/v4/orders/\(id)")!
    }

    static func iso8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    struct SearchEnvelope: Decodable, Sendable {
        var orders: [OrderSummary]?
    }

    struct OrderSummary: Decodable, Sendable {
        var id: String?
    }

    struct Order: Decodable, Sendable {
        var id: String?
        var receipts: [Receipt]?
    }

    struct Receipt: Decodable, Sendable {
        var transactionType: String?
        var totalInclVat: FlexibleDecimal?
        var total: FlexibleDecimal?
        var currency: String?
    }
}
