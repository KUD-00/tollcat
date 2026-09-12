import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Fiskil 能源发票（`GET /v1/energy/invoice`，文档亦记 `/v1/invoices`）。
///
/// 文档：https://docs.fiskil.com/data-api/api-reference/getEnergyInvoices
/// 认证：`POST /v1/token`（`client_id` + `client_secret`）→ Bearer `token`；或直接 `apiToken`。
/// Host：`api.fiskil.com`。
/// 金额：`total_amount` + `currency`（常见 AUD）。
/// 凭据：`clientID` + `clientSecret`，`accountID` = `end_user_id`。
public struct FiskilBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.fiskil }
    public static let apiHost = "api.fiskil.com"
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
        let token = try await accessToken(credential: credential)
        let endUser = try RequiredCredential.value(.accountID, in: credential, providerID: .fiskil)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var cursor: String?
        var pages = 0
        repeat {
            pages += 1
            let envelope = try await loadInvoices(endUser: endUser, cursor: cursor, headers: headers)
            for inv in envelope.items {
                let amount = inv.total_amount?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(inv.currency ?? "AUD", providerID: .fiskil)
                let stamp = inv.issue_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.period_end.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.period_start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.due_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = inv.invoice_number ?? inv.id ?? "invoice"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: inv.status ?? "invoice",
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
            guard let next = envelope.nextCursor, !next.isEmpty else { break }
            cursor = next
        } while pages < Self.maxPages

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .fiskil
        )
        return Snapshot(
            providerID: .fiskil,
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
        let clientID = try RequiredCredential.value(.clientID, in: credential, providerID: .fiskil)
        let clientSecret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .fiskil)
        let body = try JSONSerialization.data(
            withJSONObject: [
                "client_id": clientID,
                "client_secret": clientSecret,
            ]
        )
        let data = try await ProviderHTTP.post(
            url: Self.tokenURL,
            headers: [
                "Content-Type": "application/json",
                "Accept": "application/json",
            ],
            body: body,
            client: httpClient,
            providerID: .fiskil
        )
        let token = try ProviderHTTP.decode(TokenResponse.self, from: data, providerID: .fiskil)
        guard let access = token.token ?? token.access_token, !access.isEmpty else {
            throw ProviderError.unauthorized(providerID: .fiskil)
        }
        return access
    }

    private func loadInvoices(
        endUser: String,
        cursor: String?,
        headers: [String: String]
    ) async throws -> Loaded {
        var query = [
            URLQueryItem(name: "end_user_id", value: endUser),
            URLQueryItem(name: "page[size]", value: "100"),
        ]
        if let cursor, !cursor.isEmpty {
            query.append(URLQueryItem(name: "page[after]", value: cursor))
        }
        let data = try await ProviderHTTP.get(
            url: ProviderURL.https(host: Self.apiHost, path: "/v1/energy/invoice", query: query),
            headers: headers,
            client: httpClient,
            providerID: .fiskil
        )
        if let env = try? ProviderHTTP.decode(Envelope.self, from: data, providerID: .fiskil) {
            let items = env.invoices ?? env.data ?? []
            let next = env.links?.next
                ?? env.meta?.next_cursor
                ?? env.next_page
            return Loaded(items: items, nextCursor: next)
        }
        let list = try ProviderHTTP.decode([Invoice].self, from: data, providerID: .fiskil)
        return Loaded(items: list, nextCursor: nil)
    }

    static let tokenURL = ProviderURL.https(host: apiHost, path: "/v1/token")

    struct TokenResponse: Decodable, Sendable {
        var token: String?
        var access_token: String?
    }

    struct Loaded: Sendable {
        var items: [Invoice]
        var nextCursor: String?
    }

    struct Envelope: Decodable, Sendable {
        var invoices: [Invoice]?
        var data: [Invoice]?
        var links: Links?
        var meta: Meta?
        var next_page: String?
    }

    struct Links: Decodable, Sendable {
        var next: String?
    }

    struct Meta: Decodable, Sendable {
        var next_cursor: String?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var account_id: String?
        var invoice_number: String?
        var issue_date: String?
        var due_date: String?
        var period_start: String?
        var period_end: String?
        var total_amount: FlexibleDecimal?
        var currency: String?
        var status: String?
    }
}
