import Foundation
import MeterCore

/// Typesense Cloud 本月已出账发票合计。
///
/// 文档：`GET /api/v1/invoices`
/// 认证：`X-TYPESENSE-CLOUD-MANAGEMENT-API-KEY`。
///
/// `amount_cents` 是美元美分。Typesense 按周出账，当周那张不一定已经在列表里。
public struct TypesenseBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.typesense }
    static let centsPerUSD = Decimal(100)

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .typesense)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL,
            headers: [
                "X-TYPESENSE-CLOUD-MANAGEMENT-API-KEY": key,
                "Accept": "application/json",
            ],
            client: httpClient,
            providerID: .typesense
        )
        let payload = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .typesense)
        let all = payload.invoices ?? []
        var daily = DailySpendAccumulator()
        if horizon == .availableHistory {
            for invoice in all {
                let startUnix = invoice.period_starts_at
                let start = startUnix.map { BillingDateParser.parseUnixSeconds($0, calendar: calendar) }
                let cents = invoice.amount_cents?.value ?? 0
                guard let start, cents != 0 else { continue }
                daily.addPastMonth(
                    start: start,
                    amount: Money(usd: cents / Self.centsPerUSD),
                    current: window,
                    calendar: calendar
                )
            }
        }
        let invoices = all.filter {
            Self.overlapsCurrentMonth($0, window: window, calendar: calendar)
        }
        guard !invoices.isEmpty else {
            return Snapshot(
                providerID: .typesense,
                kind: .usage,
                fetchedAt: now,
                periodStart: window.start,
                periodEnd: window.endInclusive,
                dailyUSD: daily.snapshotDaily
            )
        }
        let cents = invoices.reduce(Decimal(0)) { partial, invoice in
            partial + (invoice.amount_cents?.value ?? 0)
        }
        return Snapshot(
            providerID: .typesense,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: Money(usd: cents / Self.centsPerUSD),
            dailyUSD: daily.snapshotDaily
        )
    }

    static func overlapsCurrentMonth(
        _ invoice: Invoice,
        window: CalendarMonthWindow,
        calendar: Calendar
    ) -> Bool {
        guard let startUnix = invoice.period_starts_at else { return false }
        let start = BillingDateParser.parseUnixSeconds(startUnix, calendar: calendar)
        let end: Date
        if let endUnix = invoice.period_ends_at {
            end = BillingDateParser.parseUnixSeconds(endUnix, calendar: calendar)
        } else {
            end = start
        }
        return start < window.nextStart && end >= window.start
    }

    static let invoicesURL = URL(string: "https://cloud.typesense.org/api/v1/invoices?page=1&per_page=50")!

    struct InvoiceList: Decodable, Sendable {
        var invoices: [Invoice]?
        var page: Int?
        var total: Int?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var status: String?
        var amount_cents: FlexibleDecimal?
        var period_starts_at: Int?
        var period_ends_at: Int?
    }
}
