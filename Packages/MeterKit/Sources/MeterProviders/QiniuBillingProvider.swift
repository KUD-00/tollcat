import Foundation
import MeterCore

/// 七牛云本月账单费用（优先），否则预充值余额。
///
/// 文档：`GET /billing-api/v1/bill/overview`；回退 `GET /billing-api/v1/account/balance-overview`
/// 认证：Qiniu Mac，`Authorization: Qiniu <AK>:<sign>`（HMAC-SHA1 + URL-safe Base64）。
///
/// `fee` / 余额字段按文档是 ×1e8 的整数；`currency` 为 CNY 或 USD。
public struct QiniuBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.qiniu }

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
        let accessKey = try RequiredCredential.value(.accessKeyID, in: credential, providerID: .qiniu)
        let secretKey = try RequiredCredential.value(.secretAccessKey, in: credential, providerID: .qiniu)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)

        let overviewURL = Self.billOverviewURL(month: window.start, calendar: calendar)
        let overviewData = try await ProviderHTTP.get(
            url: overviewURL,
            headers: [
                "Authorization": Self.authorization(
                    method: "GET",
                    url: overviewURL,
                    accessKey: accessKey,
                    secretKey: secretKey
                ),
            ],
            client: httpClient,
            providerID: .qiniu
        )
        if let payload = try? ProviderHTTP.decode(BillOverview.self, from: overviewData, providerID: .qiniu),
           let fee = payload.fee?.value ?? payload.data?.fee?.value {
            let amount = fee / Decimal(100_000_000)
            let currency = payload.currency ?? payload.data?.currency
            let converted = try BillingCurrency.convert(
                amount,
                currency: currency,
                rates: rateSource.current,
                providerID: .qiniu
            )
            return Snapshot(
                providerID: .qiniu,
                kind: .usage,
                fetchedAt: now,
                periodStart: window.start,
                periodEnd: window.endInclusive,
                currentSpendUSD: converted.money,
                converted: converted.isConverted ? converted : nil
            )
        }

        let balanceURL = Self.balanceOverviewURL
        let data = try await ProviderHTTP.get(
            url: balanceURL,
            headers: [
                "Authorization": Self.authorization(
                    method: "GET",
                    url: balanceURL,
                    accessKey: accessKey,
                    secretKey: secretKey
                ),
            ],
            client: httpClient,
            providerID: .qiniu
        )
        let payload = try ProviderHTTP.decode(BalanceOverview.self, from: data, providerID: .qiniu)
        guard let raw = payload.balance?.value ?? payload.data?.balance?.value else {
            throw ProviderError.malformedResponse(providerID: .qiniu)
        }
        let amount = raw / Decimal(100_000_000)
        let currency = payload.currency ?? payload.data?.currency
        let converted = try BillingCurrency.convert(
            amount,
            currency: currency,
            rates: rateSource.current,
            providerID: .qiniu
        )
        return PrepaidSnapshot.make(
            providerID: .qiniu,
            now: now,
            calendar: calendar,
            balance: converted.money,
            converted: converted.isConverted ? converted : nil
        )
    }

    static func billOverviewURL(month: Date, calendar: Calendar) -> URL {
        let parts = calendar.dateComponents([.year, .month], from: month)
        let monthStr = String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
        return ProviderURL.https(
            host: "api.qiniu.com",
            path: "/billing-api/v1/bill/overview",
            query: [URLQueryItem(name: "month", value: monthStr)]
        )
    }

    static let balanceOverviewURL = URL(string: "https://api.qiniu.com/billing-api/v1/account/balance-overview")!

    /// Qiniu Mac：`HMAC-SHA1(SK, "<Method> <PathWithQuery>\nHost: <Host>\n\n")`，再 URL-safe Base64。
    static func authorization(method: String, url: URL, accessKey: String, secretKey: String) -> String {
        let path = url.path + (url.query.map { "?\($0)" } ?? "")
        let host = url.host ?? "api.qiniu.com"
        let signing = "\(method) \(path)\nHost: \(host)\n\n"
        let mac = MeterHMAC.sha1(key: Data(secretKey.utf8), message: Data(signing.utf8))
        let sign = Data(mac).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        return "Qiniu \(accessKey):\(sign)"
    }

    struct BillOverview: Decodable, Sendable {
        var fee: FlexibleDecimal?
        var currency: String?
        var data: Nested?
        struct Nested: Decodable, Sendable {
            var fee: FlexibleDecimal?
            var currency: String?
        }
    }

    struct BalanceOverview: Decodable, Sendable {
        var balance: FlexibleDecimal?
        var currency: String?
        var data: Nested?
        struct Nested: Decodable, Sendable {
            var balance: FlexibleDecimal?
            var currency: String?
        }
    }
}
