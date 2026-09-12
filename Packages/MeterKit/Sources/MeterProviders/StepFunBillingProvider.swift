import Foundation
import MeterCore

/// StepFun 国内站预充值余额。国际站是 `StepFunAIBillingProvider`，key 不能混用。
///
/// 文档：`GET /v1/accounts`
/// 认证：普通 API key。`api.stepfun.com` 官方字段没有币种，按人民币折。
public struct StepFunBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.stepfun }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .stepfun)
        let data = try await ProviderHTTP.get(
            url: Self.accountsURL,
            headers: [
                "Authorization": "Bearer \(apiKey)",
            ],
            client: httpClient,
            providerID: .stepfun
        )
        let payload = try ProviderHTTP.decode(Account.self, from: data, providerID: .stepfun)
        guard let available = payload.balance?.value else {
            throw ProviderError.malformedResponse(providerID: .stepfun)
        }
        let converted = try BillingCurrency.convert(
            available,
            currency: "CNY",
            rates: rateSource.current,
            providerID: .stepfun
        )
        return PrepaidSnapshot.make(
            providerID: .stepfun,
            now: now,
            calendar: calendar,
            balance: converted.money,
            converted: converted.isConverted ? converted : nil
        )
    }

    static let accountsURL = URL(string: "https://api.stepfun.com/v1/accounts")!

    struct Account: Decodable, Sendable {
        var object: String?
        var type: String?
        var balance: FlexibleDecimal?
        var total_cash_balance: FlexibleDecimal?
        var total_voucher_balance: FlexibleDecimal?
    }
}
