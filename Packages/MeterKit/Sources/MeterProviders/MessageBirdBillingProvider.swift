import Foundation
import MeterCore

/// MessageBird 预充值余额。
///
/// 文档：`GET /balance`
/// 认证：`Authorization: AccessKey <key>`。
///
/// `amount` 是还剩多少。`type` 是 euros / pounds / dollars / ISO 4217。
/// credits 不是钱，折不出来。后付费账户这条接口报 0，当畸形响应。
public struct MessageBirdBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.messagebird }

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .messagebird)
        let data = try await ProviderHTTP.get(
            url: Self.balanceURL,
            headers: [
                "Authorization": "AccessKey \(key)",
            ],
            client: httpClient,
            providerID: .messagebird
        )
        let payload = try ProviderHTTP.decode(Balance.self, from: data, providerID: .messagebird)
        if payload.payment?.lowercased() == "postpaid" {
            throw ProviderError.malformedResponse(providerID: .messagebird)
        }
        guard let available = payload.amount?.value else {
            throw ProviderError.malformedResponse(providerID: .messagebird)
        }
        guard let currency = Self.currencyCode(payload.type) else {
            throw ProviderError.unsupportedCurrency(providerID: .messagebird)
        }
        let converted = try BillingCurrency.convert(
            available,
            currency: currency,
            rates: rateSource.current,
            providerID: .messagebird
        )
        return PrepaidSnapshot.make(
            providerID: .messagebird,
            now: now,
            calendar: calendar,
            balance: converted.money,
            converted: converted.isConverted ? converted : nil
        )
    }

    static func currencyCode(_ raw: String?) -> String? {
        switch raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case nil, "": return nil
        case "credits": return nil
        case "euros": return "EUR"
        case "pounds": return "GBP"
        case "dollars": return "USD"
        default: return BillingCurrency.normalize(raw)
        }
    }

    static let balanceURL = URL(string: "https://rest.messagebird.com/balance")!

    struct Balance: Decodable, Sendable {
        var payment: String?
        var type: String?
        var amount: FlexibleDecimal?
    }
}
