import Foundation
import MeterCore

/// IDCloudHost 账单发票（`GET /v1/payment/invoice/list?billing_account_id=`）。
///
/// 文档：https://api.idcloudhost.com/
/// 认证：`apikey` 头；`accountID` = billing_account_id。
/// Host：`api.idcloudhost.com`。
/// 金额：`totals.total`（主币种，缺省 IDR）；日期：`period_start`（unix 秒）或 `created`。
/// **忽略** `GET /v1/payment/credit/list` 与账户 `credit_amount`（预付余额）。
public struct IDCloudHostBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.idcloudhost }
    public static let apiHost = "api.idcloudhost.com"
    public static let defaultCurrency = "IDR"

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
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .idcloudhost) {
            key = primary
        } else {
            key = try RequiredCredential.value(.apiToken, in: credential, providerID: .idcloudhost)
        }
        let billingAccountID = try RequiredCredential.value(.accountID, in: credential, providerID: .idcloudhost)
        let headers = [
            "apikey": key,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadInvoices(billingAccountID: billingAccountID, headers: headers)
        for inv in invoices {
            let amount = inv.totals?.total?.value ?? 0
            guard amount != 0 else { continue }
            let currency = inv.currency?.trimmingCharacters(in: .whitespacesAndNewlines)
            try currencies.observe(
                (currency?.isEmpty == false) ? currency! : Self.defaultCurrency,
                providerID: .idcloudhost
            )
            let stamp: Date
            if let unix = inv.period_start?.value {
                stamp = Date(timeIntervalSince1970: NSDecimalNumber(decimal: unix).doubleValue)
            } else if let unix = inv.created?.value {
                stamp = Date(timeIntervalSince1970: NSDecimalNumber(decimal: unix).doubleValue)
            } else {
                stamp = current.start
            }
            let label = inv.padded_id ?? inv.id.map(String.init) ?? "invoice"
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
            providerID: .idcloudhost
        )
        return Snapshot(
            providerID: .idcloudhost,
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
        billingAccountID: String,
        headers: [String: String]
    ) async throws -> [Invoice] {
        let url = ProviderURL.https(
            host: Self.apiHost,
            path: "/v1/payment/invoice/list",
            query: [URLQueryItem(name: "billing_account_id", value: billingAccountID)]
        )
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .idcloudhost
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .idcloudhost) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .idcloudhost)
        return envelope.data ?? envelope.invoices ?? []
    }

    static var invoicesListURL: URL {
        ProviderURL.https(host: apiHost, path: "/v1/payment/invoice/list")
    }

    struct InvoiceList: Decodable, Sendable {
        var data: [Invoice]?
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: Int?
        var padded_id: String?
        var currency: String?
        var period_start: FlexibleDecimal?
        var period_end: FlexibleDecimal?
        var created: FlexibleDecimal?
        var status: FlexibleDecimal?
        var totals: Totals?
    }

    struct Totals: Decodable, Sendable {
        var total: FlexibleDecimal?
        var subtotal: FlexibleDecimal?
        var vat_tax: FlexibleDecimal?
    }
}
