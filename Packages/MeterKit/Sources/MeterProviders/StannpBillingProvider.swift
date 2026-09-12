import Foundation
import MeterCore

/// Stannp 预充值余额。
///
/// 文档：`GET /v1/accounts/balance`（US 区 `api-us1.stannp.com`）
/// 认证：HTTP Basic（API key 作用户名，密码空）。
///
/// `data.balance` 是剩余金额字符串（美元）。
public struct StannpBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.stannp }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .stannp)
        let data = try await ProviderHTTP.get(
            url: Self.balanceURL,
            headers: [
                "Authorization": "Basic \(ProviderOAuth.basicValue(id: apiKey, secret: String()))",
            ],
            client: httpClient,
            providerID: .stannp
        )
        let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .stannp)
        guard let balance = payload.data?.balance?.value else {
            throw ProviderError.malformedResponse(providerID: .stannp)
        }
        return PrepaidSnapshot.make(
            providerID: .stannp,
            now: now,
            calendar: calendar,
            balance: Money(usd: balance)
        )
    }

    static let balanceURL = URL(string: "https://api-us1.stannp.com/v1/accounts/balance")!

    struct Envelope: Decodable, Sendable {
        var data: Balance?
    }

    struct Balance: Decodable, Sendable {
        var balance: FlexibleDecimal?
    }
}
