import Foundation
import MeterCore

/// TierPoint Metallic 用量报告（仅 Metallic；不接 colo/privateCloud/storage/O365/Azure）。
///
/// `GET /api/v1/usage/org/{crmId}/metallic/usageReport?month=YYYY-MM&skuType=Consumption|MRR`
/// → `usageOverview[].totalCost` + `currency`。
///
/// OpenAPI：https://api.tierpoint.com/api/v1/usage/v3/api-docs
/// 认证：OAuth2 Bearer。`crmId=self` 可用。Host：`api.tierpoint.com`。
public struct TierPointBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.tierpoint }
    public static let apiHost = "api.tierpoint.com"

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .tierpoint)
        let crmRaw = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let crmId = (crmRaw?.isEmpty == false) ? crmRaw! : "self"
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
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
            let stamp = month.start
            let ym = Self.yearMonth(stamp, calendar: calendar)
            var monthTotal: Decimal = 0
            for sku in ["Consumption", "MRR"] {
                guard let report = try? await loadReport(
                    crmId: crmId, month: ym, skuType: sku, headers: headers
                ) else { continue }
                for row in report.usageOverview ?? [] {
                    let amount = row.totalCost?.value ?? 0
                    guard amount != 0 else { continue }
                    try currencies.observe(row.currency ?? report.currency, providerID: .tierpoint)
                    monthTotal += amount
                    if month.start == current.start {
                        let label = row.sku ?? row.name ?? row.description ?? sku
                        lines.add(
                            SpendLine(
                                category: sku.lowercased(),
                                label: label,
                                amountUSD: Money(usd: amount)
                            )
                        )
                    }
                }
            }
            if month.start == current.start {
                currentTotal = monthTotal
            } else if monthTotal != 0 {
                daily.addPastMonth(
                    start: stamp,
                    amount: Money(usd: monthTotal),
                    current: current,
                    calendar: calendar
                )
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .tierpoint
        )
        return Snapshot(
            providerID: .tierpoint,
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

    private func loadReport(
        crmId: String,
        month: String,
        skuType: String,
        headers: [String: String]
    ) async throws -> UsageReport {
        let url = ProviderURL.https(
            host: Self.apiHost,
            path: "/api/v1/usage/org/\(crmId)/metallic/usageReport",
            query: [
                URLQueryItem(name: "month", value: month),
                URLQueryItem(name: "skuType", value: skuType),
            ]
        )
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .tierpoint
        )
        return try ProviderHTTP.decode(UsageReport.self, from: data, providerID: .tierpoint)
    }

    static func yearMonth(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    struct UsageReport: Decodable, Sendable {
        var currency: String?
        var usageOverview: [UsageRow]?
    }

    struct UsageRow: Decodable, Sendable {
        var totalCost: FlexibleDecimal?
        var currency: String?
        var sku: String?
        var name: String?
        var description: String?
    }
}
