import Foundation
import MeterCore

/// MikroCloud 账户发票（`GET /v1/account/invoices`）。
///
/// 文档：https://docs.mikrocloud.com/api/accounts/invoices
/// 认证：`Authorization: Bearer <token>`（`account:read`）。
/// Host：`api.mikrocloud.com`。
/// 金额：`total` + `currency`（ISO 4217）。日期优先 `created_at`（`YYYY-MM-DD …`）。
public struct MikroCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.mikrocloud }
    public static let apiHost = "api.mikrocloud.com"

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
            if let primary = try? RequiredCredential.value(.personalAccessToken, in: credential, providerID: .mikrocloud) {
                token = primary
            } else {
                token = try RequiredCredential.value(.apiKey, in: credential, providerID: .mikrocloud)
            }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadInvoices(headers: headers)
        for inv in invoices {
            let amount = inv.total?.value ?? inv.amount_due?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe(inv.currency, providerID: .mikrocloud)
            let stamp = inv.created_at.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? inv.period_end.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? inv.period_start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.number ?? inv.id ?? "invoice"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "invoice",
                        label: label,
                        amountUSD: Money(usd: amount)
                    )
                )
            } else if horizon == .availableHistory {
                daily.addPastMonth(
                    start: stamp,
                    amount: Money(usd: amount),
                    current: current,
                    calendar: calendar
                )
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .mikrocloud
        )
        return Snapshot(
            providerID: .mikrocloud,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: converted.money,
            dailyUSD: currencies.scaled(daily.snapshotDaily, by: converted.usdPerUnit),
            converted: currencies.needsConversionNote ? converted : nil,
            lines: lines.snapshot
        )
    }

    private func loadInvoices(headers: [String: String]) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL, headers: headers, client: httpClient, providerID: .mikrocloud
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .mikrocloud) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .mikrocloud)
        return envelope.invoices ?? envelope.data ?? envelope.items ?? []
    }

    static let invoicesURL = URL(string: "https://api.mikrocloud.com/v1/account/invoices")!

    struct InvoiceList: Decodable, Sendable {
        var invoices: [Invoice]?
        var data: [Invoice]?
        var items: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var number: String?
        var total: FlexibleDecimal?
        var amount_due: FlexibleDecimal?
        var currency: String?
        var created_at: String?
        var period_start: String?
        var period_end: String?
        var status: String?
    }
}
