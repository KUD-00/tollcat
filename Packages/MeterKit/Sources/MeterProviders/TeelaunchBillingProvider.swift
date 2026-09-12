import Foundation
import MeterCore

/// teelaunch 本月支付历史合计（`GET /api/v1/account/payment-history`）。
///
/// 文档：https://api.teelaunch.com/documentation
/// 认证：`Authorization: Bearer <JWT>`。
/// Host：`api.teelaunch.com`。
/// 金额：`amount`（回退 `totalCost`）；日期 `createdAt`；币种默认 USD。
/// 凭据：`apiKey` / `apiToken`。
public struct TeelaunchBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.teelaunch }
    public static let apiHost = "api.teelaunch.com"
    static let maxPages = 20
    static let pageSize = 50

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .teelaunch) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .teelaunch)
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

        var page = 1
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let env = try await loadPage(page: page, headers: headers)
            let batch = env.items
            if batch.isEmpty { break }
            var sawOlder = false
            for payment in batch {
                let amount = payment.amount?.value ?? payment.totalCost?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(payment.currency ?? "USD", providerID: .teelaunch)
                let stamp = payment.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                if stamp < current.start, horizon == .currentMonth {
                    sawOlder = true
                }
                let label = payment.id.map { "\($0.value)" } ?? "payment"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: payment.status.map { "\($0.value)" } ?? "payment",
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
            let lastPage = env.lastPage ?? page
            if page >= lastPage || batch.count < Self.pageSize || sawOlder { break }
            page += 1
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .teelaunch
        )
        return Snapshot(
            providerID: .teelaunch,
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

    private func loadPage(page: Int, headers: [String: String]) async throws -> Page {
        let url = ProviderURL.https(
            host: Self.apiHost,
            path: "/api/v1/account/payment-history",
            query: [
                URLQueryItem(name: "limit", value: String(Self.pageSize)),
                URLQueryItem(name: "page", value: String(page)),
            ]
        )
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .teelaunch
        )
        let env = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .teelaunch)
        let items = env.data ?? env.payments ?? []
        let lastPage = env.meta?.lastPage ?? env.lastPage
        return Page(items: items, lastPage: lastPage)
    }

    struct Page: Sendable {
        var items: [Payment]
        var lastPage: Int?
    }

    struct Envelope: Decodable, Sendable {
        var data: [Payment]?
        var payments: [Payment]?
        var meta: Meta?
        var lastPage: Int?

        enum CodingKeys: String, CodingKey {
            case data, payments, meta
            case lastPage = "last_page"
        }
    }

    struct Meta: Decodable, Sendable {
        var lastPage: Int?
        enum CodingKeys: String, CodingKey {
            case lastPage = "last_page"
        }
    }

    struct Payment: Decodable, Sendable {
        var id: FlexibleDecimal?
        var amount: FlexibleDecimal?
        var totalCost: FlexibleDecimal?
        var currency: String?
        var status: FlexibleDecimal?
        var createdAt: String?

        enum CodingKeys: String, CodingKey {
            case id, amount, currency, status
            case totalCost = "totalCost"
            case createdAt = "createdAt"
        }
    }
}
