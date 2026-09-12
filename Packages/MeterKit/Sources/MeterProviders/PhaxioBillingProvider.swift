import Foundation
import MeterCore

/// Phaxio 预充值余额。
///
/// 文档：`GET /v2/account/status`
/// 认证：HTTP Basic（API key + secret）。
///
/// `data.balance` 是美分。
public struct PhaxioBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.phaxio }

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .phaxio)
        let secret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .phaxio)
        let data = try await ProviderHTTP.get(
            url: Self.statusURL,
            headers: [
                "Authorization": "Basic \(ProviderOAuth.basicValue(id: key, secret: secret))",
            ],
            client: httpClient,
            providerID: .phaxio
        )
        let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .phaxio)
        guard let cents = payload.data?.balance?.value else {
            throw ProviderError.malformedResponse(providerID: .phaxio)
        }
        return PrepaidSnapshot.make(
            providerID: .phaxio,
            now: now,
            calendar: calendar,
            balance: Money(usd: cents / 100)
        )
    }

    static let statusURL = URL(string: "https://api.phaxio.com/v2/account/status")!

    struct Envelope: Decodable, Sendable {
        var data: Status?
    }

    struct Status: Decodable, Sendable {
        var balance: FlexibleDecimal?
    }
}
