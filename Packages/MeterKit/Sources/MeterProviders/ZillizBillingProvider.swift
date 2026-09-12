import Foundation
import MeterCore

/// Zilliz Cloud 日用量花费。
///
/// 文档：`POST /v2/usage/query`（`https://api.cloud.zilliz.com`）
/// 认证：`Authorization: Bearer <API key>`（组织 owner / billing admin）。
///
/// 每段 `results[].total` + `currency`；明细 `items[].amount`。跳过余额类字段。
public struct ZillizBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.zilliz }

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
        let token = try RequiredCredential.value(.apiKey, in: credential, providerID: .zilliz)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json",
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
            let rows = try await loadAllPages(window: month, headers: headers)
            var monthSum: Decimal = 0
            for row in rows {
                try currencies.observe(row.currency, providerID: .zilliz)
                let amount = row.total?.value ?? 0
                monthSum += amount
                let day = (row.intervalStart ?? row.intervalEnd)
                    .flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? month.start
                if month.start == current.start {
                    daily.add(day: calendar.startOfDay(for: day), amount: Money(usd: amount))
                    for item in row.items ?? [] {
                        let itemAmount = item.amount?.value ?? 0
                        guard itemAmount != 0 else { continue }
                        let category = item.costType?.trimmed ?? "usage"
                        let label = item.properties?.clusterId?.trimmed
                            ?? item.properties?.projectId?.trimmed
                            ?? category
                        lines.add(
                            SpendLine(
                                category: category,
                                label: label,
                                scope: item.properties?.regionId?.trimmed,
                                amountUSD: Money(usd: itemAmount),
                                quantity: item.quantity?.value,
                                unit: item.unit?.trimmed
                            )
                        )
                    }
                }
            }
            if month.start == current.start {
                currentTotal = monthSum
            } else {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: monthSum),
                    current: current,
                    calendar: calendar
                )
            }
        }

        let converted = try currencies.convert(currentTotal, rates: rateSource.current, providerID: .zilliz)
        return Snapshot(
            providerID: .zilliz,
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

    private func loadAllPages(
        window: CalendarMonthWindow,
        headers: [String: String]
    ) async throws -> [UsageDay] {
        var page = 1
        var collected: [UsageDay] = []
        while true {
            let body = try JSONSerialization.data(
                withJSONObject: [
                    "start": window.rfc3339(window.start),
                    "end": window.rfc3339(window.nextStart),
                    "currentPage": page,
                    "pageSize": 100,
                ]
            )
            let data = try await ProviderHTTP.post(
                url: Self.queryURL,
                headers: headers,
                body: body,
                client: httpClient,
                providerID: .zilliz
            )
            let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .zilliz)
            if let code = payload.code, code != 0 {
                throw ProviderError.malformedResponse(providerID: .zilliz)
            }
            let rows = payload.data?.results ?? []
            collected.append(contentsOf: rows)
            let pageSize = payload.data?.pageSize ?? 100
            let total = payload.data?.total ?? rows.count
            if collected.count >= total || rows.count < pageSize {
                break
            }
            page += 1
            if page > 50 { break }
        }
        return collected
    }

    static let queryURL = URL(string: "https://api.cloud.zilliz.com/v2/usage/query")!

    struct Envelope: Decodable, Sendable {
        var code: Int?
        var data: Payload?
    }

    struct Payload: Decodable, Sendable {
        var results: [UsageDay]?
        var currentPage: Int?
        var pageSize: Int?
        var total: Int?
    }

    struct UsageDay: Decodable, Sendable {
        var intervalStart: String?
        var intervalEnd: String?
        var total: FlexibleDecimal?
        var currency: String?
        var items: [UsageItem]?
    }

    struct UsageItem: Decodable, Sendable {
        var costType: String?
        var properties: Properties?
        var quantity: FlexibleDecimal?
        var unit: String?
        var amount: FlexibleDecimal?
    }

    struct Properties: Decodable, Sendable {
        var projectId: String?
        var regionId: String?
        var clusterId: String?
        var plan: String?
        var cuType: String?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
