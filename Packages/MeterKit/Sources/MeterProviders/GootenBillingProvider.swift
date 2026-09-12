import Foundation
import MeterCore

/// Gooten 本月订单账单合计。
///
/// 文档：搜索 `GET /api/v/5/source/api/orders`，再对每单
/// `GET /api/v/5/source/api/orderbilling` 的 `Result.Total.Price` + `CurrencyCode`。
/// 认证：`recipeid` + `partnerBillingKey`（Partner Billing Key）。
///
/// 只计官方 billing Total（商户应付），按币种折美元后相加。
public struct GootenBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.gooten }
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
        let recipeID = try RequiredCredential.value(.clientID, in: credential, providerID: .gooten)
        let billingKey = try RequiredCredential.value(.clientSecret, in: credential, providerID: .gooten)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var total = Decimal(0)

        let searchData = try await ProviderHTTP.get(
            url: Self.ordersSearchURL(recipeID: recipeID, billingKey: billingKey, window: window),
            headers: [:],
            client: httpClient,
            providerID: .gooten
        )
        let search = try ProviderHTTP.decode(SearchEnvelope.self, from: searchData, providerID: .gooten)
        let orders = Array((search.Orders ?? []).prefix(Self.maxOrders))

        for order in orders {
            guard let orderID = order.Id ?? order.id, !orderID.isEmpty else { continue }
            let billData = try await ProviderHTTP.get(
                url: Self.billingURL(orderID: orderID, recipeID: recipeID, billingKey: billingKey),
                headers: [:],
                client: httpClient,
                providerID: .gooten
            )
            let bill = try ProviderHTTP.decode(BillingEnvelope.self, from: billData, providerID: .gooten)
            guard let price = bill.Result?.Total?.Price?.value else { continue }
            try currencies.observe(bill.Result?.Total?.CurrencyCode, providerID: .gooten)
            total += price
        }

        let converted = try currencies.convert(total, rates: rateSource.current, providerID: .gooten)
        return Snapshot(
            providerID: .gooten,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: converted.money,
            converted: currencies.needsConversionNote ? converted : nil
        )
    }

    static func ordersSearchURL(
        recipeID: String,
        billingKey: String,
        window: CalendarMonthWindow
    ) -> URL {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        return ProviderURL.https(
            host: "api.print.io",
            path: "/api/v/5/source/api/orders",
            query: [
                URLQueryItem(name: "recipeid", value: recipeID),
                URLQueryItem(name: "partnerBillingKey", value: billingKey),
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "pageSize", value: String(maxOrders)),
                URLQueryItem(name: "fromDate", value: fmt.string(from: window.start)),
                URLQueryItem(name: "toDate", value: fmt.string(from: window.nextStart)),
            ]
        )
    }

    static func billingURL(orderID: String, recipeID: String, billingKey: String) -> URL {
        ProviderURL.https(
            host: "api.print.io",
            path: "/api/v/5/source/api/orderbilling",
            query: [
                URLQueryItem(name: "recipeid", value: recipeID),
                URLQueryItem(name: "partnerBillingKey", value: billingKey),
                URLQueryItem(name: "orderid", value: orderID),
            ]
        )
    }

    struct SearchEnvelope: Decodable, Sendable {
        var Orders: [OrderSummary]?
    }

    struct OrderSummary: Decodable, Sendable {
        var Id: String?
        var id: String?
    }

    struct BillingEnvelope: Decodable, Sendable {
        var Result: BillingResult?
        var HadError: Bool?
    }

    struct BillingResult: Decodable, Sendable {
        var Total: MoneyBlock?
    }

    struct MoneyBlock: Decodable, Sendable {
        var Price: FlexibleDecimal?
        var CurrencyCode: String?
    }
}
