import Foundation
import MeterCore

/// mittwald 客户发票（`GET /v2/customers/{id}/invoices` + `GET /v2/invoices/{id}`）。
///
/// 文档：https://developer.mittwald.de/docs/v2/reference/contract/invoice-detail/
/// 认证：`Authorization: Bearer`。Host：`api.mittwald.de`。
/// 合计：`totalGross`（优先）/`totalNet` + ISO `currency`；明细 `groups[].items[].price.value`（最小货币单位）÷ 100。
/// `accountID` = customerId。
public struct MittwaldBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.mittwald }
    public static let apiHost = "api.mittwald.de"
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
        let auth: String
        if let t = credential.value(for: .apiToken)?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
            auth = t
        } else {
            auth = try RequiredCredential.value(.apiKey, in: credential, providerID: .mittwald)
        }
        let customerID = try RequiredCredential.value(.accountID, in: credential, providerID: .mittwald)
        let headers = [
            "Authorization": "Bearer \(auth)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let list = try await loadInvoices(customerID: customerID, headers: headers)
        var detailBudget = Self.maxDetailFetches
        for summary in list {
            let type = (summary.invoiceType ?? "").uppercased()
            if type == "CANCELLATION" { continue }
            let stamp = summary.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            try currencies.observe(summary.currency, providerID: .mittwald)

            var gross = summary.totalGross?.value ?? summary.totalNet?.value ?? 0
            var detail: InvoiceDetail?
            if detailBudget > 0, let id = summary.id {
                detailBudget -= 1
                detail = try? await loadDetail(id: id, headers: headers)
                if let d = detail {
                    try currencies.observe(d.currency ?? summary.currency, providerID: .mittwald)
                    gross = d.totalGross?.value ?? d.totalNet?.value ?? gross
                }
            }
            guard gross != 0 else { continue }

            if current.contains(stamp) {
                currentTotal += gross
                daily.add(day: stamp, amount: Money(usd: gross))
                let items = detail?.groups?.flatMap { $0.items ?? [] } ?? []
                if items.isEmpty {
                    lines.add(
                        SpendLine(
                            category: type.isEmpty ? "invoice" : type.lowercased(),
                            label: summary.invoiceNumber ?? summary.id ?? "invoice",
                            amountUSD: Money(usd: gross)
                        )
                    )
                } else {
                    for item in items {
                        try currencies.observe(item.price?.currency, providerID: .mittwald)
                        let major = Decimal(item.price?.value ?? 0) / 100
                        guard major != 0 else { continue }
                        lines.add(
                            SpendLine(
                                category: "item",
                                label: item.description ?? item.itemId ?? "item",
                                amountUSD: Money(usd: major)
                            )
                        )
                    }
                }
            } else if horizon == .availableHistory {
                daily.addPastMonth(
                    start: stamp,
                    amount: Money(usd: gross),
                    current: current,
                    calendar: calendar
                )
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .mittwald
        )
        return Snapshot(
            providerID: .mittwald,
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

    private func loadInvoices(customerID: String, headers: [String: String]) async throws -> [InvoiceSummary] {
        var all: [InvoiceSummary] = []
        var page = 1
        while page <= 20 {
            let url = ProviderURL.https(
                host: Self.apiHost,
                path: "/v2/customers/\(customerID)/invoices",
                query: [
                    URLQueryItem(name: "limit", value: "50"),
                    URLQueryItem(name: "page", value: String(page)),
                    URLQueryItem(name: "invoiceTypes", value: "REGULAR"),
                ]
            )
            let data = try await ProviderHTTP.get(
                url: url, headers: headers, client: httpClient, providerID: .mittwald
            )
            let batch = (try? ProviderHTTP.decode([InvoiceSummary].self, from: data, providerID: .mittwald))
                ?? []
            all.append(contentsOf: batch)
            if batch.count < 50 { break }
            page += 1
        }
        return all
    }

    private func loadDetail(id: String, headers: [String: String]) async throws -> InvoiceDetail {
        let url = ProviderURL.https(host: Self.apiHost, path: "/v2/invoices/\(id)")
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .mittwald
        )
        return try ProviderHTTP.decode(InvoiceDetail.self, from: data, providerID: .mittwald)
    }

    struct InvoiceSummary: Decodable, Sendable {
        var id: String?
        var invoiceNumber: String?
        var invoiceType: String?
        var currency: String?
        var date: String?
        var status: String?
        var totalGross: FlexibleDecimal?
        var totalNet: FlexibleDecimal?
    }

    struct InvoiceDetail: Decodable, Sendable {
        var id: String?
        var invoiceNumber: String?
        var currency: String?
        var totalGross: FlexibleDecimal?
        var totalNet: FlexibleDecimal?
        var groups: [Group]?
    }

    struct Group: Decodable, Sendable {
        var description: String?
        var items: [Item]?
    }

    struct Item: Decodable, Sendable {
        var itemId: String?
        var description: String?
        var price: Price?
    }

    struct Price: Decodable, Sendable {
        var currency: String?
        var value: Int64?
    }
}
