import Foundation
import MeterCore

/// Moonshot (Overseas) 预充值余额。国内站是 `MoonshotBillingProvider`，key 不能混用。
///
/// 文档：`GET /v1/users/me/balance`
/// 认证：普通 API key。`api.moonshot.ai` 官方字段是美元。
public struct MoonshotAIBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.moonshotAI }

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
        let now = now()
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .moonshotAI)
        let data = try await ProviderHTTP.get(
            url: Self.balanceURL,
            headers: [
                "Authorization": "Bearer \(apiKey)",
            ],
            client: httpClient,
            providerID: .moonshotAI
        )
        let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .moonshotAI)
        guard let available = payload.data?.available_balance?.value else {
            throw ProviderError.malformedResponse(providerID: .moonshotAI)
        }
        return PrepaidSnapshot.make(
            providerID: .moonshotAI,
            now: now,
            calendar: calendar,
            balance: Money(usd: available)
        )
    }

    static let balanceURL = URL(string: "https://api.moonshot.ai/v1/users/me/balance")!

    struct Envelope: Decodable, Sendable {
        var code: Int?
        var data: Balance?
    }

    struct Balance: Decodable, Sendable {
        var available_balance: FlexibleDecimal?
        var voucher_balance: FlexibleDecimal?
        var cash_balance: FlexibleDecimal?
    }
}
