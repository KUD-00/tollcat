import Foundation
import MeterCore

/// HostUp 发票用量花费（`GET /api/v2/billing/invoices` + `GET /api/v2/billing/invoices/{id}`）。
///
/// 文档：https://developer.hostup.se/endpoints/billing/get-v2-billing-invoices-id
/// 认证：`Authorization: Bearer`（需 `read:billing`）。Host：`cloud.hostup.se`。
/// 金额：`totals.total` + ISO `totals.currencyCode`；明细 `lineItems[].totalAmount` + `currencyCode`。
/// 列表筛本月 `dates.issuedAt`；详情补 lineItems。可选 PAYG `GET /api/v2/vps/{id}/billing-breakdown` 不作为主合计。
public struct HostUpBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.hostup }
    public static let apiHost = "cloud.hostup.se"
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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .hostup)
        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let list = try await loadInvoiceList(headers: headers)
        var detailBudget = Self.maxDetailFetches
        for summary in list {
            let status = (summary.status ?? "").lowercased()
            if status == "draft" || status == "cancelled" { continue }
            let issued = summary.dates?.issuedAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? summary.issuedAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
            let stamp = issued ?? current.start

            var amount = summary.totals?.total?.value
                ?? summary.total?.value
                ?? 0
            var currency = summary.totals?.currencyCode ?? summary.currencyCode
            var detailLines: [LineItem] = []

            if detailBudget > 0, let id = summary.id?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty {
                detailBudget -= 1
                if let detail = try? await loadInvoiceDetail(id: id, headers: headers) {
                    amount = detail.totals?.total?.value ?? amount
                    currency = detail.totals?.currencyCode ?? currency
                    detailLines = detail.lineItems ?? []
                }
            }

            try currencies.observe(currency, providerID: .hostup)
            guard amount != 0 else { continue }

            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                if detailLines.isEmpty {
                    lines.add(
                        SpendLine(
                            category: "invoice",
                            label: summary.number ?? summary.id ?? "invoice",
                            amountUSD: Money(usd: amount)
                        )
                    )
                } else {
                    for item in detailLines {
                        let itemAmount = item.totalAmount?.value ?? 0
                        guard itemAmount != 0 else { continue }
                        try currencies.observe(item.currencyCode ?? currency, providerID: .hostup)
                        lines.add(
                            SpendLine(
                                category: item.kind ?? item.purpose ?? "line",
                                label: item.displayDescription
                                    ?? item.description
                                    ?? item.resource?.displayName
                                    ?? "line",
                                amountUSD: Money(usd: itemAmount)
                            )
                        )
                    }
                }
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
            providerID: .hostup
        )
        return Snapshot(
            providerID: .hostup,
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

    private func loadInvoiceList(headers: [String: String]) async throws -> [InvoiceSummary] {
        var all: [InvoiceSummary] = []
        var page = 1
        while page <= 10 {
            let url = ProviderURL.https(
                host: Self.apiHost,
                path: "/api/v2/billing/invoices",
                query: [
                    URLQueryItem(name: "page", value: String(page)),
                    URLQueryItem(name: "perPage", value: "50"),
                ]
            )
            let data = try await ProviderHTTP.get(
                url: url, headers: headers, client: httpClient, providerID: .hostup
            )
            if let list = try? ProviderHTTP.decode([InvoiceSummary].self, from: data, providerID: .hostup) {
                all.append(contentsOf: list)
                if list.count < 50 { break }
            } else {
                let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .hostup)
                let batch = envelope.data ?? envelope.invoices ?? envelope.items ?? []
                all.append(contentsOf: batch)
                if batch.count < 50 { break }
                if envelope.hasMore == false { break }
            }
            page += 1
        }
        return all
    }

    private func loadInvoiceDetail(id: String, headers: [String: String]) async throws -> InvoiceDetail {
        let url = ProviderURL.https(host: Self.apiHost, path: "/api/v2/billing/invoices/\(id)")
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .hostup
        )
        return try ProviderHTTP.decode(InvoiceDetail.self, from: data, providerID: .hostup)
    }

    struct InvoiceList: Decodable, Sendable {
        var data: [InvoiceSummary]?
        var invoices: [InvoiceSummary]?
        var items: [InvoiceSummary]?
        var hasMore: Bool?
    }

    struct InvoiceSummary: Decodable, Sendable {
        var id: String?
        var number: String?
        var status: String?
        var dates: Dates?
        var issuedAt: String?
        var totals: Totals?
        var total: FlexibleDecimal?
        var currencyCode: String?
    }

    struct InvoiceDetail: Decodable, Sendable {
        var id: String?
        var number: String?
        var status: String?
        var dates: Dates?
        var totals: Totals?
        var lineItems: [LineItem]?
    }

    struct Dates: Decodable, Sendable {
        var issuedAt: String?
        var dueAt: String?
        var paidAt: String?
    }

    struct Totals: Decodable, Sendable {
        var currencyCode: String?
        var subtotal: FlexibleDecimal?
        var taxAmount: FlexibleDecimal?
        var total: FlexibleDecimal?
        var outstanding: FlexibleDecimal?
    }

    struct LineItem: Decodable, Sendable {
        var kind: String?
        var purpose: String?
        var description: String?
        var displayDescription: String?
        var totalAmount: FlexibleDecimal?
        var currencyCode: String?
        var resource: Resource?
    }

    struct Resource: Decodable, Sendable {
        var type: String?
        var id: String?
        var displayName: String?
    }
}
