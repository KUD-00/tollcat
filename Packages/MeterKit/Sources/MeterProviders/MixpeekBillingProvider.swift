import Foundation
import MeterCore

/// Mixpeek 组织当期花费（`GET /v1/organizations/billing/spending-caps`）。
///
/// 文档：https://docs.mixpeek.com/ · OpenAPI `https://api.mixpeek.com/docs/openapi.json`
/// 认证：`Authorization: Bearer mxp_sk_…`。Host：`api.mixpeek.com`。
/// 金额：`current_spending_usd`（当期账单周期 USD）；忽略 `/billing/balance` 预付额度。
/// 凭据：`apiToken`/`apiKey`。
public struct MixpeekBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.mixpeek }
    public static let apiHost = "api.mixpeek.com"

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
        _ = horizon
        let token: String
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .mixpeek) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .mixpeek)
        }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: Self.spendingCapsURL,
            headers: headers,
            client: httpClient,
            providerID: .mixpeek
        )
        let envelope = try ProviderHTTP.decode(SpendingCaps.self, from: data, providerID: .mixpeek)
        guard let usd = envelope.current_spending_usd?.value else {
            throw ProviderError.malformedResponse(providerID: .mixpeek)
        }
        var currencies = CurrencyAccumulator()
        try currencies.observe("USD", providerID: .mixpeek)
        var lines = SpendLineAccumulator()
        if usd != 0 {
            lines.add(
                SpendLine(
                    category: "usage",
                    label: "current_spending",
                    amountUSD: Money(usd: usd)
                )
            )
        }
        let converted = try currencies.convert(
            usd,
            rates: rateSource.current,
            providerID: .mixpeek
        )
        return Snapshot(
            providerID: .mixpeek,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: converted.money,
            dailyUSD: [:],
            converted: currencies.needsConversionNote ? converted : nil,
            lines: lines.snapshot
        )
    }

    static let spendingCapsURL = ProviderURL.https(
        host: apiHost,
        path: "/v1/organizations/billing/spending-caps"
    )

    struct SpendingCaps: Decodable, Sendable {
        var current_spending_usd: FlexibleDecimal?
        var current_spending_cents: FlexibleDecimal?
    }
}
