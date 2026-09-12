import Foundation
import MeterCore

/// PayPal 商户手续费（`GET /v1/reporting/transactions` → `fee_amount`）。
///
/// 文档：https://developer.paypal.com/docs/api/transaction-search/v1/
/// 认证：OAuth2 `client_credentials`（Client ID + Secret）→ Bearer。
/// Host：`api-m.paypal.com`；换票：同 host `/v1/oauth2/token`。
/// 金额：`transaction_info.fee_amount.value` 绝对值（手续费常为负）+ `currency_code`；
/// 日期 `transaction_initiation_date`（回退 `transaction_updated_date`）。
/// 只累计成功相关交易；跳过无手续费行。
/// 凭据：`clientID` + `clientSecret`。
public struct PayPalBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.paypal }
    public static let apiHost = "api-m.paypal.com"
    static let maxPages = 20
    static let pageSize = 100

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

    public static var tokenURL: URL {
        ProviderURL.https(host: apiHost, path: "/v1/oauth2/token")
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let clientID = try RequiredCredential.value(.clientID, in: credential, providerID: .paypal)
        let clientSecret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .paypal)
        let token = try await ProviderOAuth.clientCredentialsToken(
            url: Self.tokenURL,
            basic: (id: clientID, secret: clientSecret),
            form: ["grant_type": "client_credentials"],
            client: httpClient,
            providerID: .paypal
        )
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let fetchWindow = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var page = 1
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let end = min(current.nextStart, now.addingTimeInterval(1))
            let env = try await loadPage(
                from: fetchWindow.start,
                to: end,
                page: page,
                headers: headers
            )
            let batch = env.transactionDetails ?? []
            if batch.isEmpty { break }
            for row in batch {
                guard let info = row.transactionInfo else { continue }
                let fee = info.feeAmount?.value?.value ?? 0
                let amount = abs(fee)
                guard amount != 0 else { continue }
                try currencies.observe(info.feeAmount?.currencyCode ?? info.transactionAmount?.currencyCode, providerID: .paypal)
                let stamp = info.transactionInitiationDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? info.transactionUpdatedDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = info.transactionId ?? info.paypalReferenceId ?? "txn"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: info.transactionEventCode ?? "fee",
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
            let totalPages = env.totalPages ?? page
            if page >= totalPages || batch.count < Self.pageSize { break }
            page += 1
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .paypal
        )
        return Snapshot(
            providerID: .paypal,
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

    private func loadPage(
        from: Date,
        to: Date,
        page: Int,
        headers: [String: String]
    ) async throws -> Envelope {
        let query = [
            URLQueryItem(name: "start_date", value: Self.iso8601(from)),
            URLQueryItem(name: "end_date", value: Self.iso8601(to)),
            URLQueryItem(name: "fields", value: "transaction_info"),
            URLQueryItem(name: "page_size", value: String(Self.pageSize)),
            URLQueryItem(name: "page", value: String(page)),
        ]
        let url = ProviderURL.https(host: Self.apiHost, path: "/v1/reporting/transactions", query: query)
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .paypal
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .paypal)
    }

    static func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    struct Envelope: Decodable, Sendable {
        var transactionDetails: [Row]?
        var totalPages: Int?
        var page: Int?

        enum CodingKeys: String, CodingKey {
            case transactionDetails = "transaction_details"
            case totalPages = "total_pages"
            case page
        }
    }

    struct Row: Decodable, Sendable {
        var transactionInfo: Info?

        enum CodingKeys: String, CodingKey {
            case transactionInfo = "transaction_info"
        }
    }

    struct Info: Decodable, Sendable {
        var transactionId: String?
        var paypalReferenceId: String?
        var transactionEventCode: String?
        var transactionInitiationDate: String?
        var transactionUpdatedDate: String?
        var transactionAmount: MoneyAmount?
        var feeAmount: MoneyAmount?

        enum CodingKeys: String, CodingKey {
            case transactionId = "transaction_id"
            case paypalReferenceId = "paypal_reference_id"
            case transactionEventCode = "transaction_event_code"
            case transactionInitiationDate = "transaction_initiation_date"
            case transactionUpdatedDate = "transaction_updated_date"
            case transactionAmount = "transaction_amount"
            case feeAmount = "fee_amount"
        }
    }

    struct MoneyAmount: Decodable, Sendable {
        var currencyCode: String?
        var value: FlexibleDecimal?

        enum CodingKeys: String, CodingKey {
            case currencyCode = "currency_code"
            case value
        }
    }
}
