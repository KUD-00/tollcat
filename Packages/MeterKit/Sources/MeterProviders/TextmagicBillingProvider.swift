import Foundation
import MeterCore

/// Textmagic 预充值余额。
///
/// 文档：`GET /api/v2/user`
/// 认证：HTTP Basic，用户名是仪表用户名，密码是 API Key。
///
/// `balance` 是账户币种的剩余金额。`currency.id` 是 ISO 4217。
public struct TextmagicBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.textmagic }

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar
    public var rateSource: SharedExchangeRates

    public init(
        httpClient: any HTTPClient,
        now: @escaping @Sendable () -> Date,
        calendar: Calendar,
        rateSource: SharedExchangeRates
    ) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
        self.rateSource = rateSource
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        let now = now()
        let username = try RequiredCredential.value(.clientID, in: credential, providerID: .textmagic)
        let apiKey = try RequiredCredential.value(.clientSecret, in: credential, providerID: .textmagic)
        let data = try await ProviderHTTP.get(
            url: Self.userURL,
            headers: [
                "Authorization": Self.basicAuthorization(username: username, apiKey: apiKey),
            ],
            client: httpClient,
            providerID: .textmagic
        )
        let payload = try ProviderHTTP.decode(User.self, from: data, providerID: .textmagic)
        guard let available = payload.balance?.value else {
            throw ProviderError.malformedResponse(providerID: .textmagic)
        }
        let converted = try BillingCurrency.convert(
            available,
            currency: payload.currency?.id,
            rates: rateSource.current,
            providerID: .textmagic
        )
        return PrepaidSnapshot.make(
            providerID: .textmagic,
            now: now,
            calendar: calendar,
            balance: converted.money,
            converted: converted.isConverted ? converted : nil
        )
    }

    static func basicAuthorization(username: String, apiKey: String) -> String {
        "Basic \(ProviderOAuth.basicValue(id: username, secret: apiKey))"
    }

    static let userURL = URL(string: "https://rest.textmagic.com/api/v2/user")!

    struct User: Decodable, Sendable {
        var balance: FlexibleDecimal?
        var currency: Currency?
    }

    struct Currency: Decodable, Sendable {
        var id: String?
    }
}
