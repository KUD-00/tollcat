import Foundation
import MeterCore

/// Mistral Admin API 当月用量金额。
///
/// 文档：`GET /v1/admin/usage?month=&year=`
/// 认证：`x-api-key: <Admin API key>`，在 Backoffice 签发，普通推理 key 不够。
///
/// Admin API 是 Enterprise 专属、还在 Preview，响应里各品类的金额字段名
/// 也不完全钉死。按品类 `cost` / `total_cost` 相加；有顶层合计就用顶层。
public struct MistralBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.mistral }

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .mistral)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        var currency = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var currentTotal: Decimal = 0
        for month in months {
            let parts = calendar.dateComponents([.year, .month], from: month.start)
            let data = try await ProviderHTTP.get(
                url: Self.usageURL(year: parts.year ?? 0, month: parts.month ?? 0),
                headers: [
                    "x-api-key": key,
                ],
                client: httpClient,
                providerID: .mistral
            )
            let usage = try ProviderHTTP.decode(Usage.self, from: data, providerID: .mistral)
            try currency.observe(usage.currency, providerID: .mistral)
            if month.start == current.start {
                currentTotal = usage.total
            } else {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: usage.total),
                    current: current,
                    calendar: calendar
                )
            }
        }
        return try Snapshot(
            providerID: .mistral,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    static func usageURL(year: Int, month: Int) -> URL {
        ProviderURL.https(
            host: "api.mistral.ai",
            path: "/v1/admin/usage",
            query: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "month", value: String(month)),
            ]
        )
    }

    struct Usage: Decodable, Sendable {
        var currency: String?
        var total: Decimal

        private static let metadata: Set<String> = [
            "currency", "currency_symbol", "date", "start_date", "end_date",
            "prices", "next_month", "previous_month",
        ]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicKey.self)
            currency = try container.decodeIfPresent(String.self, forKey: DynamicKey("currency"))
            var explicit: Decimal?
            var summed: Decimal = 0
            for key in container.allKeys {
                let name = key.stringValue
                if Self.metadata.contains(name) { continue }
                if name == "total_cost" || name == "cost" {
                    if let value = try container.decodeIfPresent(FlexibleDecimal.self, forKey: key) {
                        explicit = value.value
                    }
                    continue
                }
                if let category = try? container.decode(Category.self, forKey: key) {
                    summed += category.spend
                }
            }
            total = explicit ?? summed
        }
    }

    struct Category: Decodable, Sendable {
        var cost: FlexibleDecimal?
        var total_cost: FlexibleDecimal?
        var amount: FlexibleDecimal?
        var models: [Category]?

        var spend: Decimal {
            if let value = cost?.value ?? total_cost?.value ?? amount?.value {
                return value
            }
            return (models ?? []).reduce(0) { $0 + $1.spend }
        }
    }

    private struct DynamicKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }

        init(_ stringValue: String) {
            self.stringValue = stringValue
        }

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }
}
