import Foundation
import MeterCore

/// OpenAI Organization Costs API。
///
/// 文档：`GET /v1/organization/costs`
/// 认证：`Authorization: Bearer <Admin Key>`（普通 API key 读不到账单）
/// 日期：`start_time` 为 Unix 秒；`bucket_width=1d`；`limit` 1…180，分页靠 `page`。
///
/// 待核对：官方 Admin API 没有信用余额接口。规格把 OpenAI 标成 prepaid，
/// 但这一轮只能拿到日费用。snapshot.kind 用 `.usage`，余额留到有官方接口再补。
/// 真账号：用 Admin Key 拉本月 costs，和平台 Usage / Costs 页对账。
public struct OpenAIBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.openai }
    static let maxPages = 20

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar
    /// 厂商用非美元结算时按这张表换。默认只认美元，行为和加它之前一样。
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
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        var currency = CurrencyAccumulator()
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .openai)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let fetchWindow = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let startTime = Int(fetchWindow.start.timeIntervalSince1970)
        let headers = [
            "Authorization": "Bearer \(apiKey)",
        ]

        var daily = DailySpendAccumulator()
        var page: String?
        var pages = 0
        repeat {
            pages += 1
            let url = Self.costsURL(
                startTime: startTime,
                limit: horizon == .currentMonth ? 31 : 180,
                page: page
            )
            let data = try await ProviderHTTP.get(
                url: url,
                headers: headers,
                client: httpClient,
                providerID: .openai
            )
            let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .openai)
            for bucket in envelope.data ?? [] {
                let day = BillingDateParser.parseUnixSeconds(bucket.start_time ?? startTime, calendar: calendar)
                for result in bucket.results ?? [] {
                    try currency.observe(result.amount?.currency, providerID: .openai)
                    if let value = result.amount?.value?.money {
                        daily.add(day: day, amount: value)
                    }
                }
            }
            page = envelope.has_more == true ? envelope.next_page : nil
            // 打满上限还有下一页：截断的合计不是完整账单，宁可失败（同 Stripe）。
            if page != nil, pages >= Self.maxPages {
                throw ProviderError.malformedResponse(providerID: .openai)
            }
        } while page != nil

        return try Snapshot(
            providerID: .openai,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: daily.total(in: current, calendar: calendar),
            dailyUSD: daily.snapshotDaily ?? [:]
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    static func costsURL(startTime: Int, limit: Int = 31, page: String?) -> URL {
        var items = [
            URLQueryItem(name: "start_time", value: String(startTime)),
            URLQueryItem(name: "bucket_width", value: "1d"),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        if let page {
            items.append(URLQueryItem(name: "page", value: page))
        }
        return ProviderURL.https(host: "api.openai.com", path: "/v1/organization/costs", query: items)
    }

    struct Envelope: Decodable, Sendable {
        var object: String?
        var data: [Bucket]?
        var has_more: Bool?
        var next_page: String?
    }

    struct Bucket: Decodable, Sendable {
        var object: String?
        var start_time: Int?
        var end_time: Int?
        var results: [Result]?
    }

    struct Result: Decodable, Sendable {
        var object: String?
        var amount: Amount?
        var line_item: String?
        var project_id: String?
    }

    struct Amount: Decodable, Sendable {
        var value: FlexibleDecimal?
        var currency: String?
    }
}
