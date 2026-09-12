import Foundation
import MeterCore

/// Porkbun 预充值余额。
///
/// 文档：`GET /api/json/v3/account/balance`
/// 认证：`X-API-Key` + `X-Secret-API-Key`。
///
/// `balance` 是美分；`display` 是展示字符串。
public struct PorkbunBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.porkbun }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .porkbun)
        let secret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .porkbun)
        let data = try await ProviderHTTP.get(
            url: Self.balanceURL,
            headers: [
                "X-API-Key": apiKey,
                "X-Secret-API-Key": secret,
            ],
            client: httpClient,
            providerID: .porkbun
        )
        let payload = try ProviderHTTP.decode(Balance.self, from: data, providerID: .porkbun)
        guard let cents = payload.balance?.value else {
            throw ProviderError.malformedResponse(providerID: .porkbun)
        }
        return PrepaidSnapshot.make(
            providerID: .porkbun,
            now: now,
            calendar: calendar,
            balance: Money(usd: cents / 100)
        )
    }

    static let balanceURL = URL(string: "https://api.porkbun.com/api/json/v3/account/balance")!

    struct Balance: Decodable, Sendable {
        var status: String?
        var balance: FlexibleDecimal?
        var display: String?
    }
}
