import Foundation
import MeterCore

/// EasyPost 预充值钱包余额。
///
/// 文档：`GET /v2/users`
/// 认证：HTTP Basic，用户名是 Production API Key，密码为空。
///
/// `balance` 是更高精度的美元字符串。
public struct EasyPostBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.easypost }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .easypost)
        let data = try await ProviderHTTP.get(
            url: Self.usersURL,
            headers: [
                "Authorization": Self.basicAuthorization(apiKey: apiKey),
            ],
            client: httpClient,
            providerID: .easypost
        )
        let payload = try ProviderHTTP.decode(User.self, from: data, providerID: .easypost)
        guard let balance = payload.balance?.value else {
            throw ProviderError.malformedResponse(providerID: .easypost)
        }
        return PrepaidSnapshot.make(
            providerID: .easypost,
            now: now,
            calendar: calendar,
            balance: Money(usd: balance)
        )
    }

    static func basicAuthorization(apiKey: String) -> String {
        "Basic \(ProviderOAuth.basicValue(id: apiKey, secret: ""))"
    }

    static let usersURL = URL(string: "https://api.easypost.com/v2/users")!

    struct User: Decodable, Sendable {
        var id: String?
        var balance: FlexibleDecimal?
    }
}
