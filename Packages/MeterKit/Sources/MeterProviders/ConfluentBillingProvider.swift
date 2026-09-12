import Foundation
import MeterCore

/// Confluent Cloud 本月花费。
///
/// 文档：`GET /billing/v1/costs?start_date=&end_date=`
/// 认证：Cloud API Key，HTTP Basic（Key:Secret）。角色 OrganizationAdmin 或 BillingAdmin。
///
/// `amount` 是折完折扣后的美元。日线按 `start_date`。`end_date` 不含当天。
/// 数据最多晚 72 小时。一页不够就跟 `metadata.next`，只跟本 host。
public struct ConfluentBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.confluent }
    public static let apiHost = "api.confluent.cloud"
    static let maxPages = 40

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(httpClient: any HTTPClient, now: @escaping @Sendable () -> Date, calendar: Calendar) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let key = try RequiredCredential.value(.clientID, in: credential, providerID: .confluent)
        let secret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .confluent)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let fetchWindow = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let headers = [
            "Authorization": Self.basicAuthorization(id: key, secret: secret),
        ]

        var url = Self.costsURL(window: fetchWindow, calendar: calendar)
        var daily = DailySpendAccumulator()
        var pages = 0

        while true {
            let data = try await ProviderHTTP.get(
                url: url,
                headers: headers,
                client: httpClient,
                providerID: .confluent
            )
            let payload = try ProviderHTTP.decode(CostList.self, from: data, providerID: .confluent)
            for item in payload.data ?? [] {
                let amount = item.amount?.value ?? 0
                guard amount != 0 else { continue }
                let day = item.start_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                daily.add(day: fetchWindow.contains(day) ? day : fetchWindow.clamp(day), amount: Money(usd: amount))
            }
            pages += 1
            guard let next = Self.nextPageURL(payload.metadata?.next) else { break }
            // 打满上限还有下一页：截断的合计不是完整账单，宁可失败（同 Stripe）。
            if pages >= Self.maxPages {
                throw ProviderError.malformedResponse(providerID: .confluent)
            }
            url = next
        }

        return Snapshot(
            providerID: .confluent,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: daily.total(in: current, calendar: calendar),
            dailyUSD: daily.snapshotDaily
        )
    }

    static func basicAuthorization(id: String, secret: String) -> String {
        let raw = Data("\(id):\(secret)".utf8).base64EncodedString()
        return "Basic \(raw)"
    }

    static func costsURL(window: CalendarMonthWindow, calendar: Calendar) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/billing/v1/costs",
            query: [
                URLQueryItem(name: "start_date", value: window.dayString(window.start, calendar: calendar)),
                URLQueryItem(name: "end_date", value: window.dayString(window.nextStart, calendar: calendar)),
            ]
        )
    }

    /// 只跟官方 host，避免把 Key 打到别处。
    static func nextPageURL(_ raw: String?) -> URL? {
        guard let raw, let url = URL(string: raw), url.host == apiHost else { return nil }
        return url
    }

    struct CostList: Decodable, Sendable {
        var data: [Cost]?
        var metadata: Metadata?
    }

    struct Metadata: Decodable, Sendable {
        var next: String?
        var total_size: Int?
    }

    struct Cost: Decodable, Sendable {
        var start_date: String?
        var end_date: String?
        var amount: FlexibleDecimal?
        var original_amount: FlexibleDecimal?
        var discount_amount: FlexibleDecimal?
    }
}
