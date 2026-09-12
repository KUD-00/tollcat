import Foundation
import MeterCore

/// Scaleway 本月消费。
///
/// 文档：`GET /billing/v2beta1/consumptions`
/// 认证：`X-Auth-Token: <Secret Key>`，权限 `BillingReadOnly`。
///
/// 金额是 Google Money（`units` + `nanos`）。法国户经常是欧元，按目录汇率折美元。
/// `billing_period` 用 `YYYY-MM`；一页最多 100 条，按 `total_count` 翻页。
public struct ScalewayBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.scaleway }
    static let nanosPerUnit = Decimal(1_000_000_000)
    static let pageSize = 100

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .scaleway)
        let organizationID = try RequiredCredential.value(.accountID, in: credential, providerID: .scaleway)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let headers = [
            "X-Auth-Token": token,
        ]

        var currency = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var currentTotal = Decimal(0)
        for month in months {
            let total = try await loadPeriod(
                organizationID: organizationID,
                period: Self.billingPeriod(window: month, calendar: calendar),
                headers: headers,
                currency: &currency
            )
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

        return try Snapshot(
            providerID: .scaleway,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    private func loadPeriod(
        organizationID: String,
        period: String,
        headers: [String: String],
        currency: inout CurrencyAccumulator
    ) async throws -> Decimal {
        var total = Decimal(0)
        var page = 1
        var fetched = 0
        var reportedTotal: Int?
        repeat {
            let data = try await ProviderHTTP.get(
                url: Self.consumptionsURL(organizationID: organizationID, period: period, page: page),
                headers: headers,
                client: httpClient,
                providerID: .scaleway
            )
            let payload = try ProviderHTTP.decode(ConsumptionList.self, from: data, providerID: .scaleway)
            let rows = payload.consumptions ?? []
            guard !rows.isEmpty else { break }
            for row in rows {
                try currency.observe(row.value?.currency_code, providerID: .scaleway)
                total += row.value?.decimal ?? 0
            }
            fetched += rows.count
            reportedTotal = payload.total_count.map { Int($0) } ?? reportedTotal
            page += 1
        } while fetched < (reportedTotal ?? fetched)
        return total
    }

    static func billingPeriod(window: CalendarMonthWindow, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month], from: window.start)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    static func consumptionsURL(organizationID: String, period: String, page: Int) -> URL {
        ProviderURL.https(
            host: "api.scaleway.com",
            path: "/billing/v2beta1/consumptions",
            query: [
                URLQueryItem(name: "organization_id", value: organizationID),
                URLQueryItem(name: "billing_period", value: period),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "page_size", value: String(pageSize)),
            ]
        )
    }

    struct ConsumptionList: Decodable, Sendable {
        var consumptions: [Consumption]?
        var total_count: UInt64?
    }

    struct Consumption: Decodable, Sendable {
        var value: GoogleMoney?
        var product_name: String?
    }

    struct GoogleMoney: Decodable, Sendable {
        var currency_code: String?
        var units: FlexibleDecimal?
        var nanos: Int?

        var decimal: Decimal {
            (units?.value ?? 0) + Decimal(nanos ?? 0) / nanosPerUnit
        }
    }
}
