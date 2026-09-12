import Foundation
import MeterCore

/// Stripe 本月手续费。
///
/// 文档：`GET /v1/balance_transactions`
/// 认证：Restricted key，只要 Balance: Read。`fee` 是美分，正数。
/// 只加总 USD 手续费，不是收入，也不做汇率。
public struct StripeBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.stripe }
    public static let maxPages = 50

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar
    /// 厂商用非美元结算时按这张表换。默认只认美元，行为和加它之前一样。
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
        var currency = CurrencyAccumulator()
        let secret = try RequiredCredential.value(.apiKey, in: credential, providerID: .stripe)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let fetchWindow = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let createdGTE = Int(fetchWindow.start.timeIntervalSince1970)
        let createdLT = Int(now.timeIntervalSince1970)
        var daily = DailySpendAccumulator()
        var startingAfter: String?
        var pages = 0
        var previousLast: String?

        while pages < Self.maxPages {
            pages += 1
            let url = Self.listURL(
                createdGTE: createdGTE,
                createdLT: createdLT,
                startingAfter: startingAfter
            )
            let data = try await ProviderHTTP.get(
                url: url,
                headers: [
                    "Authorization": "Bearer \(secret)",
                ],
                client: httpClient,
                providerID: .stripe
            )
            let page = try ProviderHTTP.decode(Page.self, from: data, providerID: .stripe)
            for item in page.data ?? [] {
                let cents = item.fee ?? 0
                if cents != 0 {
                    try currency.observe(item.currency, providerID: .stripe)
                }
                let day = item.created.map { BillingDateParser.parseUnixSeconds($0, calendar: calendar) }
                    ?? window.start
                daily.add(day: day, amount: Self.money(fromCents: cents))
            }

            let lastID = page.data?.last?.id
            switch Self.nextPage(
                hasMore: page.has_more ?? false,
                lastID: lastID,
                previousLast: previousLast,
                pages: pages
            ) {
            case .done:
                return try snapshot(window: window, daily: daily, currency: currency)
            case .more(let next):
                previousLast = lastID
                startingAfter = next
            case .truncated:
                throw ProviderError.malformedResponse(providerID: .stripe)
            }
        }

        throw ProviderError.malformedResponse(providerID: .stripe)
    }

    static func listURL(createdGTE: Int, createdLT: Int, startingAfter: String?) -> URL {
        var items = [
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "created[gte]", value: String(createdGTE)),
            URLQueryItem(name: "created[lt]", value: String(createdLT)),
        ]
        if let startingAfter, !startingAfter.isEmpty {
            items.append(URLQueryItem(name: "starting_after", value: startingAfter))
        }
        return ProviderURL.https(host: "api.stripe.com", path: "/v1/balance_transactions", query: items)
    }

    static func money(fromCents cents: Int64) -> Money {
        Money(usd: Decimal(cents) / 100)
    }

    enum PageAdvance: Equatable {
        case done
        case more(String)
        case truncated
    }

    static func nextPage(
        hasMore: Bool,
        lastID: String?,
        previousLast: String?,
        pages: Int
    ) -> PageAdvance {
        guard hasMore, let lastID, lastID != previousLast else { return .done }
        if pages >= maxPages { return .truncated }
        return .more(lastID)
    }

    private func snapshot(
        window: CalendarMonthWindow,
        daily: DailySpendAccumulator,
        currency: CurrencyAccumulator
    ) throws -> Snapshot {
        let now = now()
        return try Snapshot(
            providerID: .stripe,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: daily.total(in: window, calendar: calendar),
            dailyUSD: daily.snapshotDaily
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    struct Page: Decodable, Sendable {
        var data: [Item]?
        var has_more: Bool?
    }

    struct Item: Decodable, Sendable {
        var id: String?
        var fee: Int64?
        var currency: String?
        var created: Int?
    }
}
