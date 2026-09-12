import Foundation
import MeterCore

/// Mollie 商户手续费发票（`GET /v2/invoices`）。
///
/// 文档：https://docs.mollie.com/reference/list-invoices
/// 认证：`Authorization: Bearer <access_…>`（**Advanced access token**，需 `invoices.read`；
/// 普通 `live_`/`test_` 支付密钥不可用）。
/// Host：`api.mollie.com`。
/// 金额：`grossAmount.value` + `grossAmount.currency`；日期 `issuedAt`（回退行 `period`=`YYYY-MM`）。
/// 凭据：`apiToken`/`apiKey`。
public struct MollieBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.mollie }
    public static let apiHost = "api.mollie.com"
    static let maxPages = 20
    static let pageSize = 250

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .mollie) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .mollie)
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

        var from: String? = nil
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let page = try await loadPage(from: from, headers: headers)
            let batch = page.invoices
            if batch.isEmpty { break }
            for inv in batch {
                let amount = inv.grossAmount?.value?.value ?? inv.netAmount?.value?.value ?? 0
                guard amount != 0 else { continue }
                let currency = inv.grossAmount?.currency ?? inv.netAmount?.currency
                try currencies.observe(currency, providerID: .mollie)
                let stamp = inv.issuedAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.lines?.first?.period.flatMap { Self.parseYearMonth($0, calendar: calendar) }
                    ?? current.start
                let label = inv.reference ?? inv.id ?? "invoice"
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
            guard let next = page.nextFrom, next != from else { break }
            from = next
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .mollie
        )
        return Snapshot(
            providerID: .mollie,
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

    private func loadPage(from: String?, headers: [String: String]) async throws -> Page {
        var query = [URLQueryItem(name: "limit", value: String(Self.pageSize))]
        if let from, !from.isEmpty {
            query.append(URLQueryItem(name: "from", value: from))
        }
        let url = ProviderURL.https(host: Self.apiHost, path: "/v2/invoices", query: query)
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .mollie
        )
        let env = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .mollie)
        let invoices = env._embedded?.invoices ?? env.invoices ?? []
        let nextHref = env._links?.next?.href
        let nextFrom = nextHref.flatMap { Self.fromParam(in: $0) }
        return Page(invoices: invoices, nextFrom: nextFrom)
    }

    static func parseYearMonth(_ raw: String, calendar: Calendar) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: "-")
        guard parts.count >= 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]) else {
            return nil
        }
        return calendar.date(from: DateComponents(year: year, month: month, day: 1))
            .map { calendar.startOfDay(for: $0) }
    }

    static func fromParam(in href: String) -> String? {
        guard let url = URL(string: href),
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            return nil
        }
        return items.first(where: { $0.name == "from" })?.value
    }

    struct Page: Sendable {
        var invoices: [Invoice]
        var nextFrom: String?
    }

    struct Envelope: Decodable, Sendable {
        var _embedded: Embedded?
        var invoices: [Invoice]?
        var _links: Links?
    }

    struct Embedded: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Links: Decodable, Sendable {
        var next: Link?
    }

    struct Link: Decodable, Sendable {
        var href: String?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var reference: String?
        var status: String?
        var issuedAt: String?
        var grossAmount: MoneyAmount?
        var netAmount: MoneyAmount?
        var lines: [Line]?
    }

    struct MoneyAmount: Decodable, Sendable {
        var currency: String?
        var value: FlexibleDecimal?
    }

    struct Line: Decodable, Sendable {
        var period: String?
        var description: String?
    }
}
