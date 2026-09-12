import Foundation
import MeterCore

/// DeepInfra 本月已计价花费。
///
/// 文档：`GET /payment/usage?from=YYYY.MM`
/// 认证：`Authorization: Bearer <API key>`。
///
/// `total_cost` 的单位是**美分**。按当前日历月查，不要手算 token 单价。
public struct DeepInfraBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.deepinfra }
    static let centsPerUSD = Decimal(100)

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .deepinfra)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let from = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let currentPeriod = Self.periodQuery(now: now, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: Self.usageURL(period: Self.periodQuery(now: from.start, calendar: calendar)),
            headers: [
                "Authorization": "Bearer \(key)",
            ],
            client: httpClient,
            providerID: .deepinfra
        )
        let payload = try ProviderHTTP.decode(Usage.self, from: data, providerID: .deepinfra)
        guard let months = payload.months else {
            throw ProviderError.malformedResponse(providerID: .deepinfra)
        }
        var daily = DailySpendAccumulator()
        let matched = months.first { $0.period == currentPeriod }
            ?? (horizon == .currentMonth ? months.first : nil)
        let currentCents = matched?.total_cost?.value ?? 0
        for month in months {
            let cents = month.total_cost?.value ?? 0
            guard cents != 0, month.period != matched?.period else { continue }
            guard let start = Self.monthStart(period: month.period, calendar: calendar) else { continue }
            daily.addPastMonth(
                start: start,
                amount: Money(usd: cents / Self.centsPerUSD),
                current: current,
                calendar: calendar
            )
        }
        return Snapshot(
            providerID: .deepinfra,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentCents / Self.centsPerUSD),
            dailyUSD: daily.snapshotDaily
        )
    }

    static func periodQuery(now: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month], from: now)
        return String(format: "%04d.%02d", parts.year ?? 0, parts.month ?? 0)
    }

    static func monthStart(period: String?, calendar: Calendar) -> Date? {
        guard let period else { return nil }
        let parts = period.split(separator: ".")
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]) else { return nil }
        return calendar.date(from: DateComponents(year: year, month: month, day: 1))
    }

    static func usageURL(period: String) -> URL {
        ProviderURL.https(
            host: "api.deepinfra.com",
            path: "/payment/usage",
            query: [URLQueryItem(name: "from", value: period)]
        )
    }

    struct Usage: Decodable, Sendable {
        var months: [Month]?
        var initial_month: String?
    }

    struct Month: Decodable, Sendable {
        var period: String?
        var total_cost: FlexibleDecimal?
    }
}
