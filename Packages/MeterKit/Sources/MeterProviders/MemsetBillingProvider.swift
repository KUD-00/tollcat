import Foundation
import MeterCore

/// Memset 发票用量（`invoice.list` / `invoice.info` → `amount` + ISO `currency`）。
///
/// 文档：https://www.memset.com/apidocs/methods_invoice.html
/// 认证：HTTP Basic（`apiKey` 作 username，password 任意）或 `api_key` 查询参数。
/// Host：`api.memset.com`。JSON：`GET/POST /v1/json/invoice.list`。
/// 金额主单位（GBP/USD/EUR）；跳过 `proforma` 与 `CANCELLED`。
public struct MemsetBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.memset }
    public static let apiHost = "api.memset.com"

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .memset)
        let basic = Data("\(apiKey):x".utf8).base64EncodedString()
        let headers = [
            "Authorization": "Basic \(basic)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let window = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: max(Self.descriptor.historyLookbackMonths, 1),
            now: now,
            calendar: calendar
        )
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let params: [String: String] = [
            "date_gte": Self.apiDate(window.start, calendar: calendar),
            "date_lte": Self.apiDate(window.endInclusive, calendar: calendar),
        ]
        let data = try await call(
            method: "invoice.list",
            parameters: params,
            headers: headers
        )
        let invoices = try decodeInvoices(data)
        for inv in invoices {
            if inv.proforma == true { continue }
            let status = (inv.status ?? "").uppercased()
            if status == "CANCELLED" { continue }
            try currencies.observe(inv.currency, providerID: .memset)
            let amount = inv.amount?.value ?? 0
            guard amount != 0 else { continue }
            let stamp = inv.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                if let items = inv.items, !items.isEmpty {
                    for item in items {
                        let label = item.description ?? item.label ?? "item"
                        let itemAmount = item.amount?.value ?? 0
                        guard itemAmount != 0 else { continue }
                        lines.add(
                            SpendLine(
                                category: "invoice",
                                label: label,
                                amountUSD: Money(usd: itemAmount)
                            )
                        )
                    }
                } else {
                    lines.add(
                        SpendLine(
                            category: "invoice",
                            label: inv.ref.map(String.init) ?? "invoice",
                            amountUSD: Money(usd: amount)
                        )
                    )
                }
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
            providerID: .memset
        )
        return Snapshot(
            providerID: .memset,
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

    private func call(
        method: String,
        parameters: [String: String],
        headers: [String: String]
    ) async throws -> Data {
        let paramsJSON = String(
            data: try JSONSerialization.data(withJSONObject: parameters),
            encoding: .utf8
        ) ?? "{}"
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+")
        let encoded = paramsJSON.addingPercentEncoding(withAllowedCharacters: allowed) ?? paramsJSON
        let body = Data("parameters=\(encoded)".utf8)
        let url = ProviderURL.https(host: Self.apiHost, path: "/v1/json/\(method)")
        return try await ProviderHTTP.post(
            url: url,
            headers: headers.merging(["Content-Type": "application/x-www-form-urlencoded"]) { _, new in new },
            body: body,
            client: httpClient,
            providerID: .memset
        )
    }

    private func decodeInvoices(_ data: Data) throws -> [Invoice] {
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .memset) {
            return list
        }
        if let wrapped = try? ProviderHTTP.decode(ResultWrap.self, from: data, providerID: .memset) {
            return wrapped.result ?? wrapped.invoices ?? []
        }
        throw ProviderError.malformedResponse(providerID: .memset)
    }

    static func apiDate(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d 00:00:00", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    struct ResultWrap: Decodable, Sendable {
        var result: [Invoice]?
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var ref: Int?
        var amount: FlexibleDecimal?
        var currency: String?
        var vat: FlexibleDecimal?
        var status: String?
        var proforma: Bool?
        var payment_method: String?
        var date: String?
        var items: [Item]?
    }

    struct Item: Decodable, Sendable {
        var description: String?
        var label: String?
        var amount: FlexibleDecimal?
        var period: String?

        enum CodingKeys: String, CodingKey {
            case description, label, amount, period
        }
    }
}
