import Foundation
import MeterCore

/// Flexport 货运账单发票（`GET /invoices`）。
///
/// 文档：https://developers.flexport.com/tutorials/freight-invoices-api-tutorial/
/// 认证：`Authorization: Bearer <token>` + `Flexport-Version: 3`。
/// Host：`api.flexport.com`。
/// 金额：`total.amount` + `total.currency_code`。按 `issued_at` 归入本月；只累计正金额。
public struct FlexportBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.flexport }
    public static let apiHost = "api.flexport.com"
    static let maxPages = 20

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
        if let primary = try? RequiredCredential.value(.personalAccessToken, in: credential, providerID: .flexport) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .flexport)
        }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Flexport-Version": "3",
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
                if inv.voided_at != nil { continue }
                let amount = inv.total?.amount?.value ?? 0
                guard amount > 0 else { continue }
                try currencies.observe(inv.total?.currency_code, providerID: .flexport)
                let stamp = inv.issued_at.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.due_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = inv.name ?? inv.id ?? "invoice"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: inv.type ?? inv.status ?? "invoice",
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
            if batch.count < 100 { break }
            page += 1
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .flexport
        )
        return Snapshot(
            providerID: .flexport,
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
        let url = Self.invoicesURL(page: page)
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .flexport
        )
        let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .flexport)
        return envelope.data?.data ?? envelope.data?.invoices ?? []
    }

    static func invoicesURL(page: Int) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/invoices",
            query: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per", value: "100"),
            ]
        )
    }

    struct Envelope: Decodable, Sendable {
        var data: Collection?
    }

    struct Collection: Decodable, Sendable {
        var data: [Invoice]?
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var name: String?
        var issued_at: String?
        var due_date: String?
        var total: MoneyAmount?
        var status: String?
        var type: String?
        var voided_at: String?
    }

    struct MoneyAmount: Decodable, Sendable {
        var amount: FlexibleDecimal?
        var currency_code: String?
    }
}
