import Foundation
import MeterCore

/// Formspring 团队发票（`GET /api/v1/billing/invoices`）。
///
/// 文档：https://formspring.io/docs/api/reference/billing
/// 认证：`Authorization: Bearer <token>`（需 `billing:read`）。Host：`formspring.io`。
/// 金额：`total` 为 USD cents（÷100）；日期：`date`；跳过 void/uncollectible。
/// **不用** `/billing/usage` 的 value/limit（计量配额，非金额）。
public struct FormspringBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.formspring }
    public static let apiHost = "formspring.io"
    public static let invoicesURL = ProviderURL.https(host: apiHost, path: "/api/v1/billing/invoices")
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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .formspring) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .formspring)
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
            let status = (inv.status ?? "").lowercased()
            if status == "void" || status == "uncollectible" || status == "draft" { continue }
            let cents = inv.total?.value ?? 0
            guard cents != 0 else { continue }
            let amount = cents / Self.centsPerUnit
            try currencies.observe("USD", providerID: .formspring)
            let stamp = inv.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
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
            providerID: .formspring
        )
        return Snapshot(
            providerID: .formspring,
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
            url: Self.invoicesURL,
            headers: headers,
            client: httpClient,
            providerID: .formspring
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .formspring) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .formspring)
        return envelope.data ?? envelope.invoices ?? []
    }

    struct InvoiceList: Decodable, Sendable {
        var data: [Invoice]?
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var number: String?
        var total: FlexibleDecimal?
        var status: String?
        var date: String?
        var hosted_invoice_url: String?
    }
}
