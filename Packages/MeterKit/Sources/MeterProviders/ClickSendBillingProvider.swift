import Foundation
import MeterCore

/// ClickSend 本月按量花费（跳过账户余额）。
///
/// 文档：`GET /v3/account/usage/{year}/{month}/subaccount`
/// 认证：HTTP Basic（用户名 + API Key）。
///
/// `sms_total.price` / `total_price` + `_currency.currency_name_short` 为本月费率金额。
public struct ClickSendBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.clicksend }

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
        let username = try RequiredCredential.value(.clientID, in: credential, providerID: .clicksend)
        let apiKey = try RequiredCredential.value(.clientSecret, in: credential, providerID: .clicksend)
        let headers = [
            "Authorization": "Basic \(ProviderOAuth.basicValue(id: username, secret: apiKey))",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var currentTotal: Decimal = 0

        for month in months {
            let parts = calendar.dateComponents([.year, .month], from: month.start)
            let year = parts.year ?? 0
            let mon = parts.month ?? 0
            let data = try await ProviderHTTP.get(
                url: Self.usageURL(year: year, month: mon),
                headers: headers,
                client: httpClient,
                providerID: .clicksend
            )
            let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .clicksend)
            try currencies.observe(
                payload.data?._currency?.currency_name_short ?? payload.data?.currency,
                providerID: .clicksend
            )
            let amount = payload.data?.total_price?.value
                ?? payload.data?.sms_total?.price?.value
                ?? 0
            if month.start == current.start {
                currentTotal = amount
            } else {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: amount),
                    current: current,
                    calendar: calendar
                )
            }
        }

        let converted = try currencies.convert(currentTotal, rates: rateSource.current, providerID: .clicksend)
        return Snapshot(
            providerID: .clicksend,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: converted.money,
            dailyUSD: currencies.scaled(daily.snapshotDaily, by: converted.usdPerUnit),
            converted: currencies.needsConversionNote ? converted : nil
        )
    }

    static func usageURL(year: Int, month: Int) -> URL {
        ProviderURL.https(
            host: "rest.clicksend.com",
            path: "/v3/account/usage/\(year)/\(month)/subaccount"
        )
    }

    struct Envelope: Decodable, Sendable {
        var data: Usage?
    }

    struct Usage: Decodable, Sendable {
        var total_price: FlexibleDecimal?
        var currency: String?
        var sms_total: SMSTotal?
        var _currency: CurrencyMeta?
    }

    struct SMSTotal: Decodable, Sendable {
        var price: FlexibleDecimal?
    }

    struct CurrencyMeta: Decodable, Sendable {
        var currency_name_short: String?
    }
}
