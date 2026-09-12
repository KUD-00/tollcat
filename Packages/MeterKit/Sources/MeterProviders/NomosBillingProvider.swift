import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Nomos 能源用量发票（`GET /invoices`，`type: usage`）。
///
/// 文档：https://docs.nomos.energy/api-reference/invoices/list-invoices
/// 认证：`POST /oauth/token`（Basic clientID:clientSecret，`grant_type=client_credentials`）→ Bearer。
/// Host：`api.nomos.energy`。
/// 金额：`total` 文档写明 euros (EUR)。跳过 `prepayment` / `void` 与 `voided`。
/// 凭据：`clientID` + `clientSecret`，或直接 `apiToken`。
public struct NomosBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.nomos }
    public static let apiHost = "api.nomos.energy"
    public static let currency = "EUR"
    static let maxPages = 50

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
        let token = try await accessToken(credential: credential)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0
        try currencies.observe(Self.currency, providerID: .nomos)

        var cursor: String?
        var pages = 0
        repeat {
            pages += 1
            let envelope = try await loadInvoices(cursor: cursor, headers: headers)
            for inv in envelope.items ?? [] {
                let type = (inv.type ?? "").lowercased()
                guard type == "usage" else { continue }
                let status = (inv.status ?? "").lowercased()
                if status == "voided" { continue }
                let amount = inv.total?.value ?? 0
                guard amount != 0 else { continue }
                let stamp = Self.stamp(for: inv, current: current, calendar: calendar)
                let label = inv.invoice_number ?? inv.id ?? "invoice"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: "usage",
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
            guard envelope.has_more == true, let next = envelope.next_page, !next.isEmpty else { break }
            cursor = next
        } while pages < Self.maxPages

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .nomos
        )
        return Snapshot(
            providerID: .nomos,
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

    private func accessToken(credential: Credential) async throws -> String {
        if let ready = credential.value(for: .apiToken)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !ready.isEmpty
        {
            return ready
        }
        let clientID = try RequiredCredential.value(.clientID, in: credential, providerID: .nomos)
        let clientSecret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .nomos)
        let basic = ProviderOAuth.basicValue(id: clientID, secret: clientSecret)
        let body = try JSONSerialization.data(withJSONObject: ["grant_type": "client_credentials"])
        let data = try await ProviderHTTP.post(
            url: Self.tokenURL,
            headers: [
                "Authorization": "Basic \(basic)",
                "Content-Type": "application/json",
                "Accept": "application/json",
            ],
            body: body,
            client: httpClient,
            providerID: .nomos
        )
        let token = try ProviderHTTP.decode(TokenResponse.self, from: data, providerID: .nomos)
        guard let access = token.access_token, !access.isEmpty else {
            throw ProviderError.unauthorized(providerID: .nomos)
        }
        return access
    }

    private func loadInvoices(cursor: String?, headers: [String: String]) async throws -> Envelope {
        var query = [
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "filter[type][eq]", value: "usage"),
        ]
        if let cursor, !cursor.isEmpty {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        let data = try await ProviderHTTP.get(
            url: ProviderURL.https(host: Self.apiHost, path: "/invoices", query: query),
            headers: headers,
            client: httpClient,
            providerID: .nomos
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .nomos)
    }

    static let tokenURL = ProviderURL.https(host: apiHost, path: "/oauth/token")

    static func stamp(for inv: Invoice, current: CalendarMonthWindow, calendar: Calendar) -> Date {
        if let year = inv.year?.intValue, let month = inv.month?.intValue,
           (1...12).contains(month),
           let date = calendar.date(from: DateComponents(year: year, month: month, day: 1))
        {
            return date
        }
        return inv.period_start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
            ?? inv.issued_at.flatMap { BillingDateParser.parse($0, calendar: calendar) }
            ?? current.start
    }

    struct TokenResponse: Decodable, Sendable {
        var access_token: String?
    }

    struct Envelope: Decodable, Sendable {
        var items: [Invoice]?
        var next_page: String?
        var has_more: Bool?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var invoice_number: String?
        var type: String?
        var status: String?
        var month: FlexibleDecimal?
        var year: FlexibleDecimal?
        var period_start: String?
        var issued_at: String?
        var total: FlexibleDecimal?
    }
}

private extension FlexibleDecimal {
    var intValue: Int? {
        NSDecimalNumber(decimal: value).intValue
    }
}
