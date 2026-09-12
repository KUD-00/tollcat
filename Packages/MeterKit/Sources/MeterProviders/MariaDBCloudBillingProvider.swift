import Foundation
import MeterCore

/// MariaDB Cloud（SkySQL）本月用量分摊合计。
///
/// 文档：`GET /billing/v1/bills?year=&month=`
/// 认证：`X-API-Key`。
///
/// `total` 是该月用量分摊的账单金额，`currency` 按目录汇率折美元。
public struct MariaDBCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.mariadb }

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .mariadb)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        var currency = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var currentTotal: Decimal?
        for month in months {
            let data: Data
            do {
                data = try await ProviderHTTP.get(
                    url: Self.billsURL(window: month, calendar: calendar),
                    headers: [
                        "X-API-Key": key,
                    ],
                    client: httpClient,
                    providerID: .mariadb
                )
            } catch let error as ProviderError where error.code == .billingAPIUnavailable {
                if month.start == current.start { throw error }
                continue
            }
            let bill = try ProviderHTTP.decode(Bill.self, from: data, providerID: .mariadb)
            guard let total = bill.total?.value else {
                if month.start == current.start {
                    throw ProviderError.malformedResponse(providerID: .mariadb)
                }
                continue
            }
            try currency.observe(bill.currency, providerID: .mariadb)
            if month.start == current.start {
                currentTotal = total
            } else {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: total),
                    current: current,
                    calendar: calendar
                )
            }
        }
        guard let currentTotal else {
            throw ProviderError.malformedResponse(providerID: .mariadb)
        }
        return try Snapshot(
            providerID: .mariadb,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    static func billsURL(window: CalendarMonthWindow, calendar: Calendar) -> URL {
        let parts = calendar.dateComponents([.year, .month], from: window.start)
        return ProviderURL.https(
            host: "api.skysql.com",
            path: "/billing/v1/bills",
            query: [
                URLQueryItem(name: "year", value: String(parts.year ?? 0)),
                URLQueryItem(name: "month", value: String(parts.month ?? 0)),
            ]
        )
    }

    struct Bill: Decodable, Sendable {
        var total: FlexibleDecimal?
        var currency: String?
        var period: String?
    }
}
