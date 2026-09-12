import Foundation
import MeterCore

/// Hostens 客户发票（`GET /userapi/invoice` + `GET /userapi/invoice/@id`；次级 `GET /userapi/balance`）。
///
/// 文档：https://billing.hostens.com/userapi
/// 认证：`Authorization` / API key。Host：`billing.hostens.com`。
/// 金额：发票 `total` + `currency` 为主；无本月发票时回落到 balance `acc_balance` 预付。
public struct HostensBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.hostens }
    public static let apiHost = "billing.hostens.com"
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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .hostens)
        let headers = [
            "Authorization": apiKey,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let list = try await loadInvoices(headers: headers)
        var detailBudget = Self.maxDetailFetches
        for summary in list {
            let stamp = summary.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? summary.duedate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            var amount = summary.total?.value ?? 0
            var currency = summary.currency
            if detailBudget > 0, let id = summary.id.map(String.init) ?? summary.invoiceid.map(String.init) {
                detailBudget -= 1
                if let detail = try? await loadDetail(id: id, headers: headers) {
                    amount = detail.total?.value ?? amount
                    currency = detail.currency ?? currency
                }
            }
            try currencies.observe(currency, providerID: .hostens)
            guard amount != 0 else { continue }
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "invoice",
                        label: summary.invoiceid.map(String.init) ?? summary.id.map(String.init) ?? "invoice",
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

        // Invoices primary; prepaid balance only when no current-month invoice spend.
        if currentTotal == 0, let balance = try? await loadBalance(headers: headers),
           let prepaid = balance.acc_balance?.value, prepaid != 0 {
            try currencies.observe(balance.currency, providerID: .hostens)
            let converted = try currencies.convert(
                prepaid,
                rates: rateSource.current,
                providerID: .hostens
            )
            return PrepaidSnapshot.make(
                providerID: .hostens,
                now: now,
                calendar: calendar,
                balance: converted.money,
                converted: currencies.needsConversionNote ? converted : nil
            )
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .hostens
        )
        return Snapshot(
            providerID: .hostens,
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
        let url = ProviderURL.https(host: Self.apiHost, path: "/userapi/invoice")
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .hostens
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .hostens) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .hostens)
        return envelope.invoice ?? envelope.invoices ?? envelope.data ?? []
    }

    private func loadDetail(id: String, headers: [String: String]) async throws -> Invoice {
        let url = ProviderURL.https(host: Self.apiHost, path: "/userapi/invoice/\(id)")
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .hostens
        )
        return try ProviderHTTP.decode(Invoice.self, from: data, providerID: .hostens)
    }

    private func loadBalance(headers: [String: String]) async throws -> Balance {
        let url = ProviderURL.https(host: Self.apiHost, path: "/userapi/balance")
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .hostens
        )
        return try ProviderHTTP.decode(Balance.self, from: data, providerID: .hostens)
    }

    struct InvoiceList: Decodable, Sendable {
        var invoice: [Invoice]?
        var invoices: [Invoice]?
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: Int?
        var invoiceid: Int?
        var total: FlexibleDecimal?
        var subtotal: FlexibleDecimal?
        var tax: FlexibleDecimal?
        var currency: String?
        var date: String?
        var duedate: String?
        var status: String?
    }

    struct Balance: Decodable, Sendable {
        var currency: String?
        var acc_balance: FlexibleDecimal?
    }
}
