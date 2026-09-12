import Foundation
import MeterCore

/// Moonshot (China) 预充值余额。国际站是 `MoonshotAIBillingProvider`，key 不能混用。
///
/// 文档：`GET /v1/users/me/balance`
/// 认证：普通 API key。`api.moonshot.cn` 官方字段是人民币元，没有币种字段，按 CNY 折。
public struct MoonshotBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.moonshot }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .moonshot)
        let data = try await ProviderHTTP.get(
            url: Self.balanceURL,
            headers: [
                "Authorization": "Bearer \(apiKey)",
            ],
            client: httpClient,
            providerID: .moonshot
        )
        let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .moonshot)
        guard let available = payload.data?.available_balance?.value else {
            throw ProviderError.malformedResponse(providerID: .moonshot)
        }
        let converted = try BillingCurrency.convert(
            available,
            currency: "CNY",
            rates: rateSource.current,
            providerID: .moonshot
        )
        return PrepaidSnapshot.make(
            providerID: .moonshot,
            now: now,
            calendar: calendar,
            balance: converted.money,
            converted: converted.isConverted ? converted : nil
        )
    }

    static let balanceURL = URL(string: "https://api.moonshot.cn/v1/users/me/balance")!

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
