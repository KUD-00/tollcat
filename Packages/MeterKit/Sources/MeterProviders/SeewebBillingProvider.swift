import Foundation
import MeterCore

/// Seeweb ECS 月度用量花费（servers / templates / snapshots billing）。
///
/// 文档：https://docs.seeweb.it/en/hosting/cloudserver/rest-api/API-Endpoints/Billing/
/// 认证：`X-APITOKEN`（长效 API token）。Host：`api.seeweb.it`。
/// 金额：servers/templates 行 `cost`，snapshots `total_cost` / `final_cost`；公开价目为 EUR。
/// 凭据：`apiToken`/`apiKey`。
public struct SeewebBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.seeweb }
    public static let apiHost = "api.seeweb.it"

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .seeweb) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .seeweb)
        }
        let headers = [
            "X-APITOKEN": token,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: max(Self.descriptor.historyLookbackMonths, 1),
            now: now,
            calendar: calendar
        )
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0
        try currencies.observe("EUR", providerID: .seeweb)

        for month in months {
            let parts = calendar.dateComponents([.year, .month], from: month.start)
            let year = parts.year ?? 0
            let mon = parts.month ?? 0
            let serverRows = try await loadServerCosts(year: year, month: mon, headers: headers)
            let templateRows = try await loadTemplateCosts(year: year, month: mon, headers: headers)
            let snap = try await loadSnapshotCosts(year: year, month: mon, headers: headers)

            var monthTotal: Decimal = 0
            for row in serverRows {
                let amount = row.cost?.value ?? 0
                guard amount != 0 else { continue }
                monthTotal += amount
                if month.start == current.start {
                    lines.add(
                        SpendLine(
                            category: "server",
                            label: row.name ?? row.plan ?? "server",
                            amountUSD: Money(usd: amount)
                        )
                    )
                }
            }
            for row in templateRows {
                let amount = row.cost?.value ?? 0
                guard amount != 0 else { continue }
                monthTotal += amount
                if month.start == current.start {
                    lines.add(
                        SpendLine(
                            category: "template",
                            label: row.name ?? row.notes ?? "template",
                            amountUSD: Money(usd: amount)
                        )
                    )
                }
            }
            if let total = snap.total_cost?.value, total != 0 {
                monthTotal += total
                if month.start == current.start {
                    lines.add(
                        SpendLine(
                            category: "snapshot",
                            label: "snapshots",
                            amountUSD: Money(usd: total)
                        )
                    )
                }
            } else {
                for row in snap.snapshots ?? [] {
                    let amount = row.final_cost?.value ?? 0
                    guard amount != 0 else { continue }
                    monthTotal += amount
                    if month.start == current.start {
                        lines.add(
                            SpendLine(
                                category: "snapshot",
                                label: row.snapshot_name ?? "snapshot",
                                amountUSD: Money(usd: amount)
                            )
                        )
                    }
                }
            }

            guard monthTotal != 0 else { continue }
            if month.start == current.start {
                currentTotal += monthTotal
                daily.add(day: month.start, amount: Money(usd: monthTotal))
            } else if horizon == .availableHistory {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: monthTotal),
                    current: current,
                    calendar: calendar
                )
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .seeweb
        )
        return Snapshot(
            providerID: .seeweb,
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

    private func loadServerCosts(year: Int, month: Int, headers: [String: String]) async throws -> [CostRow] {
        let data = try await ProviderHTTP.get(
            url: Self.billingURL(kind: "servers", year: year, month: month),
            headers: headers,
            client: httpClient,
            providerID: .seeweb
        )
        return try decodeCostRows(data)
    }

    private func loadTemplateCosts(year: Int, month: Int, headers: [String: String]) async throws -> [CostRow] {
        let data = try await ProviderHTTP.get(
            url: Self.billingURL(kind: "templates", year: year, month: month),
            headers: headers,
            client: httpClient,
            providerID: .seeweb
        )
        return try decodeCostRows(data)
    }

    private func loadSnapshotCosts(year: Int, month: Int, headers: [String: String]) async throws -> SnapshotEnvelope {
        let data = try await ProviderHTTP.get(
            url: Self.billingURL(kind: "snapshots", year: year, month: month),
            headers: headers,
            client: httpClient,
            providerID: .seeweb
        )
        if let env = try? ProviderHTTP.decode(SnapshotEnvelope.self, from: data, providerID: .seeweb) {
            return env
        }
        // Some deployments may return a bare array of snapshot rows.
        if let rows = try? ProviderHTTP.decode([SnapshotRow].self, from: data, providerID: .seeweb) {
            return SnapshotEnvelope(total_cost: nil, snapshots: rows)
        }
        return SnapshotEnvelope(total_cost: nil, snapshots: [])
    }

    private func decodeCostRows(_ data: Data) throws -> [CostRow] {
        if let rows = try? ProviderHTTP.decode([CostRow].self, from: data, providerID: .seeweb) {
            return rows
        }
        if let env = try? ProviderHTTP.decode(CostListEnvelope.self, from: data, providerID: .seeweb) {
            return env.data ?? env.items ?? env.servers ?? env.templates ?? []
        }
        return []
    }

    static func billingURL(kind: String, year: Int, month: Int) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/ecs/v2/billing/\(kind)/\(year)/\(month)",
            query: [URLQueryItem(name: "type", value: "json")]
        )
    }

    struct CostListEnvelope: Decodable, Sendable {
        var data: [CostRow]?
        var items: [CostRow]?
        var servers: [CostRow]?
        var templates: [CostRow]?
    }

    struct CostRow: Decodable, Sendable {
        var plan: String?
        var name: String?
        var notes: String?
        var cost: FlexibleDecimal?
    }

    struct SnapshotEnvelope: Decodable, Sendable {
        var total_cost: FlexibleDecimal?
        var snapshots: [SnapshotRow]?
    }

    struct SnapshotRow: Decodable, Sendable {
        var snapshot_name: String?
        var final_cost: FlexibleDecimal?
    }
}
