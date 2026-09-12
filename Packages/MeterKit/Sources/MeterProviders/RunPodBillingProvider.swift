import Foundation
import MeterCore

/// RunPod 本周期 pod 账单合计（美元）。
///
/// 文档：`GET /v2/billing/pods`（`totalAmount` 为区间 USD）。
/// 认证：`Authorization: Bearer <API key>`。
///
/// 优先于 GraphQL `clientBalance` 预充值余额——这里记的是已结算周期花费。
public struct RunPodBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.runpod }

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .runpod)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let headers = [
            "Authorization": "Bearer \(key)",
        ]
        var daily = DailySpendAccumulator()
        var currentTotal: Decimal = 0
        for month in months {
            let data: Data
            do {
                data = try await ProviderHTTP.get(
                    url: Self.podsBillingURL(window: month),
                    headers: headers,
                    client: httpClient,
                    providerID: .runpod
                )
            } catch let error as ProviderError where error.code == .billingAPIUnavailable {
                if month.start == current.start { throw error }
                continue
            }
            let payload = try ProviderHTTP.decode(PodsBilling.self, from: data, providerID: .runpod)
            let total = payload.totalAmount?.value
                ?? (payload.pods ?? []).reduce(Decimal(0)) { $0 + ($1.totalAmount?.value ?? 0) }
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
            providerID: .runpod,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily
        )
    }

    static func podsBillingURL(window: CalendarMonthWindow) -> URL {
        ProviderURL.https(
            host: "api.runpod.io",
            path: "/v2/billing/pods",
            query: [
                URLQueryItem(name: "startTime", value: window.rfc3339(window.start)),
                URLQueryItem(name: "endTime", value: window.rfc3339(window.nextStart)),
            ]
        )
    }

    struct PodsBilling: Decodable, Sendable {
        var totalAmount: FlexibleDecimal?
        var pods: [PodCharge]?
    }

    struct PodCharge: Decodable, Sendable {
        var totalAmount: FlexibleDecimal?
    }
}
