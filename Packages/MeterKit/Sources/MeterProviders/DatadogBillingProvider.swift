import Foundation
import MeterCore

/// Datadog 本月估算出账。
///
/// 文档：`GET /api/v2/usage/estimated_cost`
/// 认证：`DD-API-KEY` + `DD-APPLICATION-KEY`。Pro / Enterprise、父组织、最多延迟 72 小时。
///
/// `view=summary` 的 `data[].attributes.total_cost` 是美元。
/// `accountID` 是站点短名（`us1` / `eu` / `us3` / `us5` / `ap1` / `ap2` / `uk1`），默认 US1。
public struct DatadogBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.datadog }

    /// 短名 → 已声明的 API host。不接受任意域名，免得把 key 打到别处。
    static let sites: [String: String] = [
        "": "api.datadoghq.com",
        "us1": "api.datadoghq.com",
        "us": "api.datadoghq.com",
        "eu": "api.datadoghq.eu",
        "us3": "api.us3.datadoghq.com",
        "us5": "api.us5.datadoghq.com",
        "ap1": "api.ap1.datadoghq.com",
        "ap2": "api.ap2.datadoghq.com",
        "uk1": "api.uk1.datadoghq.com",
    ]

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .datadog)
        let appKey = try RequiredCredential.value(.apiToken, in: credential, providerID: .datadog)
        let site = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let host = try Self.apiHost(site: site)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let headers = [
            "DD-API-KEY": apiKey,
            "DD-APPLICATION-KEY": appKey,
            "Accept": "application/json",
        ]
        let data = try await ProviderHTTP.get(
            url: Self.estimatedCostURL(host: host, window: window, calendar: calendar),
            headers: headers,
            client: httpClient,
            providerID: .datadog
        )
        let payload = try ProviderHTTP.decode(CostByOrgResponse.self, from: data, providerID: .datadog)
        let rows = payload.data ?? []
        let amounts = rows.compactMap { $0.attributes?.total_cost?.value }
        if !rows.isEmpty, amounts.isEmpty {
            throw ProviderError.malformedResponse(providerID: .datadog)
        }
        let total = amounts.reduce(Decimal(0), +)
        var daily = DailySpendAccumulator()
        if horizon == .availableHistory {
            let past = CalendarMonthWindow.spanning(
                for: .availableHistory,
                lookbackMonths: Self.descriptor.historyLookbackMonths,
                now: now,
                calendar: calendar
            )
            do {
                let historyData = try await ProviderHTTP.get(
                    url: Self.historicalCostURL(host: host, from: past, to: window, calendar: calendar),
                    headers: headers,
                    client: httpClient,
                    providerID: .datadog
                )
                let history = try ProviderHTTP.decode(CostByOrgResponse.self, from: historyData, providerID: .datadog)
                for row in history.data ?? [] {
                    let amount = row.attributes?.total_cost?.value ?? 0
                    let start = row.attributes?.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                        ?? window.start
                    daily.addPastMonth(
                        start: start,
                        amount: Money(usd: amount),
                        current: window,
                        calendar: calendar
                    )
                }
            } catch let error as ProviderError
                where error.code == .forbidden || error.code == .billingAPIUnavailable {
                // historical_cost 只要父组织。单组织账号仍能看本月估算。
            }
        }
        return Snapshot(
            providerID: .datadog,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: Money(usd: total),
            dailyUSD: daily.snapshotDaily
        )
    }

    static func apiHost(site: String) throws -> String {
        let trimmed = site.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let mapped = sites[trimmed] {
            return mapped
        }
        if Set(sites.values).contains(trimmed) {
            return trimmed
        }
        throw ProviderError.malformedResponse(providerID: .datadog)
    }

    static func estimatedCostURL(
        host: String,
        window: CalendarMonthWindow,
        calendar: Calendar
    ) -> URL {
        ProviderURL.https(
            host: host,
            path: "/api/v2/usage/estimated_cost",
            query: [
                URLQueryItem(name: "view", value: "summary"),
                URLQueryItem(name: "start_month", value: window.dayString(window.start, calendar: calendar)),
            ]
        )
    }

    static func historicalCostURL(
        host: String,
        from: CalendarMonthWindow,
        to: CalendarMonthWindow,
        calendar: Calendar
    ) -> URL {
        ProviderURL.https(
            host: host,
            path: "/api/v2/usage/historical_cost",
            query: [
                URLQueryItem(name: "view", value: "summary"),
                URLQueryItem(name: "start_month", value: from.dayString(from.start, calendar: calendar)),
                URLQueryItem(name: "end_month", value: to.dayString(to.start, calendar: calendar)),
            ]
        )
    }

    struct CostByOrgResponse: Decodable, Sendable {
        var data: [CostByOrg]?
    }

    struct CostByOrg: Decodable, Sendable {
        var attributes: Attributes?
    }

    struct Attributes: Decodable, Sendable {
        var total_cost: FlexibleDecimal?
        var org_name: String?
        var date: String?
    }
}
