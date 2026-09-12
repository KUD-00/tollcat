import Foundation
import MeterCore

/// Elastic Cloud 发票金额（美元）。
///
/// 文档：`GET /api/v1/billing/organization/{organization_id}/history`
/// 认证：`Authorization: ApiKey <key>`。
///
/// `invoices[].invoiced_amount_in_cents` 是真实美元分。**跳过** `/costs/*`（只有 ECU）。
public struct ElasticBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.elastic }

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .elastic)
        let organizationID = try RequiredCredential.value(.accountID, in: credential, providerID: .elastic)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let lookback = CalendarMonthWindow.spanning(
            for: horizon == .availableHistory ? .availableHistory : .currentMonth,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let data = try await ProviderHTTP.get(
            url: Self.historyURL(organizationID: organizationID),
            headers: [
                "Authorization": "ApiKey \(key)",
            ],
            client: httpClient,
            providerID: .elastic
        )
        let payload = try ProviderHTTP.decode(BillingHistory.self, from: data, providerID: .elastic)
        let invoices = payload.invoices ?? []
        var daily = DailySpendAccumulator()
        var currentTotal: Decimal = 0
        for invoice in invoices {
            guard let cents = invoice.invoiced_amount_in_cents else { continue }
            let amount = Decimal(cents) / 100
            let startRaw = invoice.period_start_date
            let start = startRaw.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let overlapsCurrent =
                start >= current.start && start < current.nextStart
            if overlapsCurrent {
                currentTotal += amount
            } else if horizon == .availableHistory, start >= lookback.start, start < current.start {
                daily.addPastMonth(
                    start: start,
                    amount: Money(usd: amount),
                    current: current,
                    calendar: calendar
                )
            }
        }
        return Snapshot(
            providerID: .elastic,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily
        )
    }

    static func historyURL(organizationID: String) -> URL {
        ProviderURL.https(
            host: "cloud.elastic.co",
            path: "/api/v1/billing/organization/\(organizationID)/history"
        )
    }

    struct BillingHistory: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var invoiced_amount_in_cents: Int64?
        var period_start_date: String?
        var period_end_date: String?
        var status: String?
        var type: String?
    }
}
