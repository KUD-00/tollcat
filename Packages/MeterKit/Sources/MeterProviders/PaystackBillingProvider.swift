import Foundation
import MeterCore

/// Paystack 商户手续费（`GET /transaction?status=success` → `fees`）。
///
/// 文档：https://paystack.com/docs/api/transaction/#list
/// 认证：`Authorization: Bearer <sk_…>`。
/// Host：`api.paystack.co`。
/// 金额：`fees` 为币种子单位（如 kobo）→ `/100`；币种 `currency`；
/// 日期 `paid_at` / `paidAt`（回退 `created_at`）。跳过 `fees` 为空或 0。
/// 凭据：`apiKey`。
public struct PaystackBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.paystack }
    public static let apiHost = "api.paystack.co"
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
        let secret = try RequiredCredential.value(.apiKey, in: credential, providerID: .paystack)
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
                let fees = txn.fees?.value ?? 0
                guard fees != 0 else { continue }
                let amount = abs(fees) / 100
                try currencies.observe(txn.currency, providerID: .paystack)
                let stamp = txn.paidAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? txn.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = txn.reference ?? txn.id.map { "\($0)" } ?? "txn"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: txn.channel ?? txn.status ?? "fee",
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
            let pageCount = env.meta?.pageCount ?? page
            if page >= pageCount || batch.count < Self.pageSize { break }
            page += 1
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .paystack
        )
        return Snapshot(
            providerID: .paystack,
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
            URLQueryItem(name: "status", value: "success"),
            URLQueryItem(name: "from", value: Self.iso8601(from)),
            URLQueryItem(name: "to", value: Self.iso8601(to)),
            URLQueryItem(name: "perPage", value: String(Self.pageSize)),
            URLQueryItem(name: "page", value: String(page)),
        ]
        let url = ProviderURL.https(host: Self.apiHost, path: "/transaction", query: query)
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .paystack
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .paystack)
    }

    static func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    struct Envelope: Decodable, Sendable {
        var data: [Txn]?
        var meta: Meta?
    }

    struct Meta: Decodable, Sendable {
        var page: Int?
        var pageCount: Int?
        var perPage: Int?

        enum CodingKeys: String, CodingKey {
            case page
            case pageCount
            case perPage
        }
    }

    struct Txn: Decodable, Sendable {
        var id: Int64?
        var reference: String?
        var status: String?
        var channel: String?
        var currency: String?
        var fees: FlexibleDecimal?
        var paidAt: String?
        var createdAt: String?

        enum CodingKeys: String, CodingKey {
            case id, reference, status, channel, currency, fees
            case paidAt = "paid_at"
            case createdAt = "created_at"
            case paidAtCamel = "paidAt"
            case createdAtCamel = "createdAt"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decodeIfPresent(Int64.self, forKey: .id)
            reference = try c.decodeIfPresent(String.self, forKey: .reference)
            status = try c.decodeIfPresent(String.self, forKey: .status)
            channel = try c.decodeIfPresent(String.self, forKey: .channel)
            currency = try c.decodeIfPresent(String.self, forKey: .currency)
            fees = try c.decodeIfPresent(FlexibleDecimal.self, forKey: .fees)
            paidAt = try c.decodeIfPresent(String.self, forKey: .paidAt)
                ?? c.decodeIfPresent(String.self, forKey: .paidAtCamel)
            createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
                ?? c.decodeIfPresent(String.self, forKey: .createdAtCamel)
        }
    }
}
