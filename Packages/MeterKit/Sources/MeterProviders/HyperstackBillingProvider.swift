import Foundation
import MeterCore

/// Hyperstack (NexGen Cloud) 周期用量花费（软 LIVE：金额为美元，OpenAPI 暂无 ISO `currency` 字段）。
///
/// 文档：
/// - https://docs.hyperstack.cloud/docs/api-reference/get-last-day-cost
/// - https://docs.hyperstack.cloud/docs/api-reference/get-user-billing-history
/// 认证：`api_key` header（无前缀）。Host：`infrahub-api.nexgencloud.com`。
/// `GET /v1/billing/billing/history` → `metrics.incurred_bill`（本适配器主合计）；
/// `GET /v1/billing/billing/last-day-cost` → `data.total_cost` / `instances_cost` 作日线补充。
/// 货币暂按 USD observe；出现正式 currency 字段后再升硬 LIVE。
public struct HyperstackBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.hyperstack }
    public static let apiHost = "infrahub-api.nexgencloud.com"

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .hyperstack)
        let headers = [
            "api_key": apiKey,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let window = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: max(Self.descriptor.historyLookbackMonths, 1),
            now: now,
            calendar: calendar
        )
        var currencies = CurrencyAccumulator()
        // Soft LIVE: docs quote dollars; no ISO currency in OpenAPI examples yet.
        try currencies.observe("USD", providerID: .hyperstack)
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()

        let historyURL = ProviderURL.https(
            host: Self.apiHost,
            path: "/v1/billing/billing/history",
            query: [
                URLQueryItem(name: "start_date", value: Self.day(window.start, calendar: calendar)),
                URLQueryItem(name: "end_date", value: Self.day(window.endInclusive, calendar: calendar)),
            ]
        )
        let historyData = try await ProviderHTTP.get(
            url: historyURL, headers: headers, client: httpClient, providerID: .hyperstack
        )
        let history = try ProviderHTTP.decode(HistoryEnvelope.self, from: historyData, providerID: .hyperstack)
        var currentTotal: Decimal = 0
        for entry in history.billing_history?.billing_history ?? [] {
            let amount = entry.metrics?.incurred_bill?.value
                ?? entry.metrics?.non_discounted_bill?.value
                ?? 0
            guard amount != 0 else { continue }
            let stamp = entry.attributes?.start_date
                .flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? entry.attributes?.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            if current.contains(stamp) || Self.sameMonth(stamp, current.start, calendar: calendar) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                let m = entry.metrics
                for (cat, raw) in [
                    ("vm", m?.vm_cost),
                    ("volume", m?.volume_cost),
                    ("contract", m?.contract_cost),
                    ("snapshot", m?.snapshot_cost),
                    ("bucket", m?.bucket_cost),
                    ("ais_token", m?.ais_token_cost),
                ] {
                    let part = raw?.value ?? 0
                    guard part != 0 else { continue }
                    lines.add(SpendLine(category: cat, label: cat, amountUSD: Money(usd: part)))
                }
            } else if horizon == .availableHistory {
                daily.addPastMonth(
                    start: stamp,
                    amount: Money(usd: amount),
                    current: current,
                    calendar: calendar
                )
            }
        }

        // Last-day cost as supplemental day bucket when history is empty for current month.
        if currentTotal == 0 {
            let lastURL = ProviderURL.https(host: Self.apiHost, path: "/v1/billing/billing/last-day-cost")
            if let data = try? await ProviderHTTP.get(
                url: lastURL, headers: headers, client: httpClient, providerID: .hyperstack
            ), let payload = try? ProviderHTTP.decode(LastDayEnvelope.self, from: data, providerID: .hyperstack) {
                let total = payload.data?.total_cost?.value
                    ?? payload.data?.instances_cost?.value
                    ?? 0
                if total != 0 {
                    let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? current.start
                    if current.contains(yesterday) {
                        currentTotal = total
                        daily.add(day: yesterday, amount: Money(usd: total))
                        if let instances = payload.data?.instances_cost?.value, instances != 0 {
                            lines.add(SpendLine(category: "instances", label: "instances", amountUSD: Money(usd: instances)))
                        }
                        if let volumes = payload.data?.volumes_cost?.value, volumes != 0 {
                            lines.add(SpendLine(category: "volumes", label: "volumes", amountUSD: Money(usd: volumes)))
                        }
                        if let clusters = payload.data?.clusters_cost?.value, clusters != 0 {
                            lines.add(SpendLine(category: "clusters", label: "clusters", amountUSD: Money(usd: clusters)))
                        }
                    }
                }
            }
        }

        return try Snapshot(
            providerID: .hyperstack,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily ?? [:],
            lines: lines.snapshot
        ).convertedToUSD(using: currencies, rates: rateSource.current)
    }

    static func day(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func sameMonth(_ a: Date, _ b: Date, calendar: Calendar) -> Bool {
        let ca = calendar.dateComponents([.year, .month], from: a)
        let cb = calendar.dateComponents([.year, .month], from: b)
        return ca.year == cb.year && ca.month == cb.month
    }

    struct HistoryEnvelope: Decodable, Sendable {
        var status: Bool?
        var message: String?
        var billing_history: OrgHistory?
    }

    struct OrgHistory: Decodable, Sendable {
        var org_id: FlexibleDecimal?
        var billing_history: [HistoryEntry]?
    }

    struct HistoryEntry: Decodable, Sendable {
        var attributes: HistoryAttributes?
        var metrics: HistoryMetrics?
    }

    struct HistoryAttributes: Decodable, Sendable {
        var id: String?
        var start_date: String?
        var end_date: String?
        var date: String?
    }

    struct HistoryMetrics: Decodable, Sendable {
        var incurred_bill: FlexibleDecimal?
        var non_discounted_bill: FlexibleDecimal?
        var vm_cost: FlexibleDecimal?
        var volume_cost: FlexibleDecimal?
        var contract_cost: FlexibleDecimal?
        var snapshot_cost: FlexibleDecimal?
        var bucket_cost: FlexibleDecimal?
        var ais_token_cost: FlexibleDecimal?
    }

    struct LastDayEnvelope: Decodable, Sendable {
        var status: Bool?
        var message: String?
        var data: LastDayData?
    }

    struct LastDayData: Decodable, Sendable {
        var instances_cost: FlexibleDecimal?
        var volumes_cost: FlexibleDecimal?
        var clusters_cost: FlexibleDecimal?
        var total_cost: FlexibleDecimal?
    }
}
