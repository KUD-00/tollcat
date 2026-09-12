import Foundation
import MeterCore

/// Zoom Billing：`GET /accounts/{accountId}/billing/invoices`（`accountId=me`）→
/// `currency` + `invoices[].total_amount`。
///
/// 文档：https://developers.zoom.us/docs/api/billing/ma/
/// 认证：Bearer OAuth（scopes `billing:read:list_invoices:admin`）；Pro+ 账户。
/// 非 Zoom Commerce customer-invoice 路径。
/// Host：`api.zoom.us`。`accountID` 可选（默认 `me`）。
public struct ZoomBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.zoom }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .zoom)
        let accountID = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let accountPath = (accountID?.isEmpty == false) ? accountID! : "me"
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let url = ProviderURL.https(
            host: "api.zoom.us",
            path: "/v2/accounts/\(accountPath)/billing/invoices"
        )
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .zoom
        )
        let payload = try ProviderHTTP.decode(InvoicePage.self, from: data, providerID: .zoom)

        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0
        try currencies.observe(payload.currency, providerID: .zoom)

        for inv in payload.invoices ?? [] {
            let amount = inv.total_amount?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe(inv.currency ?? payload.currency, providerID: .zoom)
            let stamp = inv.invoice_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? inv.due_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.invoice_number ?? inv.invoice_id ?? "invoice"
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
            providerID: .zoom
        )
        return Snapshot(
            providerID: .zoom,
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

    struct InvoicePage: Decodable, Sendable {
        var currency: String?
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var invoice_id: String?
        var invoice_number: String?
        var invoice_date: String?
        var due_date: String?
        var total_amount: FlexibleDecimal?
        var currency: String?
    }
}
