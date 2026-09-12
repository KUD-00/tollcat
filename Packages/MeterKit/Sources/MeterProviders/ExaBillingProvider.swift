import Foundation
import MeterCore

/// Exa 单把 key 的当月花费。
///
/// 文档：`GET https://admin-api.exa.ai/team-management/api-keys/{id}/usage`
/// 认证：`x-api-key: <service key>`。注意是 service key，不是搜索用的那把。
///
/// `total_cost_usd` 已经是美元，不按检索单价重算。`cost_breakdown` 是按计费项
/// 拆的（Neural Search / Content Retrieval），不是按天，所以拿不到日粒度。
/// 统计口径是**这一把 key**：团队里还有别的 key 就漏了，向导里要写清楚。
public struct ExaBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.exa }

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
        let serviceKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .exa)
        let keyID = try RequiredCredential.value(.keyID, in: credential, providerID: .exa)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )

        var daily = DailySpendAccumulator()
        var currentTotal: Decimal = 0
        for month in months {
            let data: Data
            do {
                data = try await ProviderHTTP.get(
                    url: Self.usageURL(keyID: keyID, window: month),
                    headers: [
                        "x-api-key": serviceKey,
                    ],
                    client: httpClient,
                    providerID: .exa
                )
            } catch let error as ProviderError where error.code == .billingAPIUnavailable {
                if month.start == current.start { throw error }
                continue
            }
            let payload = try ProviderHTTP.decode(Usage.self, from: data, providerID: .exa)
            let total = Self.total(payload)
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

        return Snapshot(
            providerID: .exa,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily
        )
    }

    /// 顶层 `total_cost_usd` 缺失时用分项加总，别把一次成功的取数当成 $0。
    static func total(_ usage: Usage) -> Decimal {
        if let total = usage.total_cost_usd?.value {
            return total
        }
        return (usage.cost_breakdown ?? []).reduce(Decimal(0)) { sum, item in
            sum + (item.amount_usd?.value ?? 0)
        }
    }

    static func usageURL(keyID: String, window: CalendarMonthWindow) -> URL {
        return ProviderURL.https(
            host: "admin-api.exa.ai",
            path: "/team-management/api-keys/\(keyID)/usage",
            query: [
                URLQueryItem(name: "start_date", value: window.rfc3339(window.start)),
                URLQueryItem(name: "end_date", value: window.rfc3339(window.nextStart)),
            ]
        )
    }

    struct Usage: Decodable, Sendable {
        var api_key_id: String?
        var team_id: String?
        var total_cost_usd: FlexibleDecimal?
        var cost_breakdown: [BreakdownItem]?
    }

    struct BreakdownItem: Decodable, Sendable {
        var price_id: String?
        var price_name: String?
        var amount_usd: FlexibleDecimal?
    }
}
