import Foundation
import MeterCore

/// Tavily 本月 credits 额度占比。
///
/// 文档：`GET /usage`
/// 认证：`Authorization: Bearer <API key>`。
///
/// **拿不到钱，所以不报钱。** `plan_usage` / `plan_limit` 是 credits，不是美元。
/// 各档单价不一样，不按 $0.008/credit 手算。照 GitLab 先例报免费额度占比。
public struct TavilyBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.tavily }

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .tavily)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: Self.usageURL,
            headers: [
                "Authorization": "Bearer \(key)",
            ],
            client: httpClient,
            providerID: .tavily
        )
        let payload = try ProviderHTTP.decode(Usage.self, from: data, providerID: .tavily)
        guard let account = payload.account else {
            throw ProviderError.malformedResponse(providerID: .tavily)
        }
        let used = account.plan_usage ?? 0
        let included = account.plan_limit ?? 0
        return Snapshot(
            providerID: .tavily,
            kind: .freeTier,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: .zero,
            freeQuotaUsedRatio: Self.ratio(used: used, included: included)
        )
    }

    static func ratio(used: Int, included: Int) -> Double {
        guard included > 0 else { return 0 }
        return min(1, Double(max(0, used)) / Double(included))
    }

    static let usageURL = URL(string: "https://api.tavily.com/usage")!

    struct Usage: Decodable, Sendable {
        var account: Account?
    }

    struct Account: Decodable, Sendable {
        var current_plan: String?
        var plan_usage: Int?
        var plan_limit: Int?
        var paygo_usage: Int?
    }
}
