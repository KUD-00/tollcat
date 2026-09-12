import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// iwinv（KR）账单列表（`GET /v1/bill`）。
///
/// 文档：https://api.iwinv.kr/doc-637859 、OpenAPI Bill list。
/// 认证：`X-iwinv-Timestamp` + `X-iwinv-Credential` + `X-iwinv-Signature`
/// （HMAC-SHA256 hex；`timestamp + path`，path 无尾斜杠、**签名不含 query**）。
/// Host：`api-kr.iwinv.kr`。
/// 金额：`payment_price` + `currency`（常见 KRW）；日期：`usage_start` / `bill_date`。
/// **跳过** `type: prepaid`（预付消息等）；只取 period 账单（如 `regular`）。
/// 凭据：`accessKeyID`/`apiKey` + `secretAccessKey`/`clientSecret`/`apiToken`。
public struct IwinvBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.iwinv }
    public static let apiHost = "api-kr.iwinv.kr"
    public static let billPath = "/v1/bill"
    public static let defaultCurrency = "KRW"
    static let maxPages = 20

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
        let accessKey: String
        if let primary = try? RequiredCredential.value(.accessKeyID, in: credential, providerID: .iwinv) {
            accessKey = primary
        } else {
            accessKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .iwinv)
        }
        let secret: String
        if let primary = try? RequiredCredential.value(.secretAccessKey, in: credential, providerID: .iwinv) {
            secret = primary
        } else if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .iwinv) {
            secret = primary
        } else {
            secret = try RequiredCredential.value(.apiToken, in: credential, providerID: .iwinv)
        }
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var page = 1
        while page <= Self.maxPages {
            let envelope = try await loadBills(
                page: page,
                accessKey: accessKey,
                secret: secret,
                now: now
            )
            let bills = envelope.result ?? []
            for bill in bills {
                let type = (bill.type ?? "").lowercased()
                if type == "prepaid" { continue }
                let amount = bill.payment_price?.value ?? bill.price?.value ?? 0
                guard amount != 0 else { continue }
                let currency = bill.currency?.trimmingCharacters(in: .whitespacesAndNewlines)
                try currencies.observe(
                    (currency?.isEmpty == false) ? currency! : Self.defaultCurrency,
                    providerID: .iwinv
                )
                let stamp = bill.usage_start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? bill.bill_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = bill.bill_id ?? bill.name ?? "bill"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: type.isEmpty ? "bill" : type,
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
            let count = envelope.count ?? bills.count
            let pageSize = Int(envelope.page_size ?? "") ?? bills.count
            if bills.isEmpty || (pageSize > 0 && count < pageSize) || bills.count < pageSize {
                break
            }
            page += 1
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .iwinv
        )
        return Snapshot(
            providerID: .iwinv,
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

    private func loadBills(
        page: Int,
        accessKey: String,
        secret: String,
        now: Date
    ) async throws -> Envelope {
        let timestamp = String(Int(now.timeIntervalSince1970))
        let headers = Self.signedHeaders(
            timestamp: timestamp,
            path: Self.billPath,
            accessKey: accessKey,
            secret: secret
        )
        let url = ProviderURL.https(
            host: Self.apiHost,
            path: Self.billPath,
            query: [
                URLQueryItem(name: "page_no", value: String(page)),
                URLQueryItem(name: "page_size", value: "100"),
            ]
        )
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .iwinv
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .iwinv)
    }

    static var billListURL: URL {
        ProviderURL.https(host: apiHost, path: billPath)
    }

    static func signedHeaders(
        timestamp: String,
        path: String,
        accessKey: String,
        secret: String
    ) -> [String: String] {
        [
            "X-iwinv-Timestamp": timestamp,
            "X-iwinv-Credential": accessKey,
            "X-iwinv-Signature": signature(timestamp: timestamp, path: path, secret: secret),
            "Accept": "application/json",
        ]
    }

    static func signature(timestamp: String, path: String, secret: String) -> String {
        let message = "\(timestamp)\(path)"
        let mac = MeterHMAC.sha256(key: Data(secret.utf8), message: Data(message.utf8))
        return Data(mac).map { String(format: "%02x", $0) }.joined()
    }

    struct Envelope: Decodable, Sendable {
        var code: String?
        var result: [Bill]?
        var count: Int?
        var page_no: String?
        var page_size: String?
    }

    struct Bill: Decodable, Sendable {
        var bill_id: String?
        var usage_start: String?
        var usage_end: String?
        var bill_date: String?
        var type: String?
        var name: String?
        var price: FlexibleDecimal?
        var payment_price: FlexibleDecimal?
        var currency: String?
    }
}
