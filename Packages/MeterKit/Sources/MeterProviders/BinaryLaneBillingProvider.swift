import Foundation
import MeterCore

/// BinaryLane 发票用量（`GET /v2/customers/my/invoices` + `/{invoice_id}`；次级 `GET /v2/customers/my/balance`）。
///
/// 文档：https://api.binarylane.com.au/reference/
/// 认证：`Authorization: Bearer`。Host：`api.binarylane.com.au`。
/// 金额：发票 `invoice.amount`，币种固定 AUD（文档 AU$）；忽略 `available_credit` 作主合计。
/// 无本月发票时回落到 balance `unbilled_total`。
public struct BinaryLaneBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.binarylane }
    public static let apiHost = "api.binarylane.com.au"
    public static let currency = "AUD"
    static let maxDetailFetches = 40

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .binarylane)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0
        try currencies.observe(Self.currency, providerID: .binarylane)

        let list = try await loadInvoices(headers: headers)
        var detailBudget = Self.maxDetailFetches
        for summary in list {
            let stamp = summary.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? summary.created.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            var amount = summary.amount?.value ?? summary.invoice?.amount?.value ?? 0
            if detailBudget > 0, let id = summary.invoice_id ?? summary.id.map(String.init) {
                detailBudget -= 1
                if let detail = try? await loadDetail(id: id, headers: headers) {
                    amount = detail.invoice?.amount?.value ?? detail.amount?.value ?? amount
                }
            }
            guard amount != 0 else { continue }
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "invoice",
                        label: summary.invoice_id ?? summary.id.map(String.init) ?? "invoice",
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

        // Secondary: unbilled_total when no invoice spend this month (not available_credit).
        if currentTotal == 0, let balance = try? await loadBalance(headers: headers) {
            let unbilled = balance.unbilled_total?.value ?? 0
            if unbilled != 0 {
                currentTotal = unbilled
                lines.add(
                    SpendLine(
                        category: "unbilled",
                        label: "unbilled total",
                        amountUSD: Money(usd: unbilled)
                    )
                )
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .binarylane
        )
        return Snapshot(
            providerID: .binarylane,
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

    private func loadInvoices(headers: [String: String]) async throws -> [InvoiceSummary] {
        let url = ProviderURL.https(host: Self.apiHost, path: "/v2/customers/my/invoices")
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .binarylane
        )
        if let list = try? ProviderHTTP.decode([InvoiceSummary].self, from: data, providerID: .binarylane) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .binarylane)
        return envelope.invoices ?? envelope.data ?? []
    }

    private func loadDetail(id: String, headers: [String: String]) async throws -> InvoiceDetail {
        let url = ProviderURL.https(host: Self.apiHost, path: "/v2/customers/my/invoices/\(id)")
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .binarylane
        )
        return try ProviderHTTP.decode(InvoiceDetail.self, from: data, providerID: .binarylane)
    }

    private func loadBalance(headers: [String: String]) async throws -> Balance {
        let url = ProviderURL.https(host: Self.apiHost, path: "/v2/customers/my/balance")
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .binarylane
        )
        return try ProviderHTTP.decode(Balance.self, from: data, providerID: .binarylane)
    }

    struct InvoiceList: Decodable, Sendable {
        var invoices: [InvoiceSummary]?
        var data: [InvoiceSummary]?
    }

    struct InvoiceSummary: Decodable, Sendable {
        var id: Int?
        var invoice_id: String?
        var amount: FlexibleDecimal?
        var date: String?
        var created: String?
        var invoice: InvoiceBody?
    }

    struct InvoiceDetail: Decodable, Sendable {
        var invoice: InvoiceBody?
        var amount: FlexibleDecimal?
    }

    struct InvoiceBody: Decodable, Sendable {
        var amount: FlexibleDecimal?
    }

    struct Balance: Decodable, Sendable {
        var unbilled_total: FlexibleDecimal?
        var available_credit: FlexibleDecimal?
    }
}
