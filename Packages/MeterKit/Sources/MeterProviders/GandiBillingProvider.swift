import Foundation
import MeterCore

/// Gandi 预充值余额。
///
/// 文档：`GET /v5/billing/info`
/// 认证：`Authorization: Bearer <PAT>`（也兼容旧版 `Apikey`）。
///
/// `prepaid.amount` + `prepaid.currency`。
public struct GandiBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.gandi }

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
        let token: String
        if let primary = try? RequiredCredential.value(.personalAccessToken, in: credential, providerID: .gandi) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .gandi)
        }
        let data = try await ProviderHTTP.get(
            url: Self.infoURL,
            headers: [
                "Authorization": "Bearer \(token)",
            ],
            client: httpClient,
            providerID: .gandi
        )
        let payload = try ProviderHTTP.decode(Info.self, from: data, providerID: .gandi)
        guard let amount = payload.prepaid?.amount?.value else {
            throw ProviderError.malformedResponse(providerID: .gandi)
        }
        let converted = try BillingCurrency.convert(
            amount,
            currency: payload.prepaid?.currency,
            rates: rateSource.current,
            providerID: .gandi
        )
        return PrepaidSnapshot.make(
            providerID: .gandi,
            now: now,
            calendar: calendar,
            balance: converted.money,
            converted: converted.isConverted ? converted : nil
        )
    }

    static let infoURL = URL(string: "https://api.gandi.net/v5/billing/info")!

    struct Info: Decodable, Sendable {
        var prepaid: Prepaid?
    }

    struct Prepaid: Decodable, Sendable {
        var amount: FlexibleDecimal?
        var currency: String?
    }
}
