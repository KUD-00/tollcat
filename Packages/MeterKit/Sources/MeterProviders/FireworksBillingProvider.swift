import Foundation
import MeterCore

/// Fireworks 本月已计价花费。
///
/// 文档：`GET /v1/accounts/{account_id}/billing/summary`
/// 认证：`Authorization: Bearer <API key>`
///
/// `billingUsage` 只给 token / 加速器秒，没有美元。金额走 `billing/summary`：
/// `lineItems` 是区间合计，`granularity=DAILY` 时 `usageBuckets` 按天拆。
/// 金额是 Google Money（`units` + `nanos`）。
public struct FireworksBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.fireworks }
    static let nanosPerUnit = Decimal(1_000_000_000)

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .fireworks)
        let accountID = try RequiredCredential.value(.accountID, in: credential, providerID: .fireworks)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let fetchWindow = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let data = try await ProviderHTTP.get(
            url: Self.summaryURL(accountID: accountID, window: fetchWindow),
            headers: [
                "Authorization": "Bearer \(key)",
            ],
            client: httpClient,
            providerID: .fireworks
        )
        let summary = try ProviderHTTP.decode(Summary.self, from: data, providerID: .fireworks)
        var currency = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        for bucket in summary.usageBuckets ?? [] {
            let day = bucket.startTime.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let amount = Self.bucketTotal(bucket)
            guard amount != 0 else { continue }
            try currency.observe(Self.bucketCurrency(bucket), providerID: .fireworks)
            daily.add(day: day, amount: Money(usd: amount))
        }
        for item in summary.lineItems ?? [] {
            try currency.observe(item.totalCost?.currencyCode, providerID: .fireworks)
        }
        // lineItems 是请求区间合计。历史窗口下那是十二个月的钱，不能当本月。
        let total: Decimal
        if horizon == .currentMonth {
            total = Self.lineItemTotal(summary.lineItems) ?? daily.total(in: current, calendar: calendar).usd
        } else {
            total = daily.total(in: current, calendar: calendar).usd
        }
        return try Snapshot(
            providerID: .fireworks,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: total),
            dailyUSD: daily.snapshotDaily
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    static func summaryURL(accountID: String, window: CalendarMonthWindow) -> URL {
        ProviderURL.https(
            host: "api.fireworks.ai",
            path: "/v1/accounts/\(accountID)/billing/summary",
            query: [
                URLQueryItem(name: "startTime", value: window.rfc3339(window.start)),
                URLQueryItem(name: "endTime", value: window.rfc3339(window.nextStart)),
                URLQueryItem(name: "granularity", value: "DAILY"),
            ]
        )
    }

    static func lineItemTotal(_ items: [LineItem]?) -> Decimal? {
        guard let items, !items.isEmpty else { return nil }
        return items.reduce(0) { $0 + ($1.totalCost?.decimal ?? 0) }
    }

    static func bucketTotal(_ bucket: UsageBucket) -> Decimal {
        (bucket.lineItems ?? []).reduce(0) { $0 + ($1.totalCost?.decimal ?? 0) }
    }

    static func bucketCurrency(_ bucket: UsageBucket) -> String? {
        bucket.lineItems?.first { $0.totalCost?.currencyCode != nil }?.totalCost?.currencyCode
    }

    struct Summary: Decodable, Sendable {
        var lineItems: [LineItem]?
        var usageBuckets: [UsageBucket]?
    }

    struct UsageBucket: Decodable, Sendable {
        var startTime: String?
        var endTime: String?
        var lineItems: [LineItem]?
    }

    struct LineItem: Decodable, Sendable {
        var category: String?
        var totalCost: GoogleMoney?
    }

    /// protobuf Money：`units` 是整单位，`nanos` 是十亿分之一。
    struct GoogleMoney: Decodable, Sendable {
        var currencyCode: String?
        var units: FlexibleDecimal?
        var nanos: Int?

        var decimal: Decimal {
            (units?.value ?? 0) + Decimal(nanos ?? 0) / nanosPerUnit
        }
    }
}
