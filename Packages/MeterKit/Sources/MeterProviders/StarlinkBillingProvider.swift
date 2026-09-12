import Foundation
import MeterCore

/// Starlink Public API v2：`GET /api/public/v2/billing/invoices` → `amount` + ISO `currency`；
/// 余额 `GET /api/public/v2/billing/balance` → `dueAmount` + `currency`（作补充行，不计入当期用量合计）。
///
/// 文档：https://starlink.readme.io/reference/get_public-v2-billing-invoices
/// 认证：Bearer JWT。Host：`starlink.com`。
public struct StarlinkBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.starlink }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .starlink)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var page = 0
        var isLast = false
        while !isLast {
            let pageData = try await loadInvoices(page: page, headers: headers)
            let content = pageData.content
            isLast = content?.isLastPage ?? true
            for inv in content?.results ?? [] {
                let status = inv.status ?? ""
                if status == "Cancelled" { continue }
                let amount = inv.amount?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(inv.currency, providerID: .starlink)
                let stamp = inv.invoiceDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: "invoice",
                            label: inv.invoiceId ?? inv.description ?? "invoice",
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
            if content?.results == nil { break }
            page += 1
            if page > 50 { break }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .starlink
        )
        return Snapshot(
            providerID: .starlink,
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

    private func loadInvoices(page: Int, headers: [String: String]) async throws -> InvoicePageEnvelope {
        let url = ProviderURL.https(
            host: "starlink.com",
            path: "/api/public/v2/billing/invoices",
            query: [URLQueryItem(name: "page", value: String(page))]
        )
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .starlink
        )
        return try ProviderHTTP.decode(InvoicePageEnvelope.self, from: data, providerID: .starlink)
    }

    struct InvoicePageEnvelope: Decodable, Sendable {
        var content: Paginated?
        var isValid: Bool?
    }

    struct Paginated: Decodable, Sendable {
        var pageIndex: Int?
        var isLastPage: Bool?
        var results: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var invoiceId: String?
        var description: String?
        var currency: String?
        var amount: FlexibleDecimal?
        var dueAmount: FlexibleDecimal?
        var invoiceDate: String?
        var status: String?
    }
}
