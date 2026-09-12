import Foundation
import MeterCore

/// PlanetScale 组织发票。
///
/// 文档：`GET /v1/organizations/{org}/invoices`
/// 认证：`Authorization: <TOKEN_ID> <TOKEN>`，权限 `read_invoices`。
public struct PlanetScaleBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.planetscale }

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
        let tokenID = try RequiredCredential.value(.accessKeyID, in: credential, providerID: .planetscale)
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .planetscale)
        let org = try RequiredCredential.value(.accountID, in: credential, providerID: .planetscale)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL(organization: org),
            headers: [
                "Authorization": "\(tokenID) \(token)",
            ],
            client: httpClient,
            providerID: .planetscale
        )
        let page = try ProviderHTTP.decode(Page.self, from: data, providerID: .planetscale)
        var daily = DailySpendAccumulator()
        if horizon == .availableHistory {
            for invoice in page.data ?? [] {
                let amount = invoice.total?.value ?? 0
                guard amount != 0 else { continue }
                let start = invoice.billing_period_start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                guard let start else { continue }
                daily.addPastMonth(
                    start: start,
                    amount: Money(usd: amount),
                    current: window,
                    calendar: calendar
                )
            }
        }
        // 本账期还没有发票 ≠ 花了 $0：读数字段整个省略，走「未读快照」合同
        // （同 Heroku / Typesense / IONOS）。
        guard let current = (page.data ?? []).first(where: { invoice in
            covers(invoice, now: now, calendar: calendar)
        }) else {
            return Snapshot(
                providerID: .planetscale,
                kind: .usage,
                fetchedAt: now,
                periodStart: window.start,
                periodEnd: window.endInclusive,
                dailyUSD: daily.snapshotDaily
            )
        }
        return Snapshot(
            providerID: .planetscale,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: Money(usd: current.total?.value ?? 0),
            dailyUSD: daily.snapshotDaily
        )
    }

    static func invoicesURL(organization: String) -> URL {
        return ProviderURL.https(host: "api.planetscale.com", path: "/v1/organizations/\(organization)/invoices")
    }

    private func covers(_ invoice: Invoice, now: Date, calendar: Calendar) -> Bool {
        let start = invoice.billing_period_start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
        let end = invoice.billing_period_end.flatMap { BillingDateParser.parse($0, calendar: calendar) }
        guard let start, let end else { return false }
        let day = calendar.startOfDay(for: now)
        return day >= start && day <= end
    }

    struct Page: Decodable, Sendable {
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var total: FlexibleDecimal?
        var billing_period_start: String?
        var billing_period_end: String?
    }
}
