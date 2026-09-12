import Foundation
import MeterCore

/// Firecrawl 本月 credits 额度占比。
///
/// 文档：`GET /v2/team/credit-usage`
/// 认证：`Authorization: Bearer <API key>`。
///
/// **拿不到钱，所以不报钱。** `remainingCredits` / `planCredits` 是 credits，
/// 各档单价不一样，不按每页多少美分手算。照 GitLab 先例报免费额度占比。
public struct FirecrawlBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.firecrawl }

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .firecrawl)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: Self.creditUsageURL,
            headers: [
                "Authorization": "Bearer \(key)",
            ],
            client: httpClient,
            providerID: .firecrawl
        )
        let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .firecrawl)
        guard let usage = envelope.data else {
            throw ProviderError.malformedResponse(providerID: .firecrawl)
        }
        let remaining = usage.remainingCredits?.value ?? 0
        let included = usage.planCredits?.value ?? 0
        let used = max(included - remaining, 0)
        let period = BillingPeriodResolver.resolve(
            startRaw: usage.billingPeriodStart,
            endRaw: usage.billingPeriodEnd,
            endConvention: .inclusive,
            fallback: window,
            calendar: calendar
        )
        return Snapshot(
            providerID: .firecrawl,
            kind: .freeTier,
            fetchedAt: now,
            periodStart: period.start,
            periodEnd: period.end,
            currentSpendUSD: .zero,
            freeQuotaUsedRatio: Self.ratio(used: used, included: included)
        )
    }

    static func ratio(used: Decimal, included: Decimal) -> Double {
        guard included > 0 else { return 0 }
        let raw = (max(used, 0) / included) as NSDecimalNumber
        return min(1, raw.doubleValue)
    }

    static let creditUsageURL = URL(string: "https://api.firecrawl.dev/v2/team/credit-usage")!

    struct Envelope: Decodable, Sendable {
        var success: Bool?
        var data: Usage?
    }

    struct Usage: Decodable, Sendable {
        var remainingCredits: FlexibleDecimal?
        var planCredits: FlexibleDecimal?
        var billingPeriodStart: String?
        var billingPeriodEnd: String?
    }
}
