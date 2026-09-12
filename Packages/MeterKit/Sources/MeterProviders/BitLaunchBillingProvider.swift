import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// BitLaunch 周期用量花费（`GET /usage?period=YYYY-MM`）。
///
/// 文档：https://developers.bitlaunch.io/reference/view-usage
/// 认证：`Authorization: Bearer <API token>`。
/// Host：`app.bitlaunch.io`。
/// 金额：`totalUsd` 为 USD×1000（与账户 balance 同单位）；**忽略** `GET /user` 预付余额。
public struct BitLaunchBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.bitlaunch }
    public static let apiHost = "app.bitlaunch.io"
    /// `totalUsd` / balance 文档约定：金额 = USD × 1000。
    public static let unitsPerUSD = Decimal(1000)

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .bitlaunch) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .bitlaunch)
        }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        for month in months {
            let period = String(
                format: "%04d-%02d",
                calendar.component(.year, from: month.start),
                calendar.component(.month, from: month.start)
            )
            let usage = try await loadUsage(period: period, headers: headers)
            let amount = (usage.totalUsd?.value ?? 0) / Self.unitsPerUSD
            guard amount != 0 else { continue }
            try currencies.observe("USD", providerID: .bitlaunch)
            if month.start == current.start {
                currentTotal += amount
                var rowSpend: Decimal = 0
                for bucket in [usage.serverUsage, usage.backupUsage, usage.bandwidthUsage, usage.protectionUsage] {
                    for row in bucket ?? [] {
                        let rowAmount = (row.cost?.value ?? 0) / Self.unitsPerUSD
                        guard rowAmount != 0 else { continue }
                        rowSpend += rowAmount
                        let stamp = row.start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                            ?? month.start
                        if current.contains(stamp) {
                            daily.add(day: stamp, amount: Money(usd: rowAmount))
                        }
                    }
                }
                if rowSpend == 0 {
                    daily.add(day: month.start, amount: Money(usd: amount))
                }
                lines.add(
                    SpendLine(
                        category: "usage",
                        label: period,
                        amountUSD: Money(usd: amount)
                    )
                )
            } else if horizon == .availableHistory {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: amount),
                    current: current,
                    calendar: calendar
                )
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .bitlaunch
        )
        return Snapshot(
            providerID: .bitlaunch,
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

    private func loadUsage(period: String, headers: [String: String]) async throws -> Usage {
        var components = URLComponents()
        components.scheme = "https"
        components.host = Self.apiHost
        components.path = "/api/usage"
        components.queryItems = [URLQueryItem(name: "period", value: period)]
        let url = components.url!
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .bitlaunch
        )
        return try ProviderHTTP.decode(Usage.self, from: data, providerID: .bitlaunch)
    }

    struct Usage: Decodable, Sendable {
        var totalUsd: FlexibleDecimal?
        var serverUsage: [UsageRow]?
        var backupUsage: [UsageRow]?
        var bandwidthUsage: [UsageRow]?
        var protectionUsage: [UsageRow]?
    }

    struct UsageRow: Decodable, Sendable {
        var description: String?
        var start: String?
        var end: String?
        var cost: FlexibleDecimal?
        var hours: FlexibleDecimal?
        var type: String?
    }
}
