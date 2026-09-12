import Foundation
import MeterCore

/// FriendliAI 团队费用（`GET /v1/team/cost`）。
///
/// 文档：https://friendli.ai/docs/openapi/administration/cost
/// 认证：`Authorization: Bearer <Personal API Key>`（`flp_…`）。
/// Host：`api.friendli.ai`。可选 `X-Friendli-Team`（`accountID`）。
/// 金额：`results[].total` 文档写明 USD；日桶 `start_time`/`end_time`。
/// 凭据：`apiToken`/`apiKey`，可选 `accountID`（team id）。
public struct FriendliBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.friendli }
    public static let apiHost = "api.friendli.ai"
    static let maxPages = 20

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
        let token: String
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .friendli) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .friendli)
        }
        var headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        if let team = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !team.isEmpty {
            headers["X-Friendli-Team"] = team
        }
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
            let endExclusive = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
                ?? now
            let endingAt = min(endExclusive, calendar.date(byAdding: .day, value: 1, to: fetchWindow.endInclusive) ?? endExclusive)
            let url = Self.costURL(
                startingAt: fetchWindow.start,
                endingAt: endingAt,
                limit: 35,
                page: page
            )
            let data = try await ProviderHTTP.get(
                url: url,
                headers: headers,
                client: httpClient,
                providerID: .friendli
            )
            let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .friendli)
            for bucket in envelope.data ?? [] {
                let day = bucket.start_time.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? fetchWindow.start
                for row in bucket.results ?? [] {
                    let amount = row.total?.value ?? 0
                    guard amount != 0 else { continue }
                    try currencies.observe("USD", providerID: .friendli)
                    daily.add(day: day, amount: Money(usd: amount))
                    if current.contains(day) {
                        lines.add(
                            SpendLine(
                                category: "usage",
                                label: row.line_item ?? "cost",
                                amountUSD: Money(usd: amount)
                            )
                        )
                    }
                }
            }
            page = envelope.has_more == true ? envelope.next_page : nil
            if page != nil, pages >= Self.maxPages {
                throw ProviderError.malformedResponse(providerID: .friendli)
            }
        } while page != nil

        let converted = try currencies.convert(
            daily.total(in: current, calendar: calendar).usd,
            rates: rateSource.current,
            providerID: .friendli
        )
        return Snapshot(
            providerID: .friendli,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: converted.money,
            dailyUSD: currencies.scaled(daily.snapshotDaily, by: converted.usdPerUnit),
            converted: currencies.needsConversionNote ? converted : nil,
            lines: lines.snapshot
        )
    }

    static func costURL(startingAt: Date, endingAt: Date, limit: Int, page: String?) -> URL {
        var items = [
            URLQueryItem(name: "start_time", value: rfc3339Day(startingAt)),
            URLQueryItem(name: "end_time", value: rfc3339Day(endingAt)),
            URLQueryItem(name: "bucket_width", value: "1d"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "group_by", value: "line_item"),
        ]
        if let page, !page.isEmpty {
            items.append(URLQueryItem(name: "page", value: page))
        }
        return ProviderURL.https(host: apiHost, path: "/v1/team/cost", query: items)
    }

    static func rfc3339Day(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    struct Envelope: Decodable, Sendable {
        var data: [Bucket]?
        var has_more: Bool?
        var next_page: String?
    }

    struct Bucket: Decodable, Sendable {
        var start_time: String?
        var end_time: String?
        var results: [ResultRow]?
    }

    struct ResultRow: Decodable, Sendable {
        var total: FlexibleDecimal?
        var line_item: String?
        var quantity: FlexibleDecimal?
        var unit_price: FlexibleDecimal?
    }
}
