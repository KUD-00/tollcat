import Foundation
import MeterCore

/// Alchemy Admin 用量摘要（`GET /v1/usage/summary`）。
///
/// 文档：https://www.alchemy.com/docs/admin-api/usage/get-usage-summary
/// 认证：`Authorization: Bearer <Access Key>`（非 app API key）。
/// Host：`admin-api.alchemy.com`。
/// 金额：`data.totals.monthToDate.usd`（文档写明 USD 两位小数）。
/// 凭据：`apiToken`/`apiKey`。
public struct AlchemyBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.alchemy }
    public static let apiHost = "admin-api.alchemy.com"

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .alchemy) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .alchemy)
        }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: Self.summaryURL,
            headers: headers,
            client: httpClient,
            providerID: .alchemy
        )
        let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .alchemy)
        guard let usd = envelope.data?.totals?.monthToDate?.usd?.value else {
            throw ProviderError.malformedResponse(providerID: .alchemy)
        }
        var currencies = CurrencyAccumulator()
        try currencies.observe("USD", providerID: .alchemy)
        var lines = SpendLineAccumulator()
        if usd != 0 {
            lines.add(
                SpendLine(
                    category: "usage",
                    label: "monthToDate",
                    amountUSD: Money(usd: usd)
                )
            )
        }
        let converted = try currencies.convert(
            usd,
            rates: rateSource.current,
            providerID: .alchemy
        )
        return Snapshot(
            providerID: .alchemy,
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

    static let summaryURL = ProviderURL.https(host: apiHost, path: "/v1/usage/summary")

    struct Envelope: Decodable, Sendable {
        var data: Payload?
    }

    struct Payload: Decodable, Sendable {
        var totals: Totals?
    }

    struct Totals: Decodable, Sendable {
        var monthToDate: Window?
    }

    struct Window: Decodable, Sendable {
        var usd: FlexibleDecimal?
        var amount: FlexibleDecimal?
        var unit: String?
    }
}
