import Foundation
import MeterCore

/// Better Stack 本月已产生费用。
///
/// 文档：`GET /api/v2/usage`
/// 认证：Global API token，`Authorization: Bearer`。
///
/// `data[].attributes.cost` 是各产品在区间内的美元费用；按产品相加。
/// `from` / `to` 钉死本月 1 号到今天，和日历月账本对齐。
public struct BetterStackBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.betterstack }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .betterstack)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let from = window.dayString(window.start, calendar: calendar)
        let to = window.dayString(now, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: Self.usageURL(from: from, to: to),
            headers: [
                "Authorization": "Bearer \(token)",
            ],
            client: httpClient,
            providerID: .betterstack
        )
        let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .betterstack)
        let total = (payload.data ?? []).reduce(Decimal(0)) { $0 + ($1.attributes?.cost?.value ?? 0) }
        return Snapshot(
            providerID: .betterstack,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: Money(usd: total)
        )
    }

    static func usageURL(from: String, to: String) -> URL {
        ProviderURL.https(
            host: "betterstack.com",
            path: "/api/v2/usage",
            query: [
                URLQueryItem(name: "from", value: from),
                URLQueryItem(name: "to", value: to),
            ]
        )
    }

    struct Envelope: Decodable, Sendable {
        var data: [Product]?
    }

    struct Product: Decodable, Sendable {
        var id: String?
        var attributes: Attributes?
    }

    struct Attributes: Decodable, Sendable {
        var name: String?
        var cost: FlexibleDecimal?
    }
}
