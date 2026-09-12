import Foundation
import MeterCore

/// StepFun 国际站预充值余额。国内站是 `StepFunBillingProvider`，key 不能混用。
///
/// 文档：`GET /v1/accounts`
/// 认证：普通 API key。`api.stepfun.ai` 官方字段按美元。
public struct StepFunAIBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.stepfunAI }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .stepfunAI)
        let data = try await ProviderHTTP.get(
            url: Self.accountsURL,
            headers: [
                "Authorization": "Bearer \(apiKey)",
            ],
            client: httpClient,
            providerID: .stepfunAI
        )
        let payload = try ProviderHTTP.decode(Account.self, from: data, providerID: .stepfunAI)
        guard let available = payload.balance?.value else {
            throw ProviderError.malformedResponse(providerID: .stepfunAI)
        }
        return PrepaidSnapshot.make(
            providerID: .stepfunAI,
            now: now,
            calendar: calendar,
            balance: Money(usd: available)
        )
    }

    static let accountsURL = URL(string: "https://api.stepfun.ai/v1/accounts")!

    struct Account: Decodable, Sendable {
        var object: String?
        var type: String?
        var balance: FlexibleDecimal?
        var total_cash_balance: FlexibleDecimal?
        var total_voucher_balance: FlexibleDecimal?
    }
}
