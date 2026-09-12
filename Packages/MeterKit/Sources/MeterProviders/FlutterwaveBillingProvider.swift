import Foundation
import MeterCore

/// Flutterwave 商户手续费（`GET /v3/transactions` → `app_fee`）。
///
/// 文档：https://developer.flutterwave.com/docs/transaction-verification
/// 列表：`GET https://api.flutterwave.com/v3/transactions`
/// 认证：`Authorization: Bearer <FLWSECK_…>`。
/// Host：`api.flutterwave.com`。
/// 金额：`app_fee`（主币单位，非子单位）+ `currency`；日期 `created_at`。
/// 只计 `status=successful`；跳过 `app_fee` 为空或 0。
/// 凭据：`apiKey`。
public struct FlutterwaveBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.flutterwave }
    public static let apiHost = "api.flutterwave.com"
    static let maxPages = 20
    static let pageSize = 50

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
        let secret = try RequiredCredential.value(.apiKey, in: credential, providerID: .flutterwave)
        let headers = [
            "Authorization": "Bearer \(secret)",
            "Accept": "application/json",
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
            let env = try await loadPage(
                from: fetchWindow.start,
                to: current.nextStart,
                page: page,
                headers: headers
            )
            let batch = env.data ?? []
            if batch.isEmpty { break }
            for txn in batch {
                let status = (txn.status ?? "").lowercased()
                if !status.isEmpty, status != "successful", status != "success" {
                    continue
                }
                let fee = txn.appFee?.value ?? 0
                guard fee != 0 else { continue }
                let amount = abs(fee)
                try currencies.observe(txn.currency, providerID: .flutterwave)
                let stamp = txn.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = txn.txRef ?? txn.id.map { "\($0)" } ?? "txn"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: txn.paymentType ?? (status.isEmpty ? "fee" : status),
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
            let totalPages = env.meta?.totalPages ?? env.meta?.pageInfo?.totalPages ?? page
            if page >= totalPages || batch.count < Self.pageSize { break }
            page += 1
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .flutterwave
        )
        return Snapshot(
            providerID: .flutterwave,
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
            URLQueryItem(name: "from", value: Self.dateOnly(from)),
            URLQueryItem(name: "to", value: Self.dateOnly(to)),
            URLQueryItem(name: "page", value: String(page)),
        ]
        let url = ProviderURL.https(host: Self.apiHost, path: "/v3/transactions", query: query)
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .flutterwave
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .flutterwave)
    }

    static func dateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    struct Envelope: Decodable, Sendable {
        var data: [Txn]?
        var meta: Meta?
    }

    struct Meta: Decodable, Sendable {
        var pageInfo: PageInfo?
        var totalPages: Int?
        var currentPage: Int?

        enum CodingKeys: String, CodingKey {
            case pageInfo = "page_info"
            case totalPages = "total_pages"
            case currentPage = "current_page"
        }
    }

    struct PageInfo: Decodable, Sendable {
        var totalPages: Int?
        var currentPage: Int?

        enum CodingKeys: String, CodingKey {
            case totalPages = "total_pages"
            case currentPage = "current_page"
        }
    }

    struct Txn: Decodable, Sendable {
        var id: Int64?
        var txRef: String?
        var status: String?
        var currency: String?
        var paymentType: String?
        var appFee: FlexibleDecimal?
        var createdAt: String?

        enum CodingKeys: String, CodingKey {
            case id, status, currency
            case txRef = "tx_ref"
            case paymentType = "payment_type"
            case appFee = "app_fee"
            case createdAt = "created_at"
        }
    }
}
