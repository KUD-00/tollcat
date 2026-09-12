import Foundation
import MeterCore

/// Gcore Cloud reservation/monthly cost report（`cost` + `currency`，commit+PAYG）。
///
/// 文档：`POST https://api.gcore.com/cloud/v1/reservation_cost_report/totals`
/// body：`{ "year_month": "YYYY-MM" }`。
/// 认证：`Authorization: APIKey <api key>`（组织级；非 reseller expenses）。
public struct GcoreBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.gcore }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .gcore)
        let headers = [
            "Authorization": "APIKey \(apiKey)",
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        for month in months {
            let payload = try await loadMonth(window: month, calendar: calendar, headers: headers)
            for row in payload.results ?? [] {
                try currencies.observe(row.currency, providerID: .gcore)
                let amount = row.cost?.value ?? 0
                guard amount != 0 else { continue }
                let label = row.billing_feature_name?.trimmed
                    ?? row.type?.trimmed
                    ?? "resource"
                if month.start == current.start {
                    currentTotal += amount
                    lines.add(
                        SpendLine(
                            category: row.type?.trimmed ?? "cost",
                            label: label,
                            amountUSD: Money(usd: amount)
                        )
                    )
                } else {
                    daily.addPastMonth(
                        start: month.start,
                        amount: Money(usd: amount),
                        current: current,
                        calendar: calendar
                    )
                }
            }
        }

        let converted = try currencies.convert(currentTotal, rates: rateSource.current, providerID: .gcore)
        return Snapshot(
            providerID: .gcore,
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

    private func loadMonth(
        window: CalendarMonthWindow,
        calendar: Calendar,
        headers: [String: String]
    ) async throws -> Report {
        let y = calendar.component(.year, from: window.start)
        let m = calendar.component(.month, from: window.start)
        let yearMonth = String(format: "%04d-%02d", y, m)
        let body = try JSONSerialization.data(withJSONObject: ["year_month": yearMonth])
        let data = try await ProviderHTTP.post(
            url: Self.totalsURL,
            headers: headers,
            body: body,
            client: httpClient,
            providerID: .gcore
        )
        return try ProviderHTTP.decode(Report.self, from: data, providerID: .gcore)
    }

    static let totalsURL = ProviderURL.https(
        host: "api.gcore.com",
        path: "/cloud/v1/reservation_cost_report/totals"
    )

    struct Report: Decodable, Sendable {
        var count: Int?
        var results: [Row]?
    }

    struct Row: Decodable, Sendable {
        var type: String?
        var cost: FlexibleDecimal?
        var currency: String?
        var billing_feature_name: String?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
