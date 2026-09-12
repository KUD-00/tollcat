import Foundation
import MeterCore

/// Infobip 预充值余额。
///
/// 文档：`GET /account/1/balance`
/// 认证：`Authorization: App <API key>`。
///
/// `balance` 是账户配置币种的剩余金额。`currency` 按目录汇率折。
/// 个性化 `xxxxx.api.infobip.com` 只是路由优化，公开入口是 `api.infobip.com`。
public struct InfobipBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.infobip }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .infobip)
        let data = try await ProviderHTTP.get(
            url: Self.balanceURL,
            headers: [
                "Authorization": "App \(apiKey)",
            ],
            client: httpClient,
            providerID: .infobip
        )
        let payload = try ProviderHTTP.decode(Balance.self, from: data, providerID: .infobip)
        guard let available = payload.balance?.value else {
            throw ProviderError.malformedResponse(providerID: .infobip)
        }
        let converted = try BillingCurrency.convert(
            available,
            currency: payload.currency,
            rates: rateSource.current,
            providerID: .infobip
        )
        return PrepaidSnapshot.make(
            providerID: .infobip,
            now: now,
            calendar: calendar,
            balance: converted.money,
            converted: converted.isConverted ? converted : nil
        )
    }

    static let balanceURL = URL(string: "https://api.infobip.com/account/1/balance")!

    struct Balance: Decodable, Sendable {
        var balance: FlexibleDecimal?
        var currency: String?
    }
}
