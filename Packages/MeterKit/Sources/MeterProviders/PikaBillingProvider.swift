import Foundation
import MeterCore

/// Pika 本周期用量花费（优先 `GET /billing/spend/daily`，micro-USD）。
///
/// OpenAPI：https://dev.pika.art/openapi.json
/// 认证：Bearer API key。Host：`api.dev.pika.art`。
/// `results[].amount_micro_usd` ÷ 1_000_000；可选 `/billing/balance` 的 `postpaid.cycle.used_micro_usd` 作补充（不优先 prepaid `balance_micro_usd`）。
public struct PikaBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.pika }
    public static let apiHost = "api.dev.pika.art"
    static let microPerUSD: Decimal = 1_000_000

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
        let auth: String
        if let token = credential.value(for: .apiToken)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !token.isEmpty {
            auth = token
        } else {
            auth = try RequiredCredential.value(.apiKey, in: credential, providerID: .pika)
        }
        let headers = [
            "Authorization": "Bearer \(auth)",
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
        try currencies.observe("USD", providerID: .pika)
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()

        let spendURL = ProviderURL.https(
            host: Self.apiHost,
            path: "/billing/spend/daily",
            query: [
                URLQueryItem(name: "start_date", value: Self.day(window.start, calendar: calendar)),
                URLQueryItem(name: "end_date", value: Self.day(window.endInclusive, calendar: calendar)),
            ]
        )
        let data = try await ProviderHTTP.get(
            url: spendURL, headers: headers, client: httpClient, providerID: .pika
        )
        let payload = try ProviderHTTP.decode(SpendDaily.self, from: data, providerID: .pika)
        for row in payload.results ?? [] {
            let usd = Decimal(row.amount_micro_usd ?? 0) / Self.microPerUSD
            guard usd != 0 else { continue }
            let day = row.date.flatMap { BillingDateParser.parse($0, calendar: calendar) } ?? current.start
            daily.add(day: day, amount: Money(usd: usd))
            if current.contains(day) {
                let label = [row.model, row.api_key_id, row.date]
                    .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .first { !$0.isEmpty } ?? "spend"
                lines.add(
                    SpendLine(
                        category: row.model ?? "spend",
                        label: label,
                        amountUSD: Money(usd: usd)
                    )
                )
            }
        }

        var currentTotal = daily.total(in: current, calendar: calendar).usd

        // Optional postpaid cycle used — never use prepaid balance as spend.
        if let balData = try? await ProviderHTTP.get(
            url: ProviderURL.https(host: Self.apiHost, path: "/billing/balance"),
            headers: headers,
            client: httpClient,
            providerID: .pika
        ), let bal = try? ProviderHTTP.decode(Balance.self, from: balData, providerID: .pika),
           bal.postpaid?.active == true,
           let usedMicro = bal.postpaid?.cycle?.used_micro_usd {
            let usedUSD = Decimal(usedMicro) / Self.microPerUSD
            if currentTotal == 0, usedUSD != 0 {
                currentTotal = usedUSD
                daily.add(day: current.start, amount: Money(usd: usedUSD))
            }
        }

        return try Snapshot(
            providerID: .pika,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily ?? [:],
            lines: lines.snapshot
        ).convertedToUSD(using: currencies, rates: rateSource.current)
    }

    static func day(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    struct SpendDaily: Decodable, Sendable {
        var results: [Item]?
        var unit: String?
        var currency: String?
    }

    struct Item: Decodable, Sendable {
        var date: String?
        var api_key_id: String?
        var model: String?
        var amount_micro_usd: Int64?
        var request_count: Int64?
    }

    struct Balance: Decodable, Sendable {
        var balance_micro_usd: Int64?
        var postpaid: Postpaid?
    }

    struct Postpaid: Decodable, Sendable {
        var active: Bool?
        var cycle: Cycle?
    }

    struct Cycle: Decodable, Sendable {
        var used_micro_usd: Int64?
        var limit_micro_usd: Int64?
        var remaining_micro_usd: Int64?
    }
}
