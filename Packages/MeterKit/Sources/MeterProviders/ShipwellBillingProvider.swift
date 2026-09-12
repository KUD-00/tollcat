import Foundation
import MeterCore

/// Shipwell 货运发票（`GET /freight-invoices`）。
///
/// 文档：https://docs.shipwell.com/openapi_pages/settlements/operation/list_freight_invoices/
/// 认证：`Authorization: Token <user token>`（或 `APIkey <key>`）。
/// Host：`api.shipwell.com`。
/// 金额：`total_amount.value` + `total_amount.currency`（或顶层 `currency`）。
/// 日期：`invoice_date` / `created_at`。跳过 `VOIDED` / `REJECTED`。
public struct ShipwellBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.shipwell }
    public static let apiHost = "api.shipwell.com"
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
        let token: String
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .shipwell) {
            token = primary
        } else if let alt = try? RequiredCredential.value(.apiToken, in: credential, providerID: .shipwell) {
            token = alt
        } else {
            token = try RequiredCredential.value(.personalAccessToken, in: credential, providerID: .shipwell)
        }
        let authValue: String
        if token.lowercased().hasPrefix("token ") || token.lowercased().hasPrefix("apikey ") {
            authValue = token
        } else {
            authValue = "Token \(token)"
        }
        let headers = [
            "Authorization": authValue,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var page = 1
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let batch = try await loadInvoices(page: page, headers: headers)
            if batch.isEmpty { break }
            for inv in batch {
                if let status = inv.status?.uppercased(), status == "VOIDED" || status == "REJECTED" {
                    continue
                }
                let amount = inv.total_amount?.value?.value ?? 0
                guard amount > 0 else { continue }
                let currency = inv.total_amount?.currency ?? inv.currency
                try currencies.observe(currency, providerID: .shipwell)
                let stamp = inv.invoice_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.created_at.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = inv.invoice_number ?? inv.id ?? "invoice"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: inv.status ?? "invoice",
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
            page += 1
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .shipwell
        )
        return Snapshot(
            providerID: .shipwell,
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

    private func loadInvoices(page: Int, headers: [String: String]) async throws -> [Invoice] {
        var components = URLComponents(url: Self.invoicesURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(Self.pageSize)),
        ]
        let data = try await ProviderHTTP.get(
            url: components.url!,
            headers: headers,
            client: httpClient,
            providerID: .shipwell
        )
        let envelope = try ProviderHTTP.decode(ListResponse.self, from: data, providerID: .shipwell)
        return envelope.data ?? []
    }

    static let invoicesURL = URL(string: "https://api.shipwell.com/freight-invoices")!
    static func invoicesURL(page: Int) -> URL {
        var components = URLComponents(url: invoicesURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(pageSize)),
        ]
        return components.url!
    }

    struct ListResponse: Decodable, Sendable {
        var data: [Invoice]?
    }
    struct Invoice: Decodable, Sendable {
        var id: String?
        var invoice_number: String?
        var invoice_date: String?
        var created_at: String?
        var status: String?
        var currency: String?
        var total_amount: MoneyAmount?
    }
    struct MoneyAmount: Decodable, Sendable {
        var value: FlexibleDecimal?
        var currency: String?
    }
}
