import Foundation
import MeterCore

/// UpCloud 本月账单合计。
///
/// 文档：`GET /1.3/account/billing/summary/{YYYY-MM}`
/// 认证：`Authorization: Bearer ucat_…`，账号要有读账单权限。
///
/// `total_amount` 是该月从余额扣掉的合计，`currency` 常见欧元，按目录汇率折。
/// 不读 `GET /account` 的剩余 credits：那是还剩多少，不是这个月花了多少。
public struct UpCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.upcloud }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .upcloud)
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
                    url: Self.summaryURL(window: month, calendar: calendar),
                    headers: [
                        "Authorization": "Bearer \(token)",
                    ],
                    client: httpClient,
                    providerID: .upcloud
                )
            } catch let error as ProviderError where error.code == .billingAPIUnavailable {
                if month.start == current.start { throw error }
                continue
            }
            let payload = try ProviderHTTP.decode(Summary.self, from: data, providerID: .upcloud)
            guard let total = payload.total_amount?.value else {
                if month.start == current.start {
                    throw ProviderError.malformedResponse(providerID: .upcloud)
                }
                continue
            }
            try currency.observe(payload.currency, providerID: .upcloud)
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
            throw ProviderError.malformedResponse(providerID: .upcloud)
        }
        return try Snapshot(
            providerID: .upcloud,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    static func summaryURL(window: CalendarMonthWindow, calendar: Calendar) -> URL {
        let parts = calendar.dateComponents([.year, .month], from: window.start)
        let period = String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
        return ProviderURL.https(
            host: "api.upcloud.com",
            path: "/1.3/account/billing/summary/\(period)"
        )
    }

    struct Summary: Decodable, Sendable {
        var currency: String?
        var total_amount: FlexibleDecimal?
    }
}
