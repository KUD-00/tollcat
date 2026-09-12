import Foundation
import MeterCore

/// Printify 本月履约成本合计（`GET /v1/shops/{shop_id}/orders.json`）。
///
/// 文档：https://developers.printify.com/
/// 认证：`Authorization: Bearer <token>`。
/// Host：`api.printify.com`。
/// 金额：只计 `line_items[].cost + shipping_cost`（美分，商户成本），
/// **不计** `total_price` / `metadata.price`（零售价）。
/// 跳过 `canceled` / `cancelled` / `on-hold`。币种按 USD 美分。
/// 凭据：`apiKey` + `accountID`（shop_id）。
public struct PrintifyBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.printify }
    public static let apiHost = "api.printify.com"
    static let maxPages = 20
    static let pageSize = 50

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
        let token = try RequiredCredential.value(.apiKey, in: credential, providerID: .printify)
        let shopID = try RequiredCredential.value(.accountID, in: credential, providerID: .printify)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
            "User-Agent": "TollcatMeter/1.0",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var page = 1
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let env = try await loadPage(shopID: shopID, page: page, headers: headers)
            let batch = env.data ?? []
            if batch.isEmpty { break }
            var sawOlder = false
            for order in batch {
                let stamp = order.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? order.sentToProductionAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                if stamp < current.start, horizon == .currentMonth {
                    sawOlder = true
                }
                let status = (order.status ?? "").lowercased()
                if status == "canceled" || status == "cancelled" || status == "on-hold" {
                    continue
                }
                let cents = Self.merchantCostCents(order: order)
                guard cents != 0 else { continue }
                let amount = Decimal(cents) / 100
                try currencies.observe("USD", providerID: .printify)
                let label = order.id ?? "order"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: status.isEmpty ? "order" : status,
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
            let lastPage = env.lastPage ?? page
            if page >= lastPage || batch.count < Self.pageSize || sawOlder { break }
            page += 1
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .printify
        )
        return Snapshot(
            providerID: .printify,
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

    private func loadPage(
        shopID: String,
        page: Int,
        headers: [String: String]
    ) async throws -> Envelope {
        let url = ProviderURL.https(
            host: Self.apiHost,
            path: "/v1/shops/\(shopID)/orders.json",
            query: [
                URLQueryItem(name: "limit", value: String(Self.pageSize)),
                URLQueryItem(name: "page", value: String(page)),
            ]
        )
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .printify
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .printify)
    }

    static func merchantCostCents(order: Order) -> Int64 {
        var cents: Int64 = 0
        for item in order.lineItems ?? [] {
            let itemStatus = (item.status ?? "").lowercased()
            if itemStatus == "canceled" || itemStatus == "cancelled" {
                continue
            }
            if let cost = item.cost {
                cents += Int64(cost)
            }
            if let shipping = item.shippingCost {
                cents += Int64(shipping)
            }
        }
        return cents
    }

    struct Envelope: Decodable, Sendable {
        var data: [Order]?
        var currentPage: Int?
        var lastPage: Int?

        enum CodingKeys: String, CodingKey {
            case data
            case currentPage = "current_page"
            case lastPage = "last_page"
        }
    }

    struct Order: Decodable, Sendable {
        var id: String?
        var status: String?
        var createdAt: String?
        var sentToProductionAt: String?
        var lineItems: [LineItem]?

        enum CodingKeys: String, CodingKey {
            case id, status
            case createdAt = "created_at"
            case sentToProductionAt = "sent_to_production_at"
            case lineItems = "line_items"
        }
    }

    struct LineItem: Decodable, Sendable {
        var cost: Int?
        var shippingCost: Int?
        var status: String?

        enum CodingKeys: String, CodingKey {
            case cost, status
            case shippingCost = "shipping_cost"
        }
    }
}
