import Foundation
import MeterCore

/// Magalu Cloud 本月消费（FOCUS `GET /consumption/usage`）。
///
/// 文档：https://docs.magalu.cloud/api/consumption
/// 认证：`x-api-key`（scope：`tally-consumption-api`）。
/// Host：`api.magalu.cloud`。
/// 金额：`BilledCost` + `BillingCurrency`（ISO 4217，例 BRL）。按 `ChargePeriodStart` 归入本月。
public struct MagaluCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.magalucloud }
    public static let apiHost = "api.magalu.cloud"
    static let maxPages = 40
    static let pageSize = 150

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
        let key: String
            if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .magalucloud) {
                key = primary
            } else {
                key = try RequiredCredential.value(.apiToken, in: credential, providerID: .magalucloud)
            }
        let headers = [
            "x-api-key": key,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let periods: [CalendarMonthWindow] = {
            if horizon == .availableHistory {
                var list: [CalendarMonthWindow] = [current]
                var cursor = current.start
                for _ in 0..<11 {
                    guard let prev = calendar.date(byAdding: .month, value: -1, to: cursor) else { break }
                    cursor = prev
                    list.append(CalendarMonthWindow.current(now: cursor, calendar: calendar))
                }
                return list
            }
            return [current]
        }()

        for window in periods {
            var offset = 0
            var pages = 0
            while pages < Self.maxPages {
                pages += 1
                let batch = try await loadUsage(window: window, offset: offset, headers: headers)
                if batch.isEmpty { break }
                for row in batch {
                    let amount = row.BilledCost?.value ?? 0
                    guard amount != 0 else { continue }
                    try currencies.observe(row.BillingCurrency, providerID: .magalucloud)
                    let stamp = row.ChargePeriodStart.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                        ?? row.BillingPeriodStart.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                        ?? window.start
                    let label = row.SkuId ?? "usage"
                    if current.contains(stamp) {
                        currentTotal += amount
                        daily.add(day: stamp, amount: Money(usd: amount))
                        lines.add(
                            SpendLine(
                                category: "usage",
                                label: label,
                                amountUSD: Money(usd: amount)
                            )
                        )
                    } else if horizon == .availableHistory {
                        daily.addPastMonth(
                            start: stamp,
                            amount: Money(usd: amount),
                            current: current,
                            calendar: calendar
                        )
                    }
                }
                if batch.count < Self.pageSize { break }
                offset += Self.pageSize
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .magalucloud
        )
        return Snapshot(
            providerID: .magalucloud,
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

    private func loadUsage(
        window: CalendarMonthWindow,
        offset: Int,
        headers: [String: String]
    ) async throws -> [UsageRow] {
        let data = try await ProviderHTTP.get(
            url: Self.usageURL(window: window, offset: offset, calendar: calendar),
            headers: headers,
            client: httpClient,
            providerID: .magalucloud
        )
        if let list = try? ProviderHTTP.decode([UsageRow].self, from: data, providerID: .magalucloud) {
            return list
        }
        let envelope = try ProviderHTTP.decode(UsageEnvelope.self, from: data, providerID: .magalucloud)
        return envelope.results ?? []
    }

    static func usageURL(window: CalendarMonthWindow, offset: Int, calendar: Calendar) -> URL {
        let start = isoDay(window.start, calendar: calendar)
        let end = isoDay(window.endInclusive, calendar: calendar)
        return ProviderURL.https(
            host: apiHost,
            path: "/consumption/usage",
            query: [
                URLQueryItem(name: "start_date", value: start),
                URLQueryItem(name: "end_date", value: end),
                URLQueryItem(name: "limit", value: String(pageSize)),
                URLQueryItem(name: "offset", value: String(offset)),
                URLQueryItem(name: "order", value: "asc"),
            ]
        )
    }

    private static func isoDay(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 1970
        let m = c.month ?? 1
        let d = c.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    struct UsageEnvelope: Decodable, Sendable {
        var results: [UsageRow]?
    }

    struct UsageRow: Decodable, Sendable {
        var SkuId: String?
        var BillingCurrency: String?
        var BilledCost: FlexibleDecimal?
        var ChargePeriodStart: String?
        var BillingPeriodStart: String?
        var ProviderName: String?
    }
}
