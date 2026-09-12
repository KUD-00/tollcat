import Foundation
import MeterCore

/// Plivo 本月花费。
///
/// 文档：`GET /v1/Account/{auth_id}/UsageSummary/`
/// 认证：HTTP Basic，用户名 Auth ID，密码 Auth Token。
///
/// 第一页 `meta.total_spend` 是窗口内用量加其它费用的合计，官方美元。
/// 不读 `cash_credits`：那是还剩多少，不是这个月花了多少。
public struct PlivoBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.plivo }

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
        let authID = try RequiredCredential.value(.accountID, in: credential, providerID: .plivo)
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .plivo)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let headers = [
            "Authorization": Self.basicAuthorization(authID: authID, token: token),
        ]
        var currency = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var currentTotal: Decimal?
        for month in months {
            let end = month.start == current.start ? now : month.endInclusive
            let data: Data
            do {
                data = try await ProviderHTTP.get(
                    url: Self.summaryURL(authID: authID, window: month, now: end, calendar: calendar),
                    headers: headers,
                    client: httpClient,
                    providerID: .plivo
                )
            } catch let error as ProviderError where error.code == .billingAPIUnavailable {
                if month.start == current.start { throw error }
                continue
            }
            let payload = try ProviderHTTP.decode(Summary.self, from: data, providerID: .plivo)
            guard let total = payload.meta?.total_spend?.value else {
                if month.start == current.start {
                    throw ProviderError.malformedResponse(providerID: .plivo)
                }
                continue
            }
            try currency.observe(payload.meta?.currency, providerID: .plivo)
            if month.start == current.start {
                currentTotal = total
            } else {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: total),
                    current: current,
                    calendar: calendar
                )
            }
        }
        guard let currentTotal else {
            throw ProviderError.malformedResponse(providerID: .plivo)
        }
        return try Snapshot(
            providerID: .plivo,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    static func basicAuthorization(authID: String, token: String) -> String {
        "Basic \(ProviderOAuth.basicValue(id: authID, secret: token))"
    }

    static func summaryURL(
        authID: String,
        window: CalendarMonthWindow,
        now: Date,
        calendar: Calendar
    ) -> URL {
        ProviderURL.https(
            host: "api.plivo.com",
            path: "/v1/Account/\(authID)/UsageSummary/",
            query: [
                URLQueryItem(name: "granularity", value: "month"),
                URLQueryItem(name: "from_date", value: window.dayString(window.start, calendar: calendar)),
                URLQueryItem(name: "to_date", value: window.dayString(now, calendar: calendar)),
            ]
        )
    }

    struct Summary: Decodable, Sendable {
        var meta: Meta?
    }

    struct Meta: Decodable, Sendable {
        var currency: String?
        var total_spend: FlexibleDecimal?
    }
}
