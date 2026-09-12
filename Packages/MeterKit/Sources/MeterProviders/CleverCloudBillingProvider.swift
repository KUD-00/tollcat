import Foundation
import MeterCore

/// Clever Cloud 组织发票（`GET /v4/billing/organisations/{orgId}/invoices`）。
///
/// 文档：https://www.clever.cloud/developers/api/v4/
/// 认证：`Authorization: Bearer <API token>`（Auth Bridge）。
/// Host：`api-bridge.clever-cloud.com`。
/// 金额：`total_tax_excluded.amount` + `total_tax.amount`，币种取自嵌套 Money 或顶层 `currency`。
/// 凭据：`apiToken`/`apiKey` + `accountID`（organisation id）。
public struct CleverCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.clevercloud }
    public static let apiHost = "api-bridge.clever-cloud.com"

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .clevercloud) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .clevercloud)
        }
        let orgID = try RequiredCredential.value(.accountID, in: credential, providerID: .clevercloud)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadInvoices(orgID: orgID, headers: headers)
        for inv in invoices {
            let excluded = inv.total_tax_excluded?.amount?.value ?? 0
            let tax = inv.total_tax?.amount?.value ?? 0
            let amount = excluded + tax
            guard amount != 0 else { continue }
            let currency = inv.total_tax_excluded?.currency
                ?? inv.total_tax?.currency
                ?? inv.currency
            try currencies.observe(currency, providerID: .clevercloud)
            let stamp = inv.emission_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? inv.pay_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.invoice_number ?? inv.kind ?? "invoice"
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
            providerID: .clevercloud
        )
        return Snapshot(
            providerID: .clevercloud,
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

    private func loadInvoices(orgID: String, headers: [String: String]) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL(orgID: orgID),
            headers: headers,
            client: httpClient,
            providerID: .clevercloud
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .clevercloud) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .clevercloud)
        return envelope.invoices ?? []
    }

    static func invoicesURL(orgID: String) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/v4/billing/organisations/\(orgID)/invoices"
        )
    }

    struct InvoiceList: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var invoice_number: String?
        var kind: String?
        var emission_date: String?
        var pay_date: String?
        var status: String?
        var currency: String?
        var total_tax_excluded: MoneyAmount?
        var total_tax: MoneyAmount?
    }

    struct MoneyAmount: Decodable, Sendable {
        var currency: String?
        var amount: FlexibleDecimal?
    }
}
