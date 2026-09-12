import Foundation
import MeterCore

/// thanks.io 本月订单合计。
///
/// 文档：`GET /api/v2/orders/list`
/// 认证：`Authorization: Bearer <API key>`。
///
/// `grand_total`（缺省回落到 `authorization_total`）是美分。按 `created_at` 落在本月的订单相加。
public struct ThanksIOBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.thanksio }
    public static let maxPages = 20

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(httpClient: any HTTPClient, now: @escaping @Sendable () -> Date, calendar: Calendar) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        let now = now()
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .thanksio)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        var daily = DailySpendAccumulator()
        var page = 1
        var pages = 0

        while pages < Self.maxPages {
            pages += 1
            let data = try await ProviderHTTP.get(
                url: Self.ordersURL(page: page),
                headers: [
                    "Authorization": "Bearer \(token)",
                ],
                client: httpClient,
                providerID: .thanksio
            )
            let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .thanksio)
            let orders = payload.data ?? []
            for order in orders {
                let cents = order.grand_total ?? order.authorization_total ?? 0
                guard cents != 0 else { continue }
                let day = order.created_at.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? window.start
                guard day >= window.start, day < window.nextStart else { continue }
                daily.add(day: day, amount: Money(usd: Decimal(cents) / 100))
            }

            let lastPage = payload.meta?.last_page ?? page
            if page >= lastPage || orders.isEmpty { break }
            page += 1
        }

        return Snapshot(
            providerID: .thanksio,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: daily.total(in: window, calendar: calendar),
            dailyUSD: daily.snapshotDaily
        )
    }

    static func ordersURL(page: Int) -> URL {
        ProviderURL.https(
            host: "api.thanks.io",
            path: "/api/v2/orders/list",
            query: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "items_per_page", value: "100"),
            ]
        )
    }

    struct Envelope: Decodable, Sendable {
        var data: [Order]?
        var meta: Meta?
    }

    struct Order: Decodable, Sendable {
        var id: Int?
        var grand_total: Int64?
        var authorization_total: Int64?
        var created_at: String?
    }

    struct Meta: Decodable, Sendable {
        var current_page: Int?
        var last_page: Int?
    }
}
