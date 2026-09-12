import Foundation
import MeterCore

/// Cloudheed 本周期用量费用（`GET /v1/billing/usage`）。
///
/// 文档：https://docs.cloudheed.com/billing
/// 认证：`Authorization: Bearer`。Host：`api.cloudheed.com`。
/// 金额：`total` + `currency`（主币）；`period.start`/`period.end` 界定窗口。
/// 另有 `GET /v1/billing/invoices`（amount，invoice 行未给 currency）——本适配器用 usage 端点，币种更清晰。
public struct CloudheedBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.cloudheed }
    public static let apiHost = "api.cloudheed.com"

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .cloudheed) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .cloudheed)
        }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()

        let envelope = try await loadUsage(headers: headers)
        let amount = envelope.total?.value ?? 0
        try currencies.observe(envelope.currency, providerID: .cloudheed)
        let stamp = envelope.period?.start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
            ?? current.start
        if amount != 0 {
            daily.add(day: stamp, amount: Money(usd: amount))
            lines.add(
                SpendLine(
                    category: "usage",
                    label: "total",
                    amountUSD: Money(usd: amount)
                )
            )
        }
        // Usage endpoint is current-period only; invoice list lacks currency.
        _ = horizon

        let periodStart = stamp
        let periodEnd = envelope.period?.end.flatMap { BillingDateParser.parse($0, calendar: calendar) }
            ?? current.endInclusive

        let converted = try currencies.convert(
            amount,
            rates: rateSource.current,
            providerID: .cloudheed
        )
        return Snapshot(
            providerID: .cloudheed,
            kind: .usage,
            fetchedAt: now,
            periodStart: periodStart,
            periodEnd: periodEnd,
            currentSpendUSD: converted.money,
            dailyUSD: currencies.scaled(daily.snapshotDaily, by: converted.usdPerUnit),
            converted: currencies.needsConversionNote ? converted : nil,
            lines: lines.snapshot
        )
    }

    private func loadUsage(headers: [String: String]) async throws -> Envelope {
        let data = try await ProviderHTTP.get(
            url: Self.usageURL,
            headers: headers,
            client: httpClient,
            providerID: .cloudheed
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .cloudheed)
    }

    static var usageURL: URL {
        ProviderURL.https(host: apiHost, path: "/v1/billing/usage")
    }

    struct Envelope: Decodable, Sendable {
        var period: Period?
        var total: FlexibleDecimal?
        var currency: String?
    }

    struct Period: Decodable, Sendable {
        var start: String?
        var end: String?
    }
}
