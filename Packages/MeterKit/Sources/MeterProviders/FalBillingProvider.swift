import Foundation
import MeterCore

/// fal.ai 本月模型用量花费（跳过 /account/billing credits）。
///
/// 文档：`GET /v1/models/usage`
/// 认证：`Authorization: Key <Admin API key>`
///
/// `cost_total` / `cost_subtotal` + `currency` 是区间美元（或可换算币种）。
public struct FalBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.fal }

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .fal)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let headers = [
            "Authorization": "Key \(key)",
        ]
        var currency = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var currentTotal: Decimal = 0
        for month in months {
            let data = try await ProviderHTTP.get(
                url: Self.usageURL(window: month, calendar: calendar),
                headers: headers,
                client: httpClient,
                providerID: .fal
            )
            let payload = try ProviderHTTP.decode(Usage.self, from: data, providerID: .fal)
            try currency.observe(payload.currency, providerID: .fal)
            let amount = payload.cost_total?.value
                ?? payload.cost_subtotal?.value
                ?? 0
            if month.start == current.start {
                currentTotal = amount
                for row in payload.results ?? payload.items ?? [] {
                    let rowAmount = row.cost_total?.value ?? row.cost?.value ?? 0
                    guard rowAmount != 0 else { continue }
                    try currency.observe(row.currency ?? payload.currency, providerID: .fal)
                    let day = (row.date ?? row.day).flatMap { BillingDateParser.parse($0, calendar: calendar) }
                        ?? month.start
                    daily.add(day: calendar.startOfDay(for: day), amount: Money(usd: rowAmount))
                }
            } else {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: amount),
                    current: current,
                    calendar: calendar
                )
            }
        }
        return try Snapshot(
            providerID: .fal,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    static func usageURL(window: CalendarMonthWindow, calendar: Calendar) -> URL {
        ProviderURL.https(
            host: "api.fal.ai",
            path: "/v1/models/usage",
            query: [
                URLQueryItem(name: "start_date", value: window.dayString(window.start, calendar: calendar)),
                URLQueryItem(name: "end_date", value: window.dayString(window.endInclusive, calendar: calendar)),
            ]
        )
    }

    struct Usage: Decodable, Sendable {
        var cost_total: FlexibleDecimal?
        var cost_subtotal: FlexibleDecimal?
        var currency: String?
        var results: [Row]?
        var items: [Row]?
    }

    struct Row: Decodable, Sendable {
        var cost_total: FlexibleDecimal?
        var cost: FlexibleDecimal?
        var currency: String?
        var date: String?
        var day: String?
    }
}
