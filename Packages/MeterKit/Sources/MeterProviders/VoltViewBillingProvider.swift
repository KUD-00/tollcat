import Foundation
import MeterCore

/// VoltView 全站点能源发票（`GET /v1/sites/invoices`）。
///
/// 文档：https://docs.voltview.co.uk/api-reference/sites/invoices-for-all-sites
/// 认证：`x-api-key`。Host：`api.voltview.co.uk`。
/// 金额：`items[].totalAmount`（优先）/`netAmount`；币种文档全局写明 GBP。
public struct VoltViewBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.voltview }
    public static let apiHost = "api.voltview.co.uk"
    public static let currency = "GBP"

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .voltview)
        let headers = [
            "x-api-key": key,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0
        try currencies.observe(Self.currency, providerID: .voltview)

        let invoices = try await loadInvoices(headers: headers)
        for inv in invoices {
            for item in inv.items ?? [] {
                let itemType = (item.itemType ?? "").lowercased()
                if itemType == "credit" { continue }
                let amount = item.totalAmount?.value ?? item.netAmount?.value ?? 0
                guard amount > 0 else { continue }
                let stamp = item.invoiceDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? item.chargeStartDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? item.dueDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = item.invoiceNumber ?? inv.supplierName ?? "invoice"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: item.itemType ?? inv.documentType ?? "invoice",
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
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .voltview
        )
        return Snapshot(
            providerID: .voltview,
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
            url: Self.invoicesURL, headers: headers, client: httpClient, providerID: .voltview
        )
        return try ProviderHTTP.decode([Invoice].self, from: data, providerID: .voltview)
    }

    static let invoicesURL = URL(string: "https://api.voltview.co.uk/v1/sites/invoices")!

    struct Invoice: Decodable, Sendable {
        var documentType: String?
        var supplierName: String?
        var items: [Item]?
    }

    struct Item: Decodable, Sendable {
        var itemType: String?
        var invoiceNumber: String?
        var invoiceDate: String?
        var dueDate: String?
        var chargeStartDate: String?
        var chargeEndDate: String?
        var netAmount: FlexibleDecimal?
        var vatAmount: FlexibleDecimal?
        var totalAmount: FlexibleDecimal?
    }
}
