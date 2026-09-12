import Foundation
import MeterCore

/// Namecheap 预充值可用余额。
///
/// 文档：`namecheap.users.getBalances`（`https://api.namecheap.com/xml.response`）
/// 认证：ApiUser + ApiKey + UserName + ClientIp（IP 白名单，见凭据文档）。
///
/// XML `UserGetBalancesResult` 的 `AvailableBalance` + `Currency`。
public struct NamecheapBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.namecheap }

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
        let apiUser = try RequiredCredential.value(.accountID, in: credential, providerID: .namecheap)
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .namecheap)
        let clientIP = try RequiredCredential.value(.clientID, in: credential, providerID: .namecheap)
        let data = try await ProviderHTTP.get(
            url: Self.balancesURL(apiUser: apiUser, apiKey: apiKey, clientIP: clientIP),
            headers: [:],
            client: httpClient,
            providerID: .namecheap
        )
        guard let text = String(data: data, encoding: .utf8) else {
            throw ProviderError.malformedResponse(providerID: .namecheap)
        }
        guard let available = Self.attribute(named: "AvailableBalance", in: text).flatMap({ Decimal(string: $0) }) else {
            throw ProviderError.malformedResponse(providerID: .namecheap)
        }
        let currency = Self.attribute(named: "Currency", in: text)
        let converted = try BillingCurrency.convert(
            available,
            currency: currency,
            rates: rateSource.current,
            providerID: .namecheap
        )
        return PrepaidSnapshot.make(
            providerID: .namecheap,
            now: now,
            calendar: calendar,
            balance: converted.money,
            converted: converted.isConverted ? converted : nil
        )
    }

    static func balancesURL(apiUser: String, apiKey: String, clientIP: String) -> URL {
        ProviderURL.https(
            host: "api.namecheap.com",
            path: "/xml.response",
            query: [
                URLQueryItem(name: "ApiUser", value: apiUser),
                URLQueryItem(name: "ApiKey", value: apiKey),
                URLQueryItem(name: "UserName", value: apiUser),
                URLQueryItem(name: "ClientIp", value: clientIP),
                URLQueryItem(name: "Command", value: "namecheap.users.getBalances"),
            ]
        )
    }

    /// 从 Namecheap XML 属性里抠值，避免拉整套 XMLParser。
    static func attribute(named name: String, in xml: String) -> String? {
        let pattern = #"\#(name)\s*=\s*"([^"]*)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(xml.startIndex..<xml.endIndex, in: xml)
        guard let match = regex.firstMatch(in: xml, range: range), match.numberOfRanges > 1,
              let r = Range(match.range(at: 1), in: xml) else { return nil }
        return String(xml[r])
    }
}
