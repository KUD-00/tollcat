import Foundation
import MeterCore

/// Grafana Cloud 指定月份已出账用量。
///
/// 文档：`GET /api/orgs/<ORG_SLUG>/billed-usage?month=&year=`
/// 认证：Cloud Access Policy token，`Authorization: Bearer`。
///
/// `items[].amountDue` 是美元。当月可能还没出账，空列表按「未读快照」返回，
/// 不写成 $0。这不是实时 MTD，所以目录标 pendingVerification。
public struct GrafanaBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.grafana }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .grafana)
        let orgSlug = try RequiredCredential.value(.accountID, in: credential, providerID: .grafana)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let headers = [
            "Authorization": "Bearer \(token)",
        ]
        var daily = DailySpendAccumulator()
        var currentTotal: Decimal?
        var currentEmpty = false
        for month in months {
            let data = try await ProviderHTTP.get(
                url: Self.billedUsageURL(orgSlug: orgSlug, window: month, calendar: calendar),
                headers: headers,
                client: httpClient,
                providerID: .grafana
            )
            let payload = try ProviderHTTP.decode(BilledUsage.self, from: data, providerID: .grafana)
            let items = payload.items ?? []
            let total = items.reduce(Decimal(0)) { $0 + ($1.amountDue?.value ?? 0) }
            if month.start == current.start {
                currentEmpty = items.isEmpty
                currentTotal = items.isEmpty ? nil : total
            } else if !items.isEmpty {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: total),
                    current: current,
                    calendar: calendar
                )
            }
        }
        // 空列表是「本月还没出账」，不是「花了 $0」——省略读数走未读快照合同。
        if currentEmpty, currentTotal == nil, horizon == .currentMonth {
            return Snapshot(
                providerID: .grafana,
                kind: .usage,
                fetchedAt: now,
                periodStart: current.start,
                periodEnd: current.endInclusive
            )
        }
        return Snapshot(
            providerID: .grafana,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: currentTotal.map { Money(usd: $0) },
            dailyUSD: daily.snapshotDaily
        )
    }

    static func billedUsageURL(
        orgSlug: String,
        window: CalendarMonthWindow,
        calendar: Calendar
    ) -> URL {
        let parts = calendar.dateComponents([.year, .month], from: window.start)
        return ProviderURL.https(
            host: "grafana.com",
            path: "/api/orgs/\(orgSlug)/billed-usage",
            query: [
                URLQueryItem(name: "month", value: String(parts.month ?? 0)),
                URLQueryItem(name: "year", value: String(parts.year ?? 0)),
            ]
        )
    }

    struct BilledUsage: Decodable, Sendable {
        var items: [Item]?
    }

    struct Item: Decodable, Sendable {
        var amountDue: FlexibleDecimal?
        var dimensionName: String?
    }
}
