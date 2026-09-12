import Foundation
import MeterCore

/// Ocamba 账户发票（`GET /v2/ocamba/invoices`）。
///
/// 文档：https://docs.ocamba.com/api/core/v2.0/reference/view-invoices/
/// 认证：`Authorization: Bearer <API key>`。
/// Host：`api.ocamba.com`。
/// 金额：`amount` + `currency_code`。日期：`create_time` / `payment_time` / `due_date`。
public struct OcambaBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.ocamba }
    public static let apiHost = "api.ocamba.com"

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
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .ocamba) {
            token = primary
        } else if let alt = try? RequiredCredential.value(.apiToken, in: credential, providerID: .ocamba) {
            token = alt
        } else {
            token = try RequiredCredential.value(.personalAccessToken, in: credential, providerID: .ocamba)
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
            let amount = inv.amount?.value ?? 0
            guard amount > 0 else { continue }
            try currencies.observe(inv.currency_code, providerID: .ocamba)
            let stamp = inv.create_time.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? inv.payment_time.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? inv.due_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.invoice_number ?? inv.id ?? "invoice"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: inv.status ?? "invoice",
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
            providerID: .ocamba
        )
        return Snapshot(
            providerID: .ocamba,
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
            url: Self.invoicesURL, headers: headers, client: httpClient, providerID: .ocamba
        )
        let envelope = try ProviderHTTP.decode(ListResponse.self, from: data, providerID: .ocamba)
        return envelope.items ?? []
    }

    static let invoicesURL = URL(string: "https://api.ocamba.com/v2/ocamba/invoices")!

    struct ListResponse: Decodable, Sendable {
        var total: Int?
        var items: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var invoice_number: String?
        var status: String?
        var amount: FlexibleDecimal?
        var currency_code: String?
        var create_time: String?
        var payment_time: String?
        var due_date: String?
    }
}
