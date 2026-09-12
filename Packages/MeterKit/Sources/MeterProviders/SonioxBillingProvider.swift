import Foundation
import MeterCore

/// Soniox 本月用量花费（按 UTC 日）。
///
/// 文档：`GET /v1/usage/summary?start_time&end_time`
/// 认证：`Authorization: Bearer <API key>`（项目由 key 隐含）。
///
/// 金额：`total.total_cost_usd` 与逐日 `total.cost_usd[]`（字符串小数）。
public struct SonioxBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.soniox }

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .soniox)
        let headers = [
            "Authorization": "Bearer \(key)",
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
                url: Self.summaryURL(window: month),
                headers: headers,
                client: httpClient,
                providerID: .soniox
            )
            let payload = try ProviderHTTP.decode(Summary.self, from: data, providerID: .soniox)
            let total = payload.total
            let amount = total?.totalCostUSD?.value ?? 0
            if month.start == current.start {
                currentTotal = amount
                let days = total?.days ?? []
                let costs = total?.costUSD ?? []
                for (index, dayString) in days.enumerated() {
                    let cost = index < costs.count ? (costs[index].value ?? 0) : 0
                    guard cost != 0 else { continue }
                    let day = BillingDateParser.parse(dayString, calendar: calendar) ?? month.start
                    daily.add(day: calendar.startOfDay(for: day), amount: Money(usd: cost))
                }
                for model in payload.models ?? [] {
                    let modelAmount = model.totalCostUSD?.value ?? 0
                    guard modelAmount != 0 else { continue }
                    let label = model.model?.trimmed ?? "model"
                    lines.add(
                        SpendLine(
                            category: "model",
                            label: label,
                            amountUSD: Money(usd: modelAmount)
                        )
                    )
                }
            } else {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: amount),
                    current: current,
                    calendar: calendar
                )
            }
        }

        return Snapshot(
            providerID: .soniox,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily,
            lines: lines.snapshot
        )
    }

    static func summaryURL(window: CalendarMonthWindow) -> URL {
        ProviderURL.https(
            host: "api.soniox.com",
            path: "/v1/usage/summary",
            query: [
                URLQueryItem(name: "start_time", value: window.rfc3339(window.start)),
                URLQueryItem(name: "end_time", value: window.rfc3339(window.nextStart)),
            ]
        )
    }

    struct Summary: Decodable, Sendable {
        var total: Series?
        var models: [Series]?
    }

    struct Series: Decodable, Sendable {
        var model: String?
        var days: [String]?
        var totalCostUSD: FlexibleDecimal?
        var costUSD: [FlexibleDecimal]?

        enum CodingKeys: String, CodingKey {
            case model
            case days
            case totalCostUSD = "total_cost_usd"
            case costUSD = "cost_usd"
        }
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
