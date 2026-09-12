import Foundation
import MeterCore

/// HetrixTools 预充值账户余额（Account Credit）。
///
/// 文档：`GET /v3/account/limits`
/// 认证：API Key，`Authorization: Bearer`。
///
/// `account_credit.balance` 是预充值美元余额。
public struct HetrixToolsBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.hetrixtools }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .hetrixtools)
        let data = try await ProviderHTTP.get(
            url: Self.limitsURL,
            headers: [
                "Authorization": "Bearer \(apiKey)",
            ],
            client: httpClient,
            providerID: .hetrixtools
        )
        let payload = try ProviderHTTP.decode(Limits.self, from: data, providerID: .hetrixtools)
        guard let balance = payload.accountCredit?.balance?.value else {
            throw ProviderError.malformedResponse(providerID: .hetrixtools)
        }
        return PrepaidSnapshot.make(
            providerID: .hetrixtools,
            now: now,
            calendar: calendar,
            balance: Money(usd: balance)
        )
    }

    static let limitsURL = URL(string: "https://api.hetrixtools.com/v3/account/limits")!

    struct Limits: Decodable, Sendable {
        var accountCredit: AccountCredit?

        enum CodingKeys: String, CodingKey {
            case accountCredit = "account_credit"
        }
    }

    struct AccountCredit: Decodable, Sendable {
        var balance: FlexibleDecimal?
    }
}
