import Foundation
import MeterCore

/// Klaviyo 本账期 USD 计价用量（`GET /api/billing-usage`，仅 `unit == USD`）。
///
/// 文档：https://developers.klaviyo.com/en/reference/billing_usage_api_overview
/// 认证：`Authorization: Klaviyo-API-Key <private key>` + `revision: 2026-07-15.pre`（`usage:read`）。
/// email/profiles 等 unit 不是钱；`sms_credits` 仅当 unit 为 USD 时计入。
public struct KlaviyoBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.klaviyo }
    public static let apiHost = "a.klaviyo.com"
    public static let revision = "2026-07-15.pre"

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(
        httpClient: any HTTPClient,
        now: @escaping @Sendable () -> Date,
        calendar: Calendar
    ) {
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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .klaviyo)
        let headers = [
            "Authorization": "Klaviyo-API-Key \(apiKey)",
            "Accept": "application/json",
            "revision": Self.revision,
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)

        let data = try await ProviderHTTP.get(
            url: Self.usageURL,
            headers: headers,
            client: httpClient,
            providerID: .klaviyo
        )
        let payload = try ProviderHTTP.decode(UsageList.self, from: data, providerID: .klaviyo)

        var lines = SpendLineAccumulator()
        var daily = DailySpendAccumulator()
        var total: Decimal = 0
        var periodStart = current.start
        var periodEnd = current.endInclusive

        for row in payload.data ?? [] {
            let attrs = row.attributes
            let unit = (attrs?.unit ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            // Money path only: USD-denominated usage (e.g. sms_credits billed in USD).
            guard unit == "USD" || unit == "US$" else { continue }
            let used = attrs?.usage_used?.value ?? 0
            guard used != 0 else { continue }
            total += used
            let label = row.id ?? "usage"
            lines.add(
                SpendLine(
                    category: "usage",
                    label: label,
                    amountUSD: Money(usd: used)
                )
            )
            if let start = attrs?.period_start.flatMap({ BillingDateParser.parse($0, calendar: calendar) }) {
                periodStart = start
            }
            if let endExclusive = attrs?.period_end.flatMap({ BillingDateParser.parse($0, calendar: calendar) }) {
                // period_end is exclusive
                let inclusive = calendar.date(byAdding: .second, value: -1, to: endExclusive) ?? endExclusive
                periodEnd = inclusive
            }
            // Attribute spend to period start day within current window when possible.
            let stamp = attrs?.period_start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            if current.contains(stamp) {
                daily.add(day: stamp, amount: Money(usd: used))
            } else if horizon == .availableHistory {
                daily.addPastMonth(
                    start: stamp,
                    amount: Money(usd: used),
                    current: current,
                    calendar: calendar
                )
            }
        }

        return Snapshot(
            providerID: .klaviyo,
            kind: .usage,
            fetchedAt: now,
            periodStart: periodStart,
            periodEnd: periodEnd,
            currentSpendUSD: Money(usd: total),
            dailyUSD: daily.snapshotDaily,
            lines: lines.snapshot
        )
    }

    static let usageURL = ProviderURL.https(
        host: apiHost,
        path: "/api/billing-usage"
    )

    struct UsageList: Decodable, Sendable {
        var data: [UsageRow]?
    }

    struct UsageRow: Decodable, Sendable {
        var type: String?
        var id: String?
        var attributes: Attributes?
    }

    struct Attributes: Decodable, Sendable {
        var usage_used: FlexibleDecimal?
        var usage_max: FlexibleDecimal?
        var unit: String?
        var period_start: String?
        var period_end: String?
        var as_of: String?
    }
}
