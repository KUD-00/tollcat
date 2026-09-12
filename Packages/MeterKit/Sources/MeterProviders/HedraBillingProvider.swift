import Foundation
import MeterCore

/// Hedra 周期用量花费（`GET /v3/usage` → `total_spent` / `spent` + ISO `currency`）。
///
/// 文档：https://www.hedra.com/docs/api-reference/v3/billing/get-usage
/// 认证：Bearer API key。Host：`api.hedra.com`。
/// `group_by=day` 填日线；`group_by=total` 取合计。预充值钱包可用，但本适配器记 period rated usage。
public struct HedraBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.hedra }
    public static let apiHost = "api.hedra.com"

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
        let auth: String
        if let token = credential.value(for: .apiToken)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !token.isEmpty {
            auth = token
        } else {
            auth = try RequiredCredential.value(.apiKey, in: credential, providerID: .hedra)
        }
        let headers = [
            "Authorization": "Bearer \(auth)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let window = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: max(Self.descriptor.historyLookbackMonths, 1),
            now: now,
            calendar: calendar
        )
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()

        // Daily breakdown
        let dayURL = ProviderURL.https(
            host: Self.apiHost,
            path: "/v3/usage",
            query: [
                URLQueryItem(name: "start", value: Self.rfc3339(window.start)),
                URLQueryItem(name: "end", value: Self.rfc3339(window.endInclusive)),
                URLQueryItem(name: "group_by", value: "day"),
            ]
        )
        if let data = try? await ProviderHTTP.get(
            url: dayURL, headers: headers, client: httpClient, providerID: .hedra
        ), let payload = try? ProviderHTTP.decode(UsagePayload.self, from: data, providerID: .hedra) {
            try currencies.observe(payload.currency ?? "USD", providerID: .hedra)
            for row in payload.rows {
                let amount = row.spent?.value ?? row.total_spent?.value ?? row.amount?.value ?? 0
                guard amount != 0 else { continue }
                let day = row.day.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? row.start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                daily.add(day: day, amount: Money(usd: amount))
                if current.contains(day) {
                    lines.add(
                        SpendLine(
                            category: row.model ?? "usage",
                            label: row.model ?? row.day ?? "day",
                            amountUSD: Money(usd: amount)
                        )
                    )
                }
            }
        }

        // Total for current window (authoritative period sum)
        let totalURL = ProviderURL.https(
            host: Self.apiHost,
            path: "/v3/usage",
            query: [
                URLQueryItem(name: "start", value: Self.rfc3339(current.start)),
                URLQueryItem(name: "end", value: Self.rfc3339(current.endInclusive)),
                URLQueryItem(name: "group_by", value: "total"),
            ]
        )
        let totalData = try await ProviderHTTP.get(
            url: totalURL, headers: headers, client: httpClient, providerID: .hedra
        )
        let totalPayload = try ProviderHTTP.decode(UsagePayload.self, from: totalData, providerID: .hedra)
        try currencies.observe(totalPayload.currency ?? "USD", providerID: .hedra)
        var currentTotal = totalPayload.total_spent?.value
            ?? totalPayload.spent?.value
            ?? daily.total(in: current, calendar: calendar).usd
        if currentTotal == 0 {
            currentTotal = daily.total(in: current, calendar: calendar).usd
        }
        if daily.snapshotDaily == nil, currentTotal != 0 {
            daily.add(day: current.start, amount: Money(usd: currentTotal))
        }

        // Optional model breakdown for lines
        let existingLines = lines.snapshot ?? []
        if existingLines.isEmpty {
            let modelURL = ProviderURL.https(
                host: Self.apiHost,
                path: "/v3/usage",
                query: [
                    URLQueryItem(name: "start", value: Self.rfc3339(current.start)),
                    URLQueryItem(name: "end", value: Self.rfc3339(current.endInclusive)),
                    URLQueryItem(name: "group_by", value: "model"),
                ]
            )
            if let data = try? await ProviderHTTP.get(
                url: modelURL, headers: headers, client: httpClient, providerID: .hedra
            ), let payload = try? ProviderHTTP.decode(UsagePayload.self, from: data, providerID: .hedra) {
                for row in payload.rows {
                    let amount = row.spent?.value ?? row.total_spent?.value ?? 0
                    guard amount != 0 else { continue }
                    lines.add(
                        SpendLine(
                            category: "model",
                            label: row.model ?? "model",
                            amountUSD: Money(usd: amount)
                        )
                    )
                }
            }
        }

        return try Snapshot(
            providerID: .hedra,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily ?? [:],
            lines: lines.snapshot
        ).convertedToUSD(using: currencies, rates: rateSource.current)
    }

    static func rfc3339(_ date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02dT00:00:00Z", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    struct UsagePayload: Decodable, Sendable {
        var currency: String?
        var total_spent: FlexibleDecimal?
        var spent: FlexibleDecimal?
        var usage: [Row]?
        var data: [Row]?
        var results: [Row]?
        var items: [Row]?

        var rows: [Row] { usage ?? data ?? results ?? items ?? [] }
    }

    struct Row: Decodable, Sendable {
        var day: String?
        var start: String?
        var end: String?
        var model: String?
        var spent: FlexibleDecimal?
        var total_spent: FlexibleDecimal?
        var amount: FlexibleDecimal?
        var currency: String?
    }
}
