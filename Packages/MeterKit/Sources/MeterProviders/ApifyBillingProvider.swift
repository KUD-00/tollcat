import Foundation
import MeterCore

/// Apify 本月平台用量美元（`GET /v2/users/me/usage/monthly` 的 `*Usd` 字段）。
///
/// 文档：https://docs.apify.com/api/v2#/reference/users/monthly-usage
/// 认证：`Authorization: Bearer <API token>`（勿放 query）。
/// 优先 `totalUsageCreditsUsdAfterVolumeDiscount` / 日线 `totalUsageCreditsUsd`；
/// 预充值钱包余额不作为本期花费（overage 计入下一张发票的用量美元）。
public struct ApifyBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.apify }
    public static let apiHost = "api.apify.com"

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar
    public var rateSource: SharedExchangeRates

    public init(
        httpClient: any HTTPClient,
        now: @escaping @Sendable () -> Date,
        calendar: Calendar,
        rateSource: SharedExchangeRates = SharedExchangeRates()
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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .apify)
        let headers = ["Authorization": "Bearer \(token)", "Accept": "application/json"]
        let fallback = CalendarMonthWindow.current(now: now, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: ProviderURL.https(host: Self.apiHost, path: "/v2/users/me/usage/monthly"),
            headers: headers,
            client: httpClient,
            providerID: .apify
        )
        let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .apify)
        guard let usage = envelope.data else {
            throw ProviderError.malformedResponse(providerID: .apify)
        }
        let period = BillingPeriodResolver.resolve(
            startRaw: usage.usageCycle?.startAt,
            endRaw: usage.usageCycle?.endAt,
            endConvention: .inclusive,
            fallback: fallback,
            calendar: calendar
        )
        var currencies = CurrencyAccumulator()
        try currencies.observe("USD", providerID: .apify)
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()

        for row in usage.dailyServiceUsages ?? [] {
            let amount = row.totalUsageCreditsUsd?.value
                ?? row.usageCreditsUsdAfterVolumeDiscount?.value
                ?? 0
            guard amount != 0 else { continue }
            let day = row.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? period.start
            daily.add(day: day, amount: Money(usd: amount))
        }

        // Service-level *Usd breakdown when present
        for svc in usage.serviceUsages ?? usage.monthlyServiceUsages ?? [] {
            let amount = svc.totalUsageCreditsUsd?.value
                ?? svc.usageCreditsUsdAfterVolumeDiscount?.value
                ?? svc.usageCreditsUsd?.value
                ?? 0
            guard amount != 0 else { continue }
            lines.add(
                SpendLine(
                    category: svc.service ?? svc.serviceName ?? "usage",
                    label: svc.service ?? svc.serviceName ?? "service",
                    amountUSD: Money(usd: amount)
                )
            )
        }

        let total = usage.totalUsageCreditsUsdAfterVolumeDiscount?.value
            ?? usage.totalUsageCreditsUsdBeforeVolumeDiscount?.value
            ?? usage.totalUsageCreditsUsd?.value
            ?? daily.total.usd

        if daily.snapshotDaily == nil, total != 0 {
            daily.add(day: period.start, amount: Money(usd: total))
        }

        // availableHistory: monthly endpoint is current cycle; past months not exposed here.
        _ = horizon

        return try Snapshot(
            providerID: .apify,
            kind: .usage,
            fetchedAt: now,
            periodStart: period.start,
            periodEnd: period.end,
            currentSpendUSD: Money(usd: total),
            dailyUSD: daily.snapshotDaily,
            lines: lines.snapshot
        ).convertedToUSD(using: currencies, rates: rateSource.current)
    }

    struct Envelope: Decodable, Sendable {
        var data: MonthlyUsage?
    }

    struct MonthlyUsage: Decodable, Sendable {
        var usageCycle: Cycle?
        var dailyServiceUsages: [DailyUsage]?
        var serviceUsages: [ServiceUsage]?
        var monthlyServiceUsages: [ServiceUsage]?
        var totalUsageCreditsUsdAfterVolumeDiscount: FlexibleDecimal?
        var totalUsageCreditsUsdBeforeVolumeDiscount: FlexibleDecimal?
        var totalUsageCreditsUsd: FlexibleDecimal?
    }

    struct Cycle: Decodable, Sendable {
        var startAt: String?
        var endAt: String?
    }

    struct DailyUsage: Decodable, Sendable {
        var date: String?
        var totalUsageCreditsUsd: FlexibleDecimal?
        var usageCreditsUsdAfterVolumeDiscount: FlexibleDecimal?
    }

    struct ServiceUsage: Decodable, Sendable {
        var service: String?
        var serviceName: String?
        var totalUsageCreditsUsd: FlexibleDecimal?
        var usageCreditsUsdAfterVolumeDiscount: FlexibleDecimal?
        var usageCreditsUsd: FlexibleDecimal?
    }
}
