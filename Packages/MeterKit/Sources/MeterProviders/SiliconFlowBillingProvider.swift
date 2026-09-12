import Foundation
import MeterCore

/// SiliconFlow（硅基流动）预充值余额。
///
/// 文档：`GET /v1/user/info`
/// 认证：普通 API key。官方字段没有币种，国内站按人民币折。
///
/// `totalBalance` 是还剩多少（充值 + 赠送金）。新云平台网页钱包不走这条接口。
public struct SiliconFlowBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.siliconflow }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .siliconflow)
        let data = try await ProviderHTTP.get(
            url: Self.userInfoURL,
            headers: [
                "Authorization": "Bearer \(apiKey)",
            ],
            client: httpClient,
            providerID: .siliconflow
        )
        let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .siliconflow)
        guard let available = payload.data?.totalBalance?.value ?? payload.data?.balance?.value else {
            throw ProviderError.malformedResponse(providerID: .siliconflow)
        }
        let converted = try BillingCurrency.convert(
            available,
            currency: "CNY",
            rates: rateSource.current,
            providerID: .siliconflow
        )
        return PrepaidSnapshot.make(
            providerID: .siliconflow,
            now: now,
            calendar: calendar,
            balance: converted.money,
            converted: converted.isConverted ? converted : nil
        )
    }

    static let userInfoURL = URL(string: "https://api.siliconflow.cn/v1/user/info")!

    struct Envelope: Decodable, Sendable {
        var data: Info?
    }

    struct Info: Decodable, Sendable {
        var totalBalance: FlexibleDecimal?
        var balance: FlexibleDecimal?
        var chargeBalance: FlexibleDecimal?
    }
}
