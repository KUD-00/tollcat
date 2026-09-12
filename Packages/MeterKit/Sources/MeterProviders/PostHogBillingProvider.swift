import Foundation
import MeterCore

/// PostHog 本周期账单 + 日花费序列。
///
/// 官方：`GET /api/billing/`（周期总额美元）与 `GET /api/billing/spend/`（USD spend 序列，需 `billing:read`）。
/// 认证：Personal API key（`phx_`）。EU Cloud 的 key 打 US 会 401，再试 EU。
public struct PostHogBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.posthog }
    public static let usHost = "us.posthog.com"
    public static let euHost = "eu.posthog.com"

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
        let secret = try RequiredCredential.value(.apiKey, in: credential, providerID: .posthog)
        do {
            return try await fetch(host: Self.usHost, secret: secret, horizon: horizon)
        } catch let error as ProviderError where error.code == .unauthorized {
            return try await fetch(host: Self.euHost, secret: secret, horizon: horizon)
        }
    }

    private func fetch(
        host: String,
        secret: String,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let headers = [
            "Authorization": "Bearer \(secret)",
        ]
        let data = try await ProviderHTTP.get(
            url: Self.billingURL(host: host),
            headers: headers,
            client: httpClient,
            providerID: .posthog
        )
        let payload = try ProviderHTTP.decode(Billing.self, from: data, providerID: .posthog)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let period = BillingPeriodResolver.resolve(
            startRaw: payload.billing_period?.current_period_start,
            endRaw: payload.billing_period?.current_period_end,
            endConvention: .exclusiveWhenMonthStart,
            fallback: window,
            calendar: calendar
        )
        var daily = DailySpendAccumulator()
        let spendStart: Date
        if horizon == .availableHistory {
            spendStart = CalendarMonthWindow.spanning(
                for: .availableHistory,
                lookbackMonths: Self.descriptor.historyLookbackMonths,
                now: now,
                calendar: calendar
            ).start
        } else {
            spendStart = period.start
        }
        do {
            let spendData = try await ProviderHTTP.get(
                url: Self.spendURL(
                    host: host,
                    start: spendStart,
                    end: period.end,
                    calendar: calendar
                ),
                headers: headers,
                client: httpClient,
                providerID: .posthog
            )
            let spend = try ProviderHTTP.decode(SpendResponse.self, from: spendData, providerID: .posthog)
            for series in spend.results ?? [] {
                let points = series.data ?? []
                let dates = series.dates ?? []
                let count = min(points.count, dates.count)
                for i in 0..<count {
                    let amount = points[i].value
                    guard amount != 0 else { continue }
                    guard let day = BillingDateParser.parse(dates[i], calendar: calendar) else { continue }
                    daily.add(day: calendar.startOfDay(for: day), amount: Money(usd: amount))
                }
            }
        } catch let error as ProviderError
            where error.code == .forbidden
            || error.code == .billingAPIUnavailable
            || error.code == .networkFailure {
            // spend 需要 billing:read；没有权限或日线接口不可用时仍返回 /api/billing/ 总额。
        }
        return Snapshot(
            providerID: .posthog,
            kind: .usage,
            fetchedAt: now,
            periodStart: period.start,
            periodEnd: period.end,
            currentSpendUSD: Money(usd: Self.amount(from: payload) ?? 0),
            dailyUSD: daily.snapshotDaily
        )
    }

    static func billingURL(host: String) -> URL {
        ProviderURL.https(host: host, path: "/api/billing/")
    }

    static func spendURL(
        host: String,
        start: Date,
        end: Date,
        calendar: Calendar
    ) -> URL {
        let fmt = DateFormatter()
        fmt.calendar = calendar
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = calendar.timeZone
        fmt.dateFormat = "yyyy-MM-dd"
        return ProviderURL.https(
            host: host,
            path: "/api/billing/spend/",
            query: [
                URLQueryItem(name: "start_date", value: fmt.string(from: start)),
                URLQueryItem(name: "end_date", value: fmt.string(from: end)),
                URLQueryItem(name: "interval", value: "day"),
            ]
        )
    }

    static func amount(from payload: Billing) -> Decimal? {
        payload.current_total_amount_usd_after_discount?.value
            ?? payload.current_total_amount_usd?.value
    }

    struct Billing: Decodable, Sendable {
        var current_total_amount_usd: FlexibleDecimal?
        var current_total_amount_usd_after_discount: FlexibleDecimal?
        var billing_period: Period?
    }

    struct Period: Decodable, Sendable {
        var current_period_start: String?
        var current_period_end: String?
    }

    struct SpendResponse: Decodable, Sendable {
        var results: [SpendSeries]?
    }

    struct SpendSeries: Decodable, Sendable {
        var data: [FlexibleDecimal]?
        var dates: [String]?
    }
}
