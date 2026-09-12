import Foundation
import MeterCore

/// inference.sh 本月用量花费（`GET /usage/breakdown?range=30d`）。
///
/// 文档：https://inference.sh/docs/api/rest/usage
/// 认证：`Authorization: Bearer` + `X-API-Version: 2`。Host：`api.inference.sh`。
/// 金额：`total_cost` / timeseries `per_app` 为 microcents（1 USD = 1e8）；币种文档写明 USD。
public struct InferenceSHBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.inferencesh }
    public static let apiHost = "api.inference.sh"
    static let microcentsPerUSD = Decimal(100_000_000)

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
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .inferencesh) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiToken, in: credential, providerID: .inferencesh)
        }
        let headers = [
            "Authorization": "Bearer \(token)",
            "X-API-Version": "2",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        _ = horizon
        let data = try await ProviderHTTP.get(
            url: Self.breakdownURL,
            headers: headers,
            client: httpClient,
            providerID: .inferencesh
        )
        let payload = try ProviderHTTP.decode(Breakdown.self, from: data, providerID: .inferencesh)
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        for bucket in payload.timeseries ?? [] {
            let stamp = bucket.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let micros = (bucket.per_app ?? [:]).values.reduce(Decimal(0)) { partial, value in
                partial + (value.value ?? 0)
            }
            guard micros > 0 else { continue }
            let amount = micros / Self.microcentsPerUSD
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
            }
        }

        if currentTotal == 0, let micros = payload.total_cost?.value, micros > 0 {
            // 无日桶时用区间合计；`range=30d` 可能跨月，只在缺日粒度时回落。
            currentTotal = micros / Self.microcentsPerUSD
        }

        for item in payload.per_model ?? [] {
            let micros = item.cost?.value ?? 0
            guard micros > 0 else { continue }
            let amount = micros / Self.microcentsPerUSD
            lines.add(
                SpendLine(
                    category: "app",
                    label: item.app_endpoint ?? "app",
                    amountUSD: Money(usd: amount)
                )
            )
        }

        return Snapshot(
            providerID: .inferencesh,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily,
            lines: lines.snapshot
        )
    }

    static let breakdownURL = URL(string: "https://api.inference.sh/usage/breakdown?range=30d")!

    struct Breakdown: Decodable, Sendable {
        var timeseries: [Bucket]?
        var per_model: [PerModel]?
        var total_cost: FlexibleDecimal?
        var period_start: String?
        var period_end: String?
    }

    struct Bucket: Decodable, Sendable {
        var date: String?
        var per_app: [String: FlexibleDecimal]?
    }

    struct PerModel: Decodable, Sendable {
        var app_endpoint: String?
        var call_count: Int?
        var cost: FlexibleDecimal?
    }
}
