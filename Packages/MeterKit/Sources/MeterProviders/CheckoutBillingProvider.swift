import Foundation
import MeterCore

/// Checkout.com 商户手续费（`GET /reporting/statements?include=payout_breakdown`）。
///
/// 文档：https://checkoutdocs.readme.io/docs/statements-endpoint
/// 认证：`Authorization: Bearer <sk_…>`（secret key）。
/// Host：`api.checkout.com`。
/// 金额：取 `current_period_breakdown.processing_fees`、`payout_fee`、`admin_fees`、`tax`
/// 的绝对值之和（对账单里手续费常为负数）；币种 `payouts[].currency`；
/// 日期优先 `payouts[].date` / `period_start`，回退 statement `date`。
/// 凭据：`apiKey`。
public struct CheckoutBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.checkout }
    public static let apiHost = "api.checkout.com"
    static let maxPages = 20
    static let pageLimit = 50

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
        let secret = try RequiredCredential.value(.apiKey, in: credential, providerID: .checkout)
        let headers = [
            "Authorization": "Bearer \(secret)",
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let fetchWindow = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var skip = 0
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let page = try await loadPage(
                from: fetchWindow.start,
                to: current.nextStart,
                skip: skip,
                headers: headers
            )
            let batch = page.data
            if batch.isEmpty { break }
            for statement in batch {
                let statementStamp = statement.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? statement.periodStart.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let payouts = statement.payouts ?? []
                if payouts.isEmpty {
                    continue
                }
                for payout in payouts {
                    let amount = Self.feeTotal(payout: payout)
                    guard amount != 0 else { continue }
                    try currencies.observe(payout.currency, providerID: .checkout)
                    let stamp = payout.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                        ?? payout.periodStart.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                        ?? statementStamp
                    let label = payout.id ?? statement.id ?? "statement"
                    if current.contains(stamp) {
                        currentTotal += amount
                        daily.add(day: stamp, amount: Money(usd: amount))
                        lines.add(
                            SpendLine(
                                category: "processing_fees",
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
            }
            if batch.count < Self.pageLimit { break }
            skip += batch.count
            if let nextSkip = page.nextSkip, nextSkip == skip {
                break
            }
            if let nextSkip = page.nextSkip {
                skip = nextSkip
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .checkout
        )
        return Snapshot(
            providerID: .checkout,
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

    private func loadPage(
        from: Date,
        to: Date,
        skip: Int,
        headers: [String: String]
    ) async throws -> Page {
        let fromISO = Self.iso8601(from)
        let toISO = Self.iso8601(to)
        var query = [
            URLQueryItem(name: "from", value: fromISO),
            URLQueryItem(name: "to", value: toISO),
            URLQueryItem(name: "include", value: "payout_breakdown"),
            URLQueryItem(name: "limit", value: String(Self.pageLimit)),
        ]
        if skip > 0 {
            query.append(URLQueryItem(name: "skip", value: String(skip)))
        }
        let url = ProviderURL.https(host: Self.apiHost, path: "/reporting/statements", query: query)
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .checkout
        )
        let env = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .checkout)
        let nextHref = env._links?.next?.href
        let nextSkip = nextHref.flatMap { Self.skipParam(in: $0) }
        return Page(data: env.data ?? [], nextSkip: nextSkip)
    }

    static func feeTotal(payout: Payout) -> Decimal {
        var total: Decimal = 0
        if let fee = payout.payoutFee?.value {
            total += abs(fee)
        }
        if let breakdown = payout.currentPeriodBreakdown {
            if let fees = breakdown.processingFees?.value {
                total += abs(fees)
            }
            if let admin = breakdown.adminFees?.value {
                total += abs(admin)
            }
            if let tax = breakdown.tax?.value {
                total += abs(tax)
            }
        }
        return total
    }

    static func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    static func skipParam(in href: String) -> Int? {
        guard let url = URL(string: href),
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let raw = items.first(where: { $0.name == "skip" })?.value,
              let value = Int(raw) else {
            return nil
        }
        return value
    }

    struct Page: Sendable {
        var data: [Statement]
        var nextSkip: Int?
    }

    struct Envelope: Decodable, Sendable {
        var data: [Statement]?
        var _links: Links?
    }

    struct Links: Decodable, Sendable {
        var next: Link?
    }

    struct Link: Decodable, Sendable {
        var href: String?
    }

    struct Statement: Decodable, Sendable {
        var id: String?
        var periodStart: String?
        var periodEnd: String?
        var date: String?
        var payouts: [Payout]?

        enum CodingKeys: String, CodingKey {
            case id, date, payouts
            case periodStart = "period_start"
            case periodEnd = "period_end"
        }
    }

    struct Payout: Decodable, Sendable {
        var id: String?
        var currency: String?
        var date: String?
        var periodStart: String?
        var payoutFee: FlexibleDecimal?
        var currentPeriodBreakdown: Breakdown?

        enum CodingKeys: String, CodingKey {
            case id, currency, date
            case periodStart = "period_start"
            case payoutFee = "payout_fee"
            case currentPeriodBreakdown = "current_period_breakdown"
        }
    }

    struct Breakdown: Decodable, Sendable {
        var processingFees: FlexibleDecimal?
        var adminFees: FlexibleDecimal?
        var tax: FlexibleDecimal?

        enum CodingKeys: String, CodingKey {
            case processingFees = "processing_fees"
            case adminFees = "admin_fees"
            case tax
        }
    }
}
