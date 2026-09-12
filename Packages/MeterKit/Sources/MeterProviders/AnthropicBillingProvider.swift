import Foundation
import MeterCore

/// Anthropic Admin Cost Report（`GET /v1/organizations/cost_report`）。
///
/// 文档：https://platform.claude.com/docs/en/manage-claude/usage-cost-api
/// 认证：`x-api-key: sk-ant-admin…` + `anthropic-version: 2023-06-01`（Console / Claude Platform；非 Bedrock）。
/// 金额：USD，`amount` 为最低货币单位（分）的十进制字符串，例如 `"123.45"` = $1.2345 → 除以 100。
/// 粒度：仅 `bucket_width=1d`。
public struct AnthropicBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.anthropic }
    public static let apiHost = "api.anthropic.com"
    static let maxPages = 20
    static let apiVersion = "2023-06-01"

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
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .anthropic)
        let headers = [
            "x-api-key": apiKey,
            "anthropic-version": Self.apiVersion,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let fetchWindow = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: max(Self.descriptor.historyLookbackMonths, 1),
            now: now,
            calendar: calendar
        )
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var page: String?
        var pages = 0

        repeat {
            pages += 1
            let url = Self.costURL(
                startingAt: fetchWindow.start,
                endingAt: calendar.date(byAdding: .day, value: 1, to: fetchWindow.endInclusive)
                    ?? fetchWindow.endInclusive,
                limit: horizon == .currentMonth ? 31 : 31,
                page: page
            )
            let data = try await ProviderHTTP.get(
                url: url,
                headers: headers,
                client: httpClient,
                providerID: .anthropic
            )
            let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .anthropic)
            for bucket in envelope.data ?? [] {
                let day = BillingDateParser.parse(bucket.starting_at ?? "", calendar: calendar)
                    ?? fetchWindow.start
                for row in bucket.results ?? [] {
                    try currencies.observe(row.currency ?? "USD", providerID: .anthropic)
                    let cents = row.amount?.value ?? 0
                    let dollars = cents / 100
                    guard dollars != 0 else { continue }
                    daily.add(day: day, amount: Money(usd: dollars))
                    if current.contains(day) {
                        let label = row.description
                            ?? row.model
                            ?? row.cost_type
                            ?? "cost"
                        lines.add(
                            SpendLine(
                                category: row.cost_type ?? "usage",
                                label: label,
                                amountUSD: Money(usd: dollars)
                            )
                        )
                    }
                }
            }
            page = envelope.has_more == true ? envelope.next_page : nil
            if page != nil, pages >= Self.maxPages {
                throw ProviderError.malformedResponse(providerID: .anthropic)
            }
        } while page != nil

        return try Snapshot(
            providerID: .anthropic,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: daily.total(in: current, calendar: calendar),
            dailyUSD: daily.snapshotDaily ?? [:],
            lines: lines.snapshot
        ).convertedToUSD(using: currencies, rates: rateSource.current)
    }

    static func costURL(startingAt: Date, endingAt: Date, limit: Int, page: String?) -> URL {
        var items = [
            URLQueryItem(name: "starting_at", value: Self.rfc3339(startingAt)),
            URLQueryItem(name: "ending_at", value: Self.rfc3339(endingAt)),
            URLQueryItem(name: "bucket_width", value: "1d"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "group_by[]", value: "description"),
        ]
        if let page {
            items.append(URLQueryItem(name: "page", value: page))
        }
        return ProviderURL.https(
            host: apiHost,
            path: "/v1/organizations/cost_report",
            query: items
        )
    }

    static func rfc3339(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02dT00:00:00Z",
            c.year ?? 0, c.month ?? 0, c.day ?? 0
        )
    }

    struct Envelope: Decodable, Sendable {
        var data: [Bucket]?
        var has_more: Bool?
        var next_page: String?
    }

    struct Bucket: Decodable, Sendable {
        var starting_at: String?
        var ending_at: String?
        var results: [Row]?
    }

    struct Row: Decodable, Sendable {
        var amount: FlexibleDecimal?
        var currency: String?
        var description: String?
        var cost_type: String?
        var model: String?
        var workspace_id: String?
    }
}
