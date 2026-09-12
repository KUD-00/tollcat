import Foundation
import MeterCore

/// Sentry 本月错误事件的免费额度占比。
///
/// 文档：`GET /api/0/organizations/{org}/stats_v2/`
/// 认证：`Authorization: Bearer <personal token>`，需要 `org:read`。
/// Organization Token 只有锁死的 `org:ci`，stats_v2 会 403。
///
/// **拿不到钱，所以不报钱。** stats_v2 只给事件条数；Sentry 的超额单价是分档的
/// （错误从 $0.0003625/条往下滑），预留额度和套餐档位都没有公开接口。按目录价手算
/// 出来的数字对不上任何一张账单，所以这里照 Resend 那条先例：只报免费额度用了多少。
///
/// 付费计划连上来会一直顶在 100%——那也是个可读的信号，比一个编出来的金额强。
public struct SentryBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.sentry }
    /// Developer（免费）计划每月含的错误事件数。
    public static let freeMonthlyErrors = 5_000

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .sentry)
        let org = try RequiredCredential.value(.accountID, in: credential, providerID: .sentry)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)

        let data = try await ProviderHTTP.get(
            url: Self.statsURL(org: org, window: window, calendar: calendar),
            headers: [
                "Authorization": "Bearer \(token)",
            ],
            client: httpClient,
            providerID: .sentry
        )
        let payload = try ProviderHTTP.decode(Stats.self, from: data, providerID: .sentry)
        let accepted = Self.acceptedErrors(payload)

        return Snapshot(
            providerID: .sentry,
            kind: .freeTier,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: .zero,
            freeQuotaUsedRatio: Self.ratio(used: accepted, included: Self.freeMonthlyErrors)
        )
    }

    /// 已经在查询里过滤了 `outcome=accepted` 和 `category=error`，这里只负责把
    /// 各分组的 `sum(quantity)` 加起来。分组维度变了也不会重复计。
    static func acceptedErrors(_ stats: Stats) -> Int {
        (stats.groups ?? []).reduce(0) { sum, group in
            sum + (group.totals?["sum(quantity)"] ?? 0)
        }
    }

    static func ratio(used: Int, included: Int) -> Double {
        guard included > 0 else { return 0 }
        return min(1, Double(max(0, used)) / Double(included))
    }

    static func statsURL(org: String, window: CalendarMonthWindow, calendar: Calendar) -> URL {
        return ProviderURL.https(
            host: "sentry.io",
            path: "/api/0/organizations/\(org)/stats_v2/",
            query: [
                URLQueryItem(name: "field", value: "sum(quantity)"),
                URLQueryItem(name: "groupBy", value: "outcome"),
                URLQueryItem(name: "category", value: "error"),
                URLQueryItem(name: "outcome", value: "accepted"),
                URLQueryItem(name: "interval", value: "1d"),
                URLQueryItem(name: "start", value: window.rfc3339(window.start)),
                URLQueryItem(name: "end", value: window.rfc3339(window.nextStart)),
            ]
        )
    }

    struct Stats: Decodable, Sendable {
        var groups: [Group]?
    }

    struct Group: Decodable, Sendable {
        var totals: [String: Int]?
    }
}
