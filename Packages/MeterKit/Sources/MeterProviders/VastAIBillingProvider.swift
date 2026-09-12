import Foundation
import MeterCore

/// Vast.ai 本月按量花费（跳过预充值 credit）。
///
/// 文档：`GET /api/v0/charges?select_filters={"day":{"gte":…,"lte":…}}`
/// 认证：`Authorization: Bearer <API key>`。
///
/// `results[].amount` 为美元；按合同 `start` 划入账期日。
public struct VastAIBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.vastai }

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .vastai)
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
            let rows = try await loadCharges(window: month, headers: headers)
            var monthTotal: Decimal = 0
            for row in rows {
                let amount = row.amount?.value ?? 0
                guard amount != 0 else { continue }
                monthTotal += amount
                if month.start == current.start {
                    let day: Date
                    if let start = row.start?.value {
                        let seconds = NSDecimalNumber(decimal: start).doubleValue
                        day = calendar.startOfDay(for: Date(timeIntervalSince1970: seconds))
                    } else {
                        day = month.start
                    }
                    if current.contains(day) {
                        daily.add(day: day, amount: Money(usd: amount))
                    }
                    let label = row.description?.trimmed
                        ?? row.source?.trimmed
                        ?? row.type?.trimmed
                        ?? "charge"
                    lines.add(
                        SpendLine(
                            category: row.type?.trimmed ?? "charge",
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

        return Snapshot(
            providerID: .vastai,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily,
            lines: lines.snapshot
        )
    }

    private func loadCharges(
        window: CalendarMonthWindow,
        headers: [String: String]
    ) async throws -> [Charge] {
        var out: [Charge] = []
        var after: String? = nil
        let gte = Int(window.start.timeIntervalSince1970)
        let lte = Int(window.nextStart.timeIntervalSince1970) - 1
        let filters = #"{"day":{"gte":\#(gte),"lte":\#(lte)}}"#
        for _ in 0..<20 {
            var query = [
                URLQueryItem(name: "select_filters", value: filters),
                URLQueryItem(name: "format", value: "table"),
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "latest_first", value: "true"),
            ]
            if let after {
                query.append(URLQueryItem(name: "after_token", value: after))
            }
            let url = ProviderURL.https(
                host: "console.vast.ai",
                path: "/api/v0/charges",
                query: query
            )
            let data = try await ProviderHTTP.get(
                url: url,
                headers: headers,
                client: httpClient,
                providerID: .vastai
            )
            let payload = try ProviderHTTP.decode(Charges.self, from: data, providerID: .vastai)
            out.append(contentsOf: payload.results ?? [])
            guard let next = payload.next_token?.trimmed else { break }
            after = next
        }
        return out
    }

    struct Charges: Decodable, Sendable {
        var results: [Charge]?
        var next_token: String?
    }

    struct Charge: Decodable, Sendable {
        var start: FlexibleDecimal?
        var end: FlexibleDecimal?
        var type: String?
        var source: String?
        var description: String?
        var amount: FlexibleDecimal?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
