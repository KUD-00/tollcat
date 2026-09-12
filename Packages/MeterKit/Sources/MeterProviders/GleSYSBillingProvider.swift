import Foundation
import MeterCore

/// GleSYS 客户发票（`GET/POST /invoice/list`）。
///
/// 文档：https://github.com/glesys/api-docs/wiki/API-Documentation#invoicelist
/// 认证：HTTP Basic（`accountID`/`clientID` = customernumber 或 cloud account，`apiKey`/`apiToken` = API key）。
/// Host：`api.glesys.com`。
/// 金额：`total` + `currency`；日期：`invoicedate`。
/// 响应信封：`response.invoices[]`（见 InvoiceRSS 示例）。
public struct GleSYSBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.glesys }
    public static let apiHost = "api.glesys.com"
    public static let invoicesURL = ProviderURL.https(host: apiHost, path: "/invoice/list/format/json")

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
        let username: String
        if let primary = try? RequiredCredential.value(.accountID, in: credential, providerID: .glesys) {
            username = primary
        } else if let primary = try? RequiredCredential.value(.clientID, in: credential, providerID: .glesys) {
            username = primary
        } else {
            username = try RequiredCredential.value(.email, in: credential, providerID: .glesys)
        }
        let password: String
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .glesys) {
            password = primary
        } else {
            password = try RequiredCredential.value(.apiToken, in: credential, providerID: .glesys)
        }
        let headers = [
            "Authorization": "Basic \(ProviderOAuth.basicValue(id: username, secret: password))",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadInvoices(headers: headers)
        for inv in invoices {
            let amount = inv.total?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe(inv.currency, providerID: .glesys)
            let stamp = inv.invoicedate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label: String = {
                if let n = inv.invoicenumber?.value {
                    return "\(n)"
                }
                return inv.url ?? "invoice"
            }()
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
            providerID: .glesys
        )
        return Snapshot(
            providerID: .glesys,
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
            url: Self.invoicesURL,
            headers: headers,
            client: httpClient,
            providerID: .glesys
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .glesys) {
            return list
        }
        let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .glesys)
        return envelope.response?.invoices ?? envelope.invoices ?? []
    }

    struct Envelope: Decodable, Sendable {
        var response: ResponseBody?
        var invoices: [Invoice]?
    }

    struct ResponseBody: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var invoicenumber: FlexibleDecimal?
        var invoicedate: String?
        var duedate: String?
        var total: FlexibleDecimal?
        var currency: String?
        var url: String?
    }
}
