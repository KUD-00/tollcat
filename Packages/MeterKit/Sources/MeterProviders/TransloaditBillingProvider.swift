import Foundation
import MeterCore

/// Transloadit 本月账单合计。
///
/// 文档：`GET /bill/{YYYY-MM}`
/// 认证：Signature Authentication，`params` + `signature`（HMAC-SHA384，`sha384:` 前缀）。
/// Auth Key 需要 `billing:read` 权限。
///
/// `total` 是当月应付美元合计。
public struct TransloaditBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.transloadit }

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
        let authKey = try RequiredCredential.value(.clientID, in: credential, providerID: .transloadit)
        let authSecret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .transloadit)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let month = Self.yearMonth(window.start, calendar: calendar)
        let params = Self.paramsJSON(authKey: authKey, expires: now.addingTimeInterval(3600))
        let signature = Self.signature(params: params, secret: authSecret)
        let data = try await ProviderHTTP.get(
            url: Self.billURL(month: month, params: params, signature: signature),
            headers: [:],
            client: httpClient,
            providerID: .transloadit
        )
        let payload = try ProviderHTTP.decode(Bill.self, from: data, providerID: .transloadit)
        guard let total = payload.total?.value else {
            throw ProviderError.malformedResponse(providerID: .transloadit)
        }
        return Snapshot(
            providerID: .transloadit,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: Money(usd: total)
        )
    }

    static func yearMonth(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    /// 紧凑 JSON；键序固定，签名与请求体同一份字节。
    static func paramsJSON(authKey: String, expires: Date) -> String {
        let expiresRaw = iso8601MillisUTC(expires)
        return #"{"auth":{"expires":"\#(expiresRaw)","key":"\#(authKey)"}}"#
    }

    static func signature(params: String, secret: String) -> String {
        let mac = MeterHMAC.sha384(key: Data(secret.utf8), message: Data(params.utf8))
        let hex = mac.map { String(format: "%02x", $0) }.joined()
        return "sha384:\(hex)"
    }

    static func billURL(month: String, params: String, signature: String) -> URL {
        ProviderURL.https(
            host: "api2.transloadit.com",
            path: "/bill/\(month)",
            query: [
                URLQueryItem(name: "params", value: params),
                URLQueryItem(name: "signature", value: signature),
            ]
        )
    }

    static func iso8601MillisUTC(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let p = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)
        let millis = (p.nanosecond ?? 0) / 1_000_000
        return String(
            format: "%04d-%02d-%02dT%02d:%02d:%02d.%03dZ",
            p.year ?? 0, p.month ?? 0, p.day ?? 0,
            p.hour ?? 0, p.minute ?? 0, p.second ?? 0, millis
        )
    }

    struct Bill: Decodable, Sendable {
        var ok: String?
        var month: String?
        var total: FlexibleDecimal?
    }
}
