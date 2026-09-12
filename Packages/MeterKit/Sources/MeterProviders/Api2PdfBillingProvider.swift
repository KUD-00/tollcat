import Foundation
import MeterCore

/// Api2Pdf 预充值余额。
///
/// 文档：`GET /balance`
/// 认证：`Authorization` 头直接放 API Key（不加 Bearer）。
///
/// `UserBalance` 是账户剩余美元。
public struct Api2PdfBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.api2pdf }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .api2pdf)
        let data = try await ProviderHTTP.get(
            url: Self.balanceURL,
            headers: [
                "Authorization": apiKey,
            ],
            client: httpClient,
            providerID: .api2pdf
        )
        let payload = try ProviderHTTP.decode(Balance.self, from: data, providerID: .api2pdf)
        guard let balance = payload.userBalance?.value else {
            throw ProviderError.malformedResponse(providerID: .api2pdf)
        }
        return PrepaidSnapshot.make(
            providerID: .api2pdf,
            now: now,
            calendar: calendar,
            balance: Money(usd: balance)
        )
    }

    static let balanceURL = URL(string: "https://v2.api2pdf.com/balance")!

    struct Balance: Decodable, Sendable {
        var userBalance: FlexibleDecimal?

        enum CodingKeys: String, CodingKey {
            case userBalance = "UserBalance"
        }
    }
}
