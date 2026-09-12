import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Melbicom 客户发票（`GET /api/billing/invoices`）。
///
/// 文档：https://docs.api.melbicom.net/
/// 认证：`Authorization: Bearer <token>`。
/// Host：`api01.melbicom.net`。
/// 金额：`total` + `currency`；日期 `date`。
/// **忽略** `/billing/creditbalance` 预付余额。跳过 `Cancelled` / `Refunded`。
/// 凭据：`apiToken`/`apiKey`。
public struct MelbicomBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.melbicom }
    public static let apiHost = "api01.melbicom.net"

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .melbicom) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .melbicom)
        }
        let headers = [
            "Authorization": "Bearer \(token)",
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
            if status == "cancelled" || status == "refunded" { continue }
            let amount = inv.total?.value ?? 0
            guard amount != 0 else { continue }
            let currency = inv.currency?.trimmingCharacters(in: .whitespacesAndNewlines)
            try currencies.observe((currency?.isEmpty == false) ? currency! : "USD", providerID: .melbicom)
            let stamp = inv.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? inv.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.invoicenum ?? inv.id.map(String.init) ?? "invoice"
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
            providerID: .melbicom
        )
        return Snapshot(
            providerID: .melbicom,
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
            providerID: .melbicom
        )
        return try ProviderHTTP.decode([Invoice].self, from: data, providerID: .melbicom)
    }

    static let invoicesURL = ProviderURL.https(
        host: apiHost,
        path: "/api/billing/invoices",
        query: [URLQueryItem(name: "limitnum", value: "100")]
    )

    struct Invoice: Decodable, Sendable {
        var id: Int?
        var invoicenum: String?
        var date: String?
        var createdAt: String?
        var total: FlexibleDecimal?
        var currency: String?
        var status: String?

        enum CodingKeys: String, CodingKey {
            case id, invoicenum, date, total, currency, status
            case createdAt = "created_at"
        }
    }
}
