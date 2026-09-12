import Foundation
import MeterCore

/// CM.com 交易合计（`GET /v1.2/transactions/?startdate=&enddate=`，最长 1 个月）。
///
/// 文档：https://developers.cm.com/messaging/docs/transactions-api
/// 认证：`X-CM-PRODUCTTOKEN`。Host：`api.cm.com`。
/// 金额：优先 `summary.localPrice` + `localCurrency`，否则 `totalPrice` + `priceCurrency`。
public struct CMComBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.cmcom }
    public static let apiHost = "api.cm.com"

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
        let token = try RequiredCredential.value(.apiKey, in: credential, providerID: .cmcom)
        let headers = [
            "X-CM-PRODUCTTOKEN": token,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        // API max window is 1 month — only fetch current month regardless of horizon.
        _ = horizon
        var currencies = CurrencyAccumulator()
        var lines = SpendLineAccumulator()

        let payload = try await loadTransactions(
            start: current.start,
            end: current.endInclusive,
            headers: headers
        )
        let summary = payload.summary
        let amount = summary?.localPrice?.value
            ?? summary?.totalPrice?.value
            ?? 0
        let currency = summary?.localCurrency
            ?? summary?.priceCurrency
        try currencies.observe(currency, providerID: .cmcom)
        if amount != 0 {
            lines.add(
                SpendLine(
                    category: "transactions",
                    label: "period summary",
                    amountUSD: Money(usd: amount)
                )
            )
        }

        let converted = try currencies.convert(
            amount,
            rates: rateSource.current,
            providerID: .cmcom
        )
        return Snapshot(
            providerID: .cmcom,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: converted.money,
            converted: currencies.needsConversionNote ? converted : nil,
            lines: lines.snapshot
        )
    }

    private func loadTransactions(
        start: Date,
        end: Date,
        headers: [String: String]
    ) async throws -> TransactionsResponse {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        let url = ProviderURL.https(
            host: Self.apiHost,
            path: "/v1.2/transactions/",
            query: [
                URLQueryItem(name: "startdate", value: formatter.string(from: start)),
                URLQueryItem(name: "enddate", value: formatter.string(from: end)),
            ]
        )
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .cmcom
        )
        return try ProviderHTTP.decode(TransactionsResponse.self, from: data, providerID: .cmcom)
    }

    struct TransactionsResponse: Decodable, Sendable {
        var summary: Summary?
    }

    struct Summary: Decodable, Sendable {
        var localPrice: FlexibleDecimal?
        var localCurrency: String?
        var totalPrice: FlexibleDecimal?
        var priceCurrency: String?
    }
}
