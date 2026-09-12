import Foundation
import MeterCore

/// ShipStation (ShipEngine) 承运商预充值余额合计。
///
/// 文档：`GET /v1/carriers`
/// 认证：`API-Key` 头。
///
/// `carriers[].balance` 是各承运商账户剩余资金（美元）。按账户相加。
public struct ShipStationBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.shipstation }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .shipstation)
        let data = try await ProviderHTTP.get(
            url: Self.carriersURL,
            headers: [
                "API-Key": apiKey,
            ],
            client: httpClient,
            providerID: .shipstation
        )
        let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .shipstation)
        let total = (payload.carriers ?? []).reduce(Decimal(0)) { $0 + ($1.balance?.value ?? 0) }
        return PrepaidSnapshot.make(
            providerID: .shipstation,
            now: now,
            calendar: calendar,
            balance: Money(usd: total)
        )
    }

    static let carriersURL = URL(string: "https://api.shipengine.com/v1/carriers")!

    struct Envelope: Decodable, Sendable {
        var carriers: [Carrier]?
    }

    struct Carrier: Decodable, Sendable {
        var carrier_id: String?
        var balance: FlexibleDecimal?
        var requires_funded_amount: Bool?
    }
}
