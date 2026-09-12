import Foundation
import MeterCore

/// DNSimple 账单 charges（`GET /v2/{account}/billing/charges`）。
///
/// 文档：https://developer.dnsimple.com/v2/billing-charges/
/// 认证：`Authorization: Bearer <token>`。
/// Host：`api.dnsimple.com`。
/// 金额：`total_amount`（文档定价为 USD）+ `invoiced_at`。仅合计 `state == collected`。
/// 凭据：`apiToken`/`apiKey` + `accountID`。
public struct DNSimpleBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.dnsimple }
    public static let apiHost = "api.dnsimple.com"

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .dnsimple) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .dnsimple)
        }
        let accountID = try RequiredCredential.value(.accountID, in: credential, providerID: .dnsimple)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let charges = try await loadCharges(accountID: accountID, headers: headers)
        for charge in charges {
            let state = (charge.state ?? "").lowercased()
            guard state.isEmpty || state == "collected" else { continue }
            let amount = charge.total_amount?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe("USD", providerID: .dnsimple)
            let stamp = charge.invoiced_at.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = charge.reference
                ?? charge.items?.first?.description
                ?? "charge"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "charge",
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

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .dnsimple
        )
        return Snapshot(
            providerID: .dnsimple,
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

    private func loadCharges(accountID: String, headers: [String: String]) async throws -> [Charge] {
        let data = try await ProviderHTTP.get(
            url: Self.chargesURL(accountID: accountID),
            headers: headers,
            client: httpClient,
            providerID: .dnsimple
        )
        let envelope = try ProviderHTTP.decode(ChargeList.self, from: data, providerID: .dnsimple)
        return envelope.data ?? []
    }

    static func chargesURL(accountID: String) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/v2/\(accountID)/billing/charges"
        )
    }

    struct ChargeList: Decodable, Sendable {
        var data: [Charge]?
    }

    struct Charge: Decodable, Sendable {
        var invoiced_at: String?
        var total_amount: FlexibleDecimal?
        var balance_amount: FlexibleDecimal?
        var reference: String?
        var state: String?
        var items: [Item]?
    }

    struct Item: Decodable, Sendable {
        var description: String?
        var amount: FlexibleDecimal?
    }
}
