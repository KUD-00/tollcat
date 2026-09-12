import Foundation
import MeterCore

/// VPS.NET 发票列表（`GET /invoices.api10json`）。
///
/// 文档：https://control.vps.net/api/
/// 认证：HTTP Basic（`email` + `apiKey`/`apiToken`）。Host：`api.vps.net`。
/// 金额：`invoice.amount` + `invoice.currency`；日期：`date_sent`。
/// 忽略 `get_credits` 预付余额接口。
public struct VPSNetBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.vpsnet }
    public static let apiHost = "api.vps.net"

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
        let email = try RequiredCredential.value(.email, in: credential, providerID: .vpsnet)
        let token: String
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .vpsnet) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiToken, in: credential, providerID: .vpsnet)
        }
        let basic = ProviderOAuth.basicValue(id: email, secret: token)
        let headers = [
            "Authorization": "Basic \(basic)",
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL,
            headers: headers,
            client: httpClient,
            providerID: .vpsnet
        )
        let rows = try decodeInvoices(data)
        for row in rows {
            let amount = row.amount?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe(row.currency, providerID: .vpsnet)
            let stamp = row.date_sent.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = row.invoice_no ?? "invoice"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: row.status ?? "invoice",
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
            providerID: .vpsnet
        )
        return Snapshot(
            providerID: .vpsnet,
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

    static let invoicesURL: URL = ProviderURL.https(
        host: apiHost,
        path: "/invoices.api10json"
    )

    private func decodeInvoices(_ data: Data) throws -> [Invoice] {
        if let wrapped = try? ProviderHTTP.decode([InvoiceEnvelope].self, from: data, providerID: .vpsnet) {
            return wrapped.compactMap(\.invoice)
        }
        return try ProviderHTTP.decode([Invoice].self, from: data, providerID: .vpsnet)
    }

    struct InvoiceEnvelope: Decodable, Sendable {
        var invoice: Invoice?
    }

    struct Invoice: Decodable, Sendable {
        var date_sent: String?
        var date_due: String?
        var amount: FlexibleDecimal?
        var currency: String?
        var status: String?
        var invoice_no: String?
    }
}
