import Foundation
import MeterCore

/// Polar 本月手续费。
///
/// 文档：`GET /v1/metrics`，scope `metrics:read`
/// 认证：`Authorization: Bearer <Organization Access Token>`
///
/// Polar 没有「fees」这个指标，只有 `revenue` 和 `net_revenue`（都是**分**）。
/// 我们要的成本 = 两者之差，也就是平台费加收单行手续费。收入本身不是花销，不进快照。
public struct PolarBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.polar }

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(httpClient: any HTTPClient, now: @escaping @Sendable () -> Date, calendar: Calendar) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .polar)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let fetchWindow = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )

        let data = try await ProviderHTTP.get(
            url: Self.metricsURL(window: fetchWindow, calendar: calendar),
            headers: [
                "Authorization": "Bearer \(token)",
            ],
            client: httpClient,
            providerID: .polar
        )
        let payload = try ProviderHTTP.decode(MetricsResponse.self, from: data, providerID: .polar)

        var daily = DailySpendAccumulator()
        for period in payload.periods ?? [] {
            let fee = Self.feeCents(revenue: period.revenue, net: period.net_revenue)
            guard fee != 0 else { continue }
            let day = period.timestamp.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            daily.add(day: day, amount: Self.money(fee))
        }

        // 本月合计优先用 totals：逐日相减会把每天的取整误差累起来。
        // 历史窗口的 totals 是整段，不能当本月数字。
        let total: Money
        if horizon == .currentMonth, let totals = payload.totals {
            total = Self.money(Self.feeCents(revenue: totals.revenue, net: totals.net_revenue))
        } else {
            total = daily.total(in: current, calendar: calendar)
        }

        return Snapshot(
            providerID: .polar,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: total,
            dailyUSD: daily.snapshotDaily
        )
    }

    /// 退款月里 net 可能大于 revenue，负手续费不写进去，免得日线出现负柱。
    static func feeCents(revenue: FlexibleDecimal?, net: FlexibleDecimal?) -> Decimal {
        guard let gross = revenue?.value, let net = net?.value else { return 0 }
        return max(0, gross - net)
    }

    static func money(_ cents: Decimal) -> Money {
        Money(usd: cents / 100)
    }

    static func metricsURL(window: CalendarMonthWindow, calendar: Calendar) -> URL {
        return ProviderURL.https(
            host: "api.polar.sh",
            path: "/v1/metrics/",
            query: [
                URLQueryItem(name: "start_date", value: window.dayString(window.start, calendar: calendar)),
                URLQueryItem(name: "end_date", value: window.dayString(window.endInclusive, calendar: calendar)),
                URLQueryItem(name: "interval", value: "day"),
                URLQueryItem(name: "metrics", value: "revenue"),
                URLQueryItem(name: "metrics", value: "net_revenue"),
            ]
        )
    }

    struct MetricsResponse: Decodable, Sendable {
        var periods: [Period]?
        var totals: Totals?
    }

    struct Period: Decodable, Sendable {
        var timestamp: String?
        var revenue: FlexibleDecimal?
        var net_revenue: FlexibleDecimal?
    }

    struct Totals: Decodable, Sendable {
        var revenue: FlexibleDecimal?
        var net_revenue: FlexibleDecimal?
    }
}
