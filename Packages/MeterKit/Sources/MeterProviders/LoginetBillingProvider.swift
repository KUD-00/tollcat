import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Loginet 客户发票（`GET /api/invoice`）。
///
/// 文档：https://hostbill.loginet.ee/?cmd=userapi
/// 认证：HTTP Basic（`email`/`clientID` + `clientSecret`/`apiToken`/`apiKey`）。
/// Host：`hostbill.loginet.ee`。
/// 金额：`total` + `currency`；日期 `date` / `datepaid`。
/// **忽略** `GET /api/balance`（未付合计 / 账户 credit 预付）。跳过 Cancelled。
public struct LoginetBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.loginet }
    public static let apiHost = "hostbill.loginet.ee"
    public static let invoicesURL = ProviderURL.https(host: apiHost, path: "/api/invoice")

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
        if let primary = try? RequiredCredential.value(.email, in: credential, providerID: .loginet) {
            username = primary
        } else {
            username = try RequiredCredential.value(.clientID, in: credential, providerID: .loginet)
        }
        let password: String
        if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .loginet) {
            password = primary
        } else if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .loginet) {
            password = primary
        } else {
            password = try RequiredCredential.value(.apiKey, in: credential, providerID: .loginet)
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
            let status = (inv.status ?? "").lowercased()
            if status == "cancelled" || status == "canceled" { continue }
            let amount = inv.total?.value ?? 0
            guard amount != 0 else { continue }
            let currency = inv.currency?.trimmingCharacters(in: .whitespacesAndNewlines)
            try currencies.observe((currency?.isEmpty == false) ? currency! : "EUR", providerID: .loginet)
            let stamp = inv.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? inv.datepaid.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.number ?? inv.id.map(String.init) ?? "invoice"
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
            providerID: .loginet
        )
        return Snapshot(
            providerID: .loginet,
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
            providerID: .loginet
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .loginet) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .loginet)
        return envelope.invoices ?? envelope.invoice ?? envelope.data ?? []
    }

    struct InvoiceList: Decodable, Sendable {
        var invoices: [Invoice]?
        var invoice: [Invoice]?
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: Int?
        var number: String?
        var date: String?
        var datepaid: String?
        var total: FlexibleDecimal?
        var currency: String?
        var status: String?
    }
}
