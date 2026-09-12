import Foundation
import MeterCore

/// AI/ML API 预充值余额。
///
/// 文档：`GET /v2/billing`
/// 认证：普通 API key。`current_balance` 官方是美元。
public struct AIMLAPIBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.aimlapi }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .aimlapi)
        let data = try await ProviderHTTP.get(
            url: Self.billingURL,
            headers: [
                "Authorization": "Bearer \(apiKey)",
            ],
            client: httpClient,
            providerID: .aimlapi
        )
        let payload = try ProviderHTTP.decode(Balance.self, from: data, providerID: .aimlapi)
        guard let available = payload.current_balance?.value else {
            throw ProviderError.malformedResponse(providerID: .aimlapi)
        }
        let converted = try BillingCurrency.convert(
            available,
            currency: payload.currency,
            rates: rateSource.current,
            providerID: .aimlapi
        )
        return PrepaidSnapshot.make(
            providerID: .aimlapi,
            now: now,
            calendar: calendar,
            balance: converted.money,
            converted: converted.isConverted ? converted : nil
        )
    }

    static let billingURL = URL(string: "https://api.aimlapi.com/v2/billing")!

    struct Balance: Decodable, Sendable {
        var current_balance: FlexibleDecimal?
        var currency: String?
    }
}
