import Foundation
import MeterCore

/// Voltage Park 本月按量扣费（跳过预充值余额）。
///
/// 文档：`GET /api/v1/billing/reports/{year}/{month}/transactions`
/// 认证：`Authorization: Bearer <API token>`。
///
/// 只累计 `details.type` 为 charge / baremetal_charge / storage_charge 的
/// `period_amount`（美元字符串）；忽略 stripe_deposit / payout。
public struct VoltageParkBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.voltagepark }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .voltagepark)
        let headers = [
            "Authorization": "Bearer \(token)",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        for month in months {
            let data = try await ProviderHTTP.get(
                url: Self.reportURL(window: month, calendar: calendar),
                headers: headers,
                client: httpClient,
                providerID: .voltagepark
            )
            let payload = try ProviderHTTP.decode(MonthlyReport.self, from: data, providerID: .voltagepark)
            var monthTotal: Decimal = 0
            for row in payload.transactions ?? [] {
                let type = row.details?.type?.trimmed ?? ""
                guard Self.chargeTypes.contains(type) else { continue }
                let amount = abs(row.period_amount?.value ?? row.total_amount?.value ?? 0)
                guard amount != 0 else { continue }
                monthTotal += amount
                if month.start == current.start {
                    let day = row.timestamp_creation
                        .flatMap { BillingDateParser.parse($0, calendar: calendar) }
                        .map { calendar.startOfDay(for: $0) }
                        ?? month.start
                    if current.contains(day) {
                        daily.add(day: day, amount: Money(usd: amount))
                    }
                    lines.add(
                        SpendLine(
                            category: type,
                            label: type,
                            amountUSD: Money(usd: amount)
                        )
                    )
                }
            }
            // Fallback: if no typed charges, use negative balance delta as spend.
            if monthTotal == 0, let delta = payload.balance_delta_in_period?.value, delta < 0 {
                monthTotal = abs(delta)
            }
            if month.start == current.start {
                currentTotal = monthTotal
            } else {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: monthTotal),
                    current: current,
                    calendar: calendar
                )
            }
        }

        return Snapshot(
            providerID: .voltagepark,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily,
            lines: lines.snapshot
        )
    }

    static let chargeTypes: Set<String> = [
        "charge",
        "baremetal_charge",
        "storage_charge",
    ]

    static func reportURL(window: CalendarMonthWindow, calendar: Calendar) -> URL {
        let parts = calendar.dateComponents([.year, .month], from: window.start)
        return ProviderURL.https(
            host: "cloud-api.voltagepark.com",
            path: "/api/v1/billing/reports/\(parts.year ?? 0)/\(parts.month ?? 0)/transactions"
        )
    }

    struct MonthlyReport: Decodable, Sendable {
        var transactions: [Transaction]?
        var balance_delta_in_period: FlexibleDecimal?
        var balance_at_period_start: FlexibleDecimal?
        var balance_at_period_end: FlexibleDecimal?
    }

    struct Transaction: Decodable, Sendable {
        var id: String?
        var total_amount: FlexibleDecimal?
        var period_amount: FlexibleDecimal?
        var timestamp_creation: String?
        var details: Details?
    }

    struct Details: Decodable, Sendable {
        var type: String?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
