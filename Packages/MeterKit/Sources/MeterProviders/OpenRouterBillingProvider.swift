import Foundation
import MeterCore

/// OpenRouter 预充值余额。
///
/// 文档：`GET /api/v1/credits`
/// 认证：`Authorization: Bearer <Management key>`。普通推理 key 会 403。
public struct OpenRouterBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.openrouter }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .openrouter)
        let data = try await ProviderHTTP.get(
            url: Self.creditsURL,
            headers: [
                "Authorization": "Bearer \(apiKey)",
            ],
            client: httpClient,
            providerID: .openrouter
        )
        let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .openrouter)
        guard let credits = envelope.data else {
            throw ProviderError.malformedResponse(providerID: .openrouter)
        }
        let remaining = max(credits.total_credits.value - credits.total_usage.value, 0)
        return PrepaidSnapshot.make(
            providerID: .openrouter,
            now: now,
            calendar: calendar,
            balance: Money(usd: remaining)
        )
    }

    static let creditsURL = URL(string: "https://openrouter.ai/api/v1/credits")!

    struct Envelope: Decodable, Sendable {
        var data: Credits?
    }

    /// 真实响应是 snake_case（TS SDK 类型里的 camelCase 只是客户端映射）。
    struct Credits: Decodable, Sendable {
        var total_credits: FlexibleDecimal
        var total_usage: FlexibleDecimal
    }
}
