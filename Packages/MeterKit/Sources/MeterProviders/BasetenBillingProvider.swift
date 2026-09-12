import Foundation
import MeterCore

/// Baseten 本月已计价花费。
///
/// 文档：`GET /v1/billing/usage_summary`
/// 认证：`Authorization: Bearer <API key>`
///
/// 三类（dedicated / training / model APIs）各自有 `total` 和抵扣后的 `subtotal`。
/// 账本用 subtotal：那是扣完 credits 之后要付的。日线走各 breakdown 的 `daily.subtotal`。
/// 区间不能超过 31 天，`end_date` 用下月 1 号（开区间）。
public struct BasetenBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.baseten }

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .baseten)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        var daily = DailySpendAccumulator()
        var currentTotal: Decimal?
        for month in months {
            let data = try await ProviderHTTP.get(
                url: Self.usageSummaryURL(window: month),
                headers: [
                    "Authorization": "Bearer \(key)",
                ],
                client: httpClient,
                providerID: .baseten
            )
            let summary = try ProviderHTTP.decode(UsageSummary.self, from: data, providerID: .baseten)
            if month.start == current.start {
                currentTotal = summary.categories.reduce(Decimal(0)) { $0 + $1.billed }
            }
            for category in summary.categories {
                for item in category.breakdown ?? [] {
                    for point in item.daily ?? [] {
                        guard let amount = point.subtotal?.value, amount != 0 else { continue }
                        let day = point.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                            ?? month.start
                        daily.add(day: month.contains(day) ? day : month.clamp(day), amount: Money(usd: amount))
                    }
                }
            }
        }
        return Snapshot(
            providerID: .baseten,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal ?? daily.total(in: current, calendar: calendar).usd),
            dailyUSD: daily.snapshotDaily
        )
    }

    static func usageSummaryURL(window: CalendarMonthWindow) -> URL {
        ProviderURL.https(
            host: "api.baseten.co",
            path: "/v1/billing/usage_summary",
            query: [
                URLQueryItem(name: "start_date", value: window.rfc3339(window.start)),
                URLQueryItem(name: "end_date", value: window.rfc3339(window.nextStart)),
            ]
        )
    }

    struct UsageSummary: Decodable, Sendable {
        var dedicated_usage: Category?
        var training_usage: Category?
        var model_apis_usage: Category?

        var categories: [Category] {
            [dedicated_usage, training_usage, model_apis_usage].compactMap { $0 }
        }
    }

    struct Category: Decodable, Sendable {
        var subtotal: FlexibleDecimal?
        var total: FlexibleDecimal?
        var breakdown: [Item]?

        /// 有抵扣后的 subtotal 用它，否则退回 total。
        var billed: Decimal {
            subtotal?.value ?? total?.value ?? 0
        }
    }

    struct Item: Decodable, Sendable {
        var daily: [Daily]?
    }

    struct Daily: Decodable, Sendable {
        var date: String?
        var subtotal: FlexibleDecimal?
    }
}
