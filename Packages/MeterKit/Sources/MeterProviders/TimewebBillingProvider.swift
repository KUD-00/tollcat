import Foundation
import MeterCore

/// Timeweb Cloud 本周期费用（`GET /api/v1/account/finances`）。
///
/// 文档：https://timeweb.cloud/api-docs · SDK `getFinances`
/// 认证：`Authorization: Bearer`（API token）。Host：`api.timeweb.cloud`。
/// 金额：`finances.monthly_cost` + `finances.currency`（主币；本月服务费用估算）。
/// 另有 `hourly_cost` / `balance`——本适配器用月费用做 period usage，不读余额预付。
public struct TimewebBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.timeweb }
    public static let apiHost = "api.timeweb.cloud"

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .timeweb) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .timeweb)
        }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()

        let envelope = try await loadFinances(headers: headers)
        let finances = envelope.finances
        let amount = finances?.monthly_cost?.value ?? 0
        try currencies.observe(finances?.currency, providerID: .timeweb)
        if amount != 0 {
            daily.add(day: current.start, amount: Money(usd: amount))
            lines.add(
                SpendLine(
                    category: "monthly_cost",
                    label: "monthly_cost",
                    amountUSD: Money(usd: amount)
                )
            )
        }
        // No historical invoice list on this endpoint.
        _ = horizon

        let converted = try currencies.convert(
            amount,
            rates: rateSource.current,
            providerID: .timeweb
        )
        return Snapshot(
            providerID: .timeweb,
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

    private func loadFinances(headers: [String: String]) async throws -> Envelope {
        let data = try await ProviderHTTP.get(
            url: Self.financesURL,
            headers: headers,
            client: httpClient,
            providerID: .timeweb
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .timeweb)
    }

    static var financesURL: URL {
        ProviderURL.https(host: apiHost, path: "/api/v1/account/finances")
    }

    struct Envelope: Decodable, Sendable {
        var finances: Finances?
    }

    struct Finances: Decodable, Sendable {
        var balance: FlexibleDecimal?
        var currency: String?
        var hourly_cost: FlexibleDecimal?
        var monthly_cost: FlexibleDecimal?
    }
}
