import Foundation
import MeterCore

/// SurrealDB Cloud 本月用量花费（优先 spend millicents，发票 cents 回退）。
///
/// 文档：
/// - `GET /api/cloud/v0/organizations/{org}/spend?period=MM-YYYY` → `amount_millcents`
/// - `GET /api/cloud/v0/organizations/{org}/billing/invoices` → `amount`（美分 USD）
/// 认证：`Authorization: Bearer <PAT>`（或 Cloud token）。
public struct SurrealDBBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.surrealdb }

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
        let org = try RequiredCredential.value(.accountID, in: credential, providerID: .surrealdb)
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .surrealdb)
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
        var usedSpend = false

        for month in months {
            if let entries = try? await loadSpend(org: org, window: month, headers: headers) {
                usedSpend = true
                var monthTotal: Decimal = 0
                for entry in entries {
                    let millicents = entry.amount_millcents?.value ?? 0
                    let amount = millicents / 100_000
                    guard amount != 0 else { continue }
                    monthTotal += amount
                    if month.start == current.start {
                        let label = entry.description?.trimmed
                            ?? entry.resource?.trimmed
                            ?? "usage"
                        lines.add(
                            SpendLine(
                                category: entry.resource?.trimmed ?? "usage",
                                label: label,
                                amountUSD: Money(usd: amount)
                            )
                        )
                    }
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
        }

        if !usedSpend {
            let invoices = try await loadInvoices(org: org, headers: headers)
            for invoice in invoices {
                let cents = invoice.amount?.value ?? 0
                let amount = cents / 100
                guard amount != 0 else { continue }
                let stamp = invoice.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                if current.contains(stamp) {
                    currentTotal += amount
                } else if horizon == .availableHistory {
                    daily.addPastMonth(
                        start: stamp,
                        amount: Money(usd: amount),
                        current: current,
                        calendar: calendar
                    )
                }
            }
        }

        return Snapshot(
            providerID: .surrealdb,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily,
            lines: lines.snapshot
        )
    }

    private func loadSpend(
        org: String,
        window: CalendarMonthWindow,
        headers: [String: String]
    ) async throws -> [SpendEntry] {
        let parts = calendar.dateComponents([.year, .month], from: window.start)
        let period = String(format: "%02d-%04d", parts.month ?? 0, parts.year ?? 0)
        let url = ProviderURL.https(
            host: "api.surrealdb.com",
            path: "/api/cloud/v0/organizations/\(org)/spend",
            query: [URLQueryItem(name: "period", value: period)]
        )
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .surrealdb
        )
        return try ProviderHTTP.decode([SpendEntry].self, from: data, providerID: .surrealdb)
    }

    private func loadInvoices(org: String, headers: [String: String]) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: ProviderURL.https(
                host: "api.surrealdb.com",
                path: "/api/cloud/v0/organizations/\(org)/billing/invoices"
            ),
            headers: headers,
            client: httpClient,
            providerID: .surrealdb
        )
        return try ProviderHTTP.decode([Invoice].self, from: data, providerID: .surrealdb)
    }

    struct SpendEntry: Decodable, Sendable {
        var organization_id: String?
        var description: String?
        var resource: String?
        var amount_millcents: FlexibleDecimal?
        var effective_at: String?
        var instance_id: String?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var date: String?
        var amount: FlexibleDecimal?
        var status: String?
        var url: String?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
