import Foundation
import MeterCore

/// Fastly 当月至今发票。
///
/// 文档：`GET /billing/v3/invoices/month-to-date`
/// 认证：`Fastly-Key: <token>`，只需要 billing 的只读权限。
///
/// v2 的 `/billing/{year}/{month}` 已在 2025-03 下线，不要再回退到它。
/// 这条接口给的是一个已经算好的月度金额，我们不按流量单价重算。
public struct FastlyBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.fastly }

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar
    /// 厂商用非美元结算时按这张表换。默认只认美元，行为和加它之前一样。
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
        var currency = CurrencyAccumulator()
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .fastly)
        let headers = [
            "Fastly-Key": token,
        ]
        let data = try await ProviderHTTP.get(
            url: Self.monthToDateURL,
            headers: headers,
            client: httpClient,
            providerID: .fastly
        )
        let invoice = try ProviderHTTP.decode(Invoice.self, from: data, providerID: .fastly)
        try currency.observe(invoice.currency_code, providerID: .fastly)

        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let period = BillingPeriodResolver.resolve(
            startRaw: invoice.billing_start_date,
            endRaw: invoice.billing_end_date,
            // Fastly 的 end 就是最后一天，且周期不一定贴着日历月。
            endConvention: .inclusive,
            fallback: window,
            calendar: calendar
        )
        var daily = DailySpendAccumulator()
        if horizon == .availableHistory {
            let listData = try await ProviderHTTP.get(
                url: Self.invoicesURL,
                headers: headers,
                client: httpClient,
                providerID: .fastly
            )
            let list = try ProviderHTTP.decode(InvoiceList.self, from: listData, providerID: .fastly)
            for past in list.data ?? [] {
                try currency.observe(past.currency_code, providerID: .fastly)
                let amount = past.monthly_transaction_amount?.value ?? 0
                let start = past.billing_start_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                guard amount != 0, let start else { continue }
                daily.addPastMonth(
                    start: start,
                    amount: Money(usd: amount),
                    current: window,
                    calendar: calendar
                )
            }
        }

        return try Snapshot(
            providerID: .fastly,
            kind: .usage,
            fetchedAt: now,
            periodStart: period.start,
            periodEnd: period.end,
            currentSpendUSD: Money(usd: invoice.monthly_transaction_amount?.value ?? 0),
            dailyUSD: daily.snapshotDaily
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    static let monthToDateURL = URL(string: "https://api.fastly.com/billing/v3/invoices/month-to-date")!
    static let invoicesURL = URL(string: "https://api.fastly.com/billing/v3/invoices")!

    struct Invoice: Decodable, Sendable {
        var customer_id: String?
        var invoice_id: String?
        var billing_start_date: String?
        var billing_end_date: String?
        var monthly_transaction_amount: FlexibleDecimal?
        var currency_code: String?
    }

    struct InvoiceList: Decodable, Sendable {
        var data: [Invoice]?
    }
}
