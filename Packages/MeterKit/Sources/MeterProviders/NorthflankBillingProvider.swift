import Foundation
import MeterCore

/// Northflank 本月已出账发票合计（`total`/`subTotal` 美分，`currency`，`period.start/end` Unix）。
///
/// 文档：`GET https://api.northflank.com/v1/billing/invoices`
/// 可选 team：`GET /v1/teams/{teamId}/billing/invoices`（`accountID` = teamId）。
/// 认证：`Authorization: Bearer <API token>`（需 Organisation > Admin > Billing > Read）。
public struct NorthflankBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.northflank }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .northflank)
        let teamID = credential.value(for: .accountID)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadAllInvoices(teamID: teamID, headers: headers)
        for invoice in invoices {
            try currencies.observe(invoice.currency, providerID: .northflank)
            let cents = invoice.total?.value ?? invoice.subTotal?.value ?? 0
            let amount = cents / 100
            guard amount != 0 else { continue }
            let stamp = Self.periodStamp(invoice: invoice, calendar: calendar) ?? current.start
            let label = invoice.id?.trimmed ?? "invoice"
            if current.contains(stamp) || Self.periodOverlapsCurrent(invoice: invoice, current: current) {
                currentTotal += amount
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

        let converted = try currencies.convert(currentTotal, rates: rateSource.current, providerID: .northflank)
        return Snapshot(
            providerID: .northflank,
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

    private func loadAllInvoices(
        teamID: String?,
        headers: [String: String]
    ) async throws -> [Invoice] {
        var cursor: String?
        var collected: [Invoice] = []
        for _ in 0..<20 {
            let url = Self.listURL(teamID: teamID, cursor: cursor)
            let data = try await ProviderHTTP.get(
                url: url,
                headers: headers,
                client: httpClient,
                providerID: .northflank
            )
            let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .northflank)
            collected.append(contentsOf: envelope.data?.invoices ?? [])
            guard envelope.pagination?.hasNextPage == true,
                  let next = envelope.pagination?.cursor?.trimmed else {
                break
            }
            cursor = next
        }
        return collected
    }

    static func listURL(teamID: String?, cursor: String?) -> URL {
        var query: [URLQueryItem] = [URLQueryItem(name: "per_page", value: "100")]
        if let cursor, !cursor.isEmpty {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let teamID, !teamID.isEmpty {
            return ProviderURL.https(
                host: "api.northflank.com",
                path: "/v1/teams/\(teamID)/billing/invoices",
                query: query
            )
        }
        return ProviderURL.https(
            host: "api.northflank.com",
            path: "/v1/billing/invoices",
            query: query
        )
    }

    static func periodStamp(invoice: Invoice, calendar _: Calendar) -> Date? {
        if let end = invoice.period?.end {
            return Date(timeIntervalSince1970: end)
        }
        if let start = invoice.period?.start {
            return Date(timeIntervalSince1970: start)
        }
        return nil
    }

    static func periodOverlapsCurrent(invoice: Invoice, current: CalendarMonthWindow) -> Bool {
        guard let start = invoice.period?.start, let end = invoice.period?.end else { return false }
        let periodStart = Date(timeIntervalSince1970: start)
        let periodEnd = Date(timeIntervalSince1970: end)
        return periodStart <= current.endInclusive && periodEnd >= current.start
    }

    struct Envelope: Decodable, Sendable {
        var data: DataBlock?
        var pagination: Pagination?
    }

    struct DataBlock: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Pagination: Decodable, Sendable {
        var hasNextPage: Bool?
        var cursor: String?
        var count: FlexibleDecimal?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var period: Period?
        var currency: String?
        var total: FlexibleDecimal?
        var subTotal: FlexibleDecimal?
        var paid: Bool?
    }

    struct Period: Decodable, Sendable {
        var start: Double?
        var end: Double?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
