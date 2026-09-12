import Foundation
import MeterCore

/// TransIP 账户发票（`GET /v6/invoices`）。
///
/// 文档：https://api.transip.nl/rest/docs.html#invoices
/// 认证：`Authorization: Bearer <JWT>`（控制面板签发的 API token）。
/// Host：`api.transip.nl`。
/// 金额：`totalAmount` / `totalAmountInclVat` 为**分**（cents）+ `currency`（ISO 4217）。
/// 日期：`creationDate`（`YYYY-MM-DD`）。本月合计用含税总额。
public struct TransIPBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.transip }
    public static let apiHost = "api.transip.nl"
    static let centsPerUnit = Decimal(100)

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
        if let primary = try? RequiredCredential.value(.personalAccessToken, in: credential, providerID: .transip) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .transip)
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
            let cents = inv.totalAmountInclVat?.value ?? inv.totalAmount?.value ?? 0
            guard cents > 0 else { continue }
            let amount = cents / Self.centsPerUnit
            try currencies.observe(inv.currency, providerID: .transip)
            let stamp = inv.creationDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? inv.payDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? inv.dueDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.invoiceNumber ?? inv.invoiceStatus ?? "invoice"
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
            providerID: .transip
        )
        return Snapshot(
            providerID: .transip,
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
            url: Self.invoicesURL, headers: headers, client: httpClient, providerID: .transip
        )
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .transip)
        return envelope.invoices ?? []
    }

    static let invoicesURL = URL(string: "https://api.transip.nl/v6/invoices")!

    struct InvoiceList: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var invoiceNumber: String?
        var creationDate: String?
        var payDate: String?
        var dueDate: String?
        var invoiceStatus: String?
        var currency: String?
        var totalAmount: FlexibleDecimal?
        var totalAmountInclVat: FlexibleDecimal?
    }
}
