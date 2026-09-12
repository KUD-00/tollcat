import Foundation
import MeterCore

/// CockroachDB Cloud 本周期草稿发票。
///
/// 文档：`GET /api/v1/invoices`
/// 认证：`Authorization: Bearer <secret key>`，角色 Billing Coordinator 或 Cluster Admin。
///
/// 正在累计的那张是 `DRAFT`。`totals[].amount` 是该币种的金额，不是美分。
public struct CockroachBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.cockroach }
    public static let draftStatus = "DRAFT"
    public static let apiVersion = "2024-09-16"

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .cockroach)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL,
            headers: [
                "Authorization": "Bearer \(token)",
                "Cc-Version": Self.apiVersion,
            ],
            client: httpClient,
            providerID: .cockroach
        )
        let payload = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .cockroach)
        let invoices = payload.invoices ?? []
        var currency = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        if horizon == .availableHistory {
            for invoice in invoices {
                var total: Decimal = 0
                for row in invoice.totals ?? [] {
                    try currency.observe(row.currency, providerID: .cockroach)
                    total += row.amount?.value ?? 0
                }
                let start = invoice.period_start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                guard let start else { continue }
                daily.addPastMonth(
                    start: start,
                    amount: Money(usd: total),
                    current: window,
                    calendar: calendar
                )
            }
        }
        guard let invoice = Self.currentInvoice(invoices, now: now, calendar: calendar) else {
            return try Snapshot(
                providerID: .cockroach,
                kind: .usage,
                fetchedAt: now,
                periodStart: window.start,
                periodEnd: window.endInclusive,
                dailyUSD: daily.snapshotDaily
            ).convertedToUSD(using: currency, rates: rateSource.current)
        }
        let period = BillingPeriodResolver.resolve(
            startRaw: invoice.period_start,
            endRaw: invoice.period_end,
            endConvention: .exclusive,
            fallback: window,
            calendar: calendar
        )
        var total: Decimal = 0
        for row in invoice.totals ?? [] {
            try currency.observe(row.currency, providerID: .cockroach)
            total += row.amount?.value ?? 0
        }
        return try Snapshot(
            providerID: .cockroach,
            kind: .usage,
            fetchedAt: now,
            periodStart: period.start,
            periodEnd: period.end,
            currentSpendUSD: Money(usd: total),
            dailyUSD: daily.snapshotDaily
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    /// 先认草稿。没有草稿就取覆盖今天的那张。
    static func currentInvoice(_ invoices: [Invoice], now: Date, calendar: Calendar) -> Invoice? {
        if let draft = invoices.first(where: { $0.status == draftStatus }) {
            return draft
        }
        let day = calendar.startOfDay(for: now)
        return invoices.first { invoice in
            guard
                let start = invoice.period_start.flatMap({ BillingDateParser.parse($0, calendar: calendar) }),
                let end = invoice.period_end.flatMap({ BillingDateParser.parse($0, calendar: calendar) })
            else {
                return false
            }
            return day >= start && day < end
        }
    }

    static let invoicesURL = URL(string: "https://cockroachlabs.cloud/api/v1/invoices")!

    struct InvoiceList: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var invoice_id: String?
        var status: String?
        var period_start: String?
        var period_end: String?
        var totals: [CurrencyAmount]?
    }

    struct CurrencyAmount: Decodable, Sendable {
        var amount: FlexibleDecimal?
        var currency: String?
    }
}
