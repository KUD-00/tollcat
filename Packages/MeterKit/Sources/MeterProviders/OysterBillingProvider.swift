import Foundation
import MeterCore

/// Oyster HR 平台费发票（`GET /v1/invoices`；`amount.decimal` + `amount.currencyCode`）。
///
/// 文档：https://docs.oysterhr.com/docs/invoicing-at-oyster
/// 认证：`Authorization: Bearer <token>`。
/// 优先 `SCALE` / `CONTRACTOR_FEES`（平台费）；跳过工资 Prefunding/Settlement 等过账。
public struct OysterBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.oyster }
    public static let apiHost = "api.oysterhr.com"
    static let pageSize = 50
    static let maxPages = 40

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
        let token = try RequiredCredential.value(.apiKey, in: credential, providerID: .oyster)
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
        for invoice in invoices {
            let status = (invoice.status ?? "").uppercased()
            if Self.skipStatuses.contains(status) { continue }
            let type = (invoice.type ?? "").uppercased()
            guard Self.feeTypes.contains(type) else { continue }
            let currency = invoice.amount?.currencyCode?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            try currencies.observe(currency, providerID: .oyster)
            let amount = invoice.amount?.decimal?.value
                ?? Self.parseDecimal(invoice.amount?.decimalString)
                ?? 0
            guard amount != 0 else { continue }
            let stamp = invoice.issueDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = invoice.referenceCode
                ?? invoice.id
                ?? type

            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: type.lowercased(),
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
            providerID: .oyster
        )
        return Snapshot(
            providerID: .oyster,
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

    static let feeTypes: Set<String> = [
        "SCALE",
        "CONTRACTOR_FEES",
    ]

    static let skipStatuses: Set<String> = [
        "VOIDED", "DISPUTED",
    ]

    static func parseDecimal(_ raw: String?) -> Decimal? {
        guard let raw, !raw.isEmpty else { return nil }
        return Decimal(string: raw.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func loadInvoices(headers: [String: String]) async throws -> [Invoice] {
        var all: [Invoice] = []
        var page = 1
        for _ in 0..<Self.maxPages {
            var query: [URLQueryItem] = [
                URLQueryItem(name: "per_page", value: String(Self.pageSize)),
                URLQueryItem(name: "page", value: String(page)),
            ]
            // Prefer fee types when API accepts repeated types[] filters.
            for t in ["SCALE", "CONTRACTOR_FEES"] {
                query.append(URLQueryItem(name: "types[]", value: t))
            }
            let url = ProviderURL.https(
                host: Self.apiHost,
                path: "/v1/invoices",
                query: query
            )
            let data = try await ProviderHTTP.get(
                url: url,
                headers: headers,
                client: httpClient,
                providerID: .oyster
            )
            let payload = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .oyster)
            let rows = payload.data ?? []
            all.append(contentsOf: rows)
            if rows.isEmpty || rows.count < Self.pageSize { break }
            page += 1
        }
        return all
    }

    struct InvoiceList: Decodable, Sendable {
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var referenceCode: String?
        var type: String?
        var status: String?
        var issueDate: String?
        var amount: MoneyAmount?
    }

    struct MoneyAmount: Decodable, Sendable {
        var currencyCode: String?
        var decimal: FlexibleDecimal?
        var decimalString: String?

        enum CodingKeys: String, CodingKey {
            case currencyCode, decimal
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            currencyCode = try c.decodeIfPresent(String.self, forKey: .currencyCode)
            if let fd = try? c.decodeIfPresent(FlexibleDecimal.self, forKey: .decimal) {
                decimal = fd
                decimalString = nil
            } else if let s = try? c.decodeIfPresent(String.self, forKey: .decimal) {
                decimal = nil
                decimalString = s
            } else {
                decimal = nil
                decimalString = nil
            }
        }
    }
}
