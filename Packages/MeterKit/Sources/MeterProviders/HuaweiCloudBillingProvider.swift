import Foundation
import MeterCore

/// Huawei Cloud 国际站本月账单合计。
///
/// 文档：`GET /v2/bills/customer-bills/monthly-sum?bill_cycle=YYYY-MM`
/// 宿主：`bss-intl.myhuaweicloud.com`
/// 认证：IAM token（`X-Auth-Token`）或 AK/SK 签名；本适配器使用 `X-Auth-Token`。
///
/// 响应顶层 `consume_amount` + `currency` 即本周期支出汇总。
public struct HuaweiCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.huaweicloud }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .huaweicloud)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let cycle = Self.billCycle(window.start, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: Self.monthlySumURL(billCycle: cycle),
            headers: [
                "X-Auth-Token": token,
                "Content-Type": "application/json",
            ],
            client: httpClient,
            providerID: .huaweicloud
        )
        let payload = try ProviderHTTP.decode(MonthlySum.self, from: data, providerID: .huaweicloud)
        guard let amount = payload.consume_amount?.value ?? payload.official_amount?.value else {
            throw ProviderError.malformedResponse(providerID: .huaweicloud)
        }
        var currencies = CurrencyAccumulator()
        try currencies.observe(payload.currency, providerID: .huaweicloud)
        let converted = try currencies.convert(amount, rates: rateSource.current, providerID: .huaweicloud)
        return Snapshot(
            providerID: .huaweicloud,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: converted.money,
            converted: currencies.needsConversionNote ? converted : nil
        )
    }

    static func billCycle(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    static func monthlySumURL(billCycle: String) -> URL {
        ProviderURL.https(
            host: "bss-intl.myhuaweicloud.com",
            path: "/v2/bills/customer-bills/monthly-sum",
            query: [
                URLQueryItem(name: "bill_cycle", value: billCycle),
            ]
        )
    }

    struct MonthlySum: Decodable, Sendable {
        var consume_amount: FlexibleDecimal?
        var official_amount: FlexibleDecimal?
        var currency: String?
    }
}
