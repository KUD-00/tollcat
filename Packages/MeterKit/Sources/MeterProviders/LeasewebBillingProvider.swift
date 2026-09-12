import Foundation
import MeterCore

/// Leaseweb 客户发票（`GET /invoices/v1/invoices`）。
///
/// 文档：https://developer.leaseweb.com/api-docs/invoice_v1.html
/// 认证：`X-LSW-Auth: <API key>`（Customer Portal → API Client Management）。
/// Host：`api.leaseweb.com`。
/// 金额：`total` + `currency`（ISO 4217）。按 `date` 归入本月。
public struct LeasewebBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.leaseweb }
    public static let apiHost = "api.leaseweb.com"
    static let maxPages = 20
    static let pageSize = 100

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
        let key: String
            if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .leaseweb) {
                key = primary
            } else {
                key = try RequiredCredential.value(.apiToken, in: credential, providerID: .leaseweb)
            }
        let headers = [
            "X-LSW-Auth": key,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var offset = 0
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let batch = try await loadInvoices(offset: offset, headers: headers)
            if batch.isEmpty { break }
            for inv in batch {
                let amount = inv.total?.value ?? inv.openAmount?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(inv.currency, providerID: .leaseweb)
                let stamp = inv.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.dueDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = inv.id ?? "invoice"
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
            if batch.count < Self.pageSize { break }
            offset += Self.pageSize
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .leaseweb
        )
        return Snapshot(
            providerID: .leaseweb,
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

    private func loadInvoices(
        offset: Int,
        headers: [String: String]
    ) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL(offset: offset),
            headers: headers,
            client: httpClient,
            providerID: .leaseweb
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .leaseweb) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .leaseweb)
        return envelope.invoices ?? envelope.data ?? envelope.items ?? envelope.results ?? []
    }

    static func invoicesURL(offset: Int) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/invoices/v1/invoices",
            query: [
                URLQueryItem(name: "limit", value: String(pageSize)),
                URLQueryItem(name: "offset", value: String(offset)),
            ]
        )
    }

    struct InvoiceList: Decodable, Sendable {
        var invoices: [Invoice]?
        var data: [Invoice]?
        var items: [Invoice]?
        var results: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var total: FlexibleDecimal?
        var openAmount: FlexibleDecimal?
        var currency: String?
        var date: String?
        var dueDate: String?
        var status: String?
    }
}
