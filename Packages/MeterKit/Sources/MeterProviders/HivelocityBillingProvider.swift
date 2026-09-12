import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Hivelocity 客户发票（`GET /api/v2/invoice/`）。
///
/// 文档：https://developers.hivelocity.net/docs/billing
/// 认证：`X-API-KEY`。
/// Host：`core.hivelocity.net`。
/// 金额：`amount`（USD）；日期 `created`（unix 秒）。
/// **忽略** `/invoice/unpaid` 未付合计与 `/credit` 账户 credit。
/// 跳过 Cancelled / Void。凭据：`apiKey`/`apiToken`。
public struct HivelocityBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.hivelocity }
    public static let apiHost = "core.hivelocity.net"
    public static let invoicesURL = ProviderURL.https(host: apiHost, path: "/api/v2/invoice/")

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
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .hivelocity) {
            key = primary
        } else {
            key = try RequiredCredential.value(.apiToken, in: credential, providerID: .hivelocity)
        }
        let headers = [
            "X-API-KEY": key,
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
            if status == "cancelled" || status == "canceled" || status == "void" { continue }
            let amount = inv.amount?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe("USD", providerID: .hivelocity)
            let stamp: Date
            if let created = inv.created {
                stamp = Date(timeIntervalSince1970: TimeInterval(created))
            } else if let sent = inv.sent {
                stamp = Date(timeIntervalSince1970: TimeInterval(sent))
            } else {
                stamp = current.start
            }
            let label = inv.id.map(String.init) ?? "invoice"
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
            providerID: .hivelocity
        )
        return Snapshot(
            providerID: .hivelocity,
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
            providerID: .hivelocity
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .hivelocity) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .hivelocity)
        return envelope.items ?? envelope.invoices ?? envelope.data ?? []
    }

    struct InvoiceList: Decodable, Sendable {
        var items: [Invoice]?
        var invoices: [Invoice]?
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: Int?
        var amount: FlexibleDecimal?
        var amountUnpaid: FlexibleDecimal?
        var status: String?
        var created: Int?
        var sent: Int?
        var due: Int?
        var datePaid: Int?
    }
}
