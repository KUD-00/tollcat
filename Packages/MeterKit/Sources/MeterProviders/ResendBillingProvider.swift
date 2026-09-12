import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Resend 免费档本月发信额度。
///
/// 公开 API 没有账单金额。文档里的 `x-resend-daily-quota` 只给免费户；
/// `x-resend-monthly-quota` 是已用封顶数。免费档按官方 3,000 封/月算比例。
/// 付费套餐没有金额字段，拒绝而不是手算 Pro/Scale 价。
/// 任意一条 API 都会带回额度头，这里打 `GET /emails?limit=1`。
/// 认证：`Authorization: Bearer re_…`，必须带 `User-Agent`。
public struct ResendBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.resend }
    public static let freeMonthlyQuota = 3_000
    public static let userAgent = "Meter/1.0"

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
        let secret = try RequiredCredential.value(.apiKey, in: credential, providerID: .resend)
        let (_, response) = try await ProviderHTTP.getResponse(
            url: Self.emailsURL,
            headers: [
                "Authorization": "Bearer \(secret)",
                "User-Agent": Self.userAgent,
            ],
            client: httpClient,
            providerID: .resend
        )
        guard Self.isFreePlan(response) else {
            throw ProviderError.billingAPIUnavailable(providerID: .resend, httpStatus: 200)
        }
        let used = Self.usedCount(
            from: response.value(forHTTPHeaderField: "x-resend-monthly-quota")
        ) ?? 0
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        return Snapshot(
            providerID: .resend,
            kind: .freeTier,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: .zero,
            freeQuotaUsedRatio: Self.ratio(used: used, included: Self.freeMonthlyQuota)
        )
    }

    static let emailsURL: URL = {
        return ProviderURL.https(
            host: "api.resend.com",
            path: "/emails",
            query: [URLQueryItem(name: "limit", value: "1")]
        )
    }()

    static func isFreePlan(_ response: HTTPURLResponse) -> Bool {
        response.value(forHTTPHeaderField: "x-resend-daily-quota") != nil
    }

    static func usedCount(from header: String?) -> Int? {
        guard let header else { return nil }
        let trimmed = header.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmed), value >= 0 else { return nil }
        return value
    }

    static func ratio(used: Int, included: Int) -> Double {
        guard included > 0 else { return 0 }
        return min(1, Double(used) / Double(included))
    }
}
