import Foundation
import MeterCore

/// Vonage（Nexmo）本月用量花费。
///
/// 文档：`GET /v2/reports/records`（Reports API）
/// 认证：HTTP Basic，用户名 API Key，密码 API Secret。
///
/// 对本月窗口内各产品记录的 `total_price` + `currency` 求和。
/// 不再用 `get-balance` 预充值余额当作本月花费。
public struct VonageBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.vonage }
    /// 官方同步接口单次最多约 1000 条；按产品轮询。
    public static let products = ["SMS", "VOICE-CALL", "VOICE-TTS", "VERIFY-API", "NUMBER-INSIGHT", "MESSAGES"]
    public static let maxPagesPerProduct = 5

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
        let key = try RequiredCredential.value(.clientID, in: credential, providerID: .vonage)
        let secret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .vonage)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let headers = [
            "Authorization": Self.basicAuthorization(key: key, secret: secret),
        ]
        var currencies = CurrencyAccumulator()
        var total = Decimal(0)
        let fmt = ISO8601DateFormatter()

        for product in Self.products {
            var pages = 0
            var cursorStart = window.start
            while pages < Self.maxPagesPerProduct {
                pages += 1
                let data: Data
                do {
                    data = try await ProviderHTTP.get(
                        url: Self.recordsURL(
                            accountID: key,
                            product: product,
                            dateStart: fmt.string(from: cursorStart),
                            dateEnd: fmt.string(from: min(now, window.nextStart))
                        ),
                        headers: headers,
                        client: httpClient,
                        providerID: .vonage
                    )
                } catch let error as ProviderError where error.code == .billingAPIUnavailable {
                    // 部分产品账号未开通时跳过
                    break
                }
                let payload = try ProviderHTTP.decode(Report.self, from: data, providerID: .vonage)
                let records = payload.records ?? []
                for record in records {
                    guard let price = record.total_price?.value else { continue }
                    try currencies.observe(record.currency ?? payload.currency, providerID: .vonage)
                    total += price
                }
                if records.count < 1000 { break }
                // 推进窗口：用最后一条 finalized/received 时间
                if let last = records.last?.date_finalized ?? records.last?.date_received,
                   let next = BillingDateParser.parse(last, calendar: calendar),
                   next > cursorStart {
                    cursorStart = next
                } else {
                    break
                }
            }
        }

        let converted = try currencies.convert(total, rates: rateSource.current, providerID: .vonage)
        return Snapshot(
            providerID: .vonage,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: converted.money,
            converted: currencies.needsConversionNote ? converted : nil
        )
    }

    static func basicAuthorization(key: String, secret: String) -> String {
        "Basic \(ProviderOAuth.basicValue(id: key, secret: secret))"
    }

    static func recordsURL(accountID: String, product: String, dateStart: String, dateEnd: String) -> URL {
        ProviderURL.https(
            host: "api.nexmo.com",
            path: "/v2/reports/records",
            query: [
                URLQueryItem(name: "account_id", value: accountID),
                URLQueryItem(name: "product", value: product),
                URLQueryItem(name: "date_start", value: dateStart),
                URLQueryItem(name: "date_end", value: dateEnd),
            ]
        )
    }

    struct Report: Decodable, Sendable {
        var currency: String?
        var records: [Record]?
    }

    struct Record: Decodable, Sendable {
        var currency: String?
        var total_price: FlexibleDecimal?
        var date_received: String?
        var date_finalized: String?
    }
}
