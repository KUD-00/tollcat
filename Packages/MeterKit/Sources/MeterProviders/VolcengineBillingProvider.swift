import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// 火山引擎费用中心账单明细（`ListBillDetail`）。
///
/// 文档：https://www.volcengine.com/docs/6269/79834 （ListBillDetail）
/// 认证：Access Key ID + Secret（Volc HMAC-SHA256；`accessKeyID` / `secretAccessKey`）。
/// Host：`billing.volcengineapi.com`；Region `cn-north-1`；Service `billing`；Version `2022-01-01`。
/// 金额：同资源 `PayableAmount`/`PaidAmount` + `Currency`（CNY/USD）。
/// 聚合：`GroupTerm=2`（产品）+ `GroupPeriod=0`（账期），分页 `Limit=300`。
public struct VolcengineBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.volcengine }
    public static let apiHost = "billing.volcengineapi.com"
    public static let apiVersion = "2022-01-01"
    public static let signingService = "billing"
    public static let signingRegion = "cn-north-1"
    public static let pageLimit = 300

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
        if let primary = try? RequiredCredential.value(.accessKeyID, in: credential, providerID: .volcengine) {
            accessKey = primary
        } else {
            accessKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .volcengine)
        }
        let secretKey: String
        if let primary = try? RequiredCredential.value(.secretAccessKey, in: credential, providerID: .volcengine) {
            secretKey = primary
        } else if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .volcengine) {
            secretKey = primary
        } else {
            secretKey = try RequiredCredential.value(.apiToken, in: credential, providerID: .volcengine)
        }

        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: max(Self.descriptor.historyLookbackMonths, 1),
            now: now,
            calendar: calendar
        )
        let windows: [CalendarMonthWindow] = horizon == .availableHistory ? months : [current]

        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        for window in windows {
            let period = Self.billPeriod(window.start, calendar: calendar)
            let items = try await listAllBillDetails(
                accessKey: accessKey,
                secretKey: secretKey,
                billPeriod: period,
                now: now
            )
            for item in items {
                let amount = item.PayableAmount?.value
                    ?? item.PaidAmount?.value
                    ?? item.DiscountBillAmount?.value
                    ?? 0
                guard amount != 0 else { continue }
                let currency = item.Currency?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
                guard let currency, !currency.isEmpty else { continue }
                try currencies.observe(currency, providerID: .volcengine)
                let label = [
                    item.ProductZh,
                    item.Product,
                    item.ProductName,
                    item.BillID,
                ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty } ?? "bill"
                let category = item.BillingMode?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .nonEmpty
                    ?? item.BillCategory?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .nonEmpty
                    ?? "bill"
                if window.start == current.start {
                    currentTotal += amount
                    daily.add(day: current.start, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: category,
                            label: label,
                            amountUSD: Money(usd: amount)
                        )
                    )
                } else if horizon == .availableHistory {
                    daily.addPastMonth(
                        start: window.start,
                        amount: Money(usd: amount),
                        current: current,
                        calendar: calendar
                    )
                }
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .volcengine
        )
        return Snapshot(
            providerID: .volcengine,
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

    static func billPeriod(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    func listAllBillDetails(
        accessKey: String,
        secretKey: String,
        billPeriod: String,
        now: Date
    ) async throws -> [BillDetail] {
        var offset = 0
        var collected: [BillDetail] = []
        while true {
            let page = try await listBillDetail(
                accessKey: accessKey,
                secretKey: secretKey,
                billPeriod: billPeriod,
                offset: offset,
                now: now
            )
            let batch = page.Result?.List ?? []
            collected.append(contentsOf: batch)
            let total = page.Result?.Total ?? batch.count
            offset += batch.count
            if batch.isEmpty || offset >= total || batch.count < Self.pageLimit {
                break
            }
        }
        return collected
    }

    func listBillDetail(
        accessKey: String,
        secretKey: String,
        billPeriod: String,
        offset: Int,
        now: Date
    ) async throws -> Envelope {
        let query: [String: String] = [
            "Action": "ListBillDetail",
            "Version": Self.apiVersion,
            "BillPeriod": billPeriod,
            "Limit": String(Self.pageLimit),
            "Offset": String(offset),
            "GroupTerm": "2",
            "GroupPeriod": "0",
            "IgnoreZero": "1",
            "NeedRecordNum": "1",
        ]
        let body = Data()
        // 签名 canonical query 与实际 URL 必须同一套 percentEncode，避免 URLComponents 编码漂移。
        let url = URL(string: "https://\(Self.apiHost)/?\(Self.normalizedQuery(query))")!
        let headers = Self.sign(
            method: "POST",
            host: Self.apiHost,
            path: "/",
            query: query,
            body: body,
            accessKey: accessKey,
            secretKey: secretKey,
            now: now
        )
        let data = try await ProviderHTTP.post(
            url: url,
            headers: headers,
            body: body,
            client: httpClient,
            providerID: .volcengine
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .volcengine)
    }

    /// Volcengine OpenAPI HMAC-SHA256（官方签名示例对齐；可测）。
    static func sign(
        method: String,
        host: String,
        path: String,
        query: [String: String],
        body: Data,
        accessKey: String,
        secretKey: String,
        now: Date
    ) -> [String: String] {
        let xDate = amzDate(now)
        let shortDate = String(xDate.prefix(8))
        let payloadHash = sha256Hex(body)
        let contentType = "application/x-www-form-urlencoded"
        let canonicalQuery = normalizedQuery(query)
        let canonicalHeaders =
            "content-type:\(contentType)\n"
            + "host:\(host)\n"
            + "x-content-sha256:\(payloadHash)\n"
            + "x-date:\(xDate)\n"
        let signedHeaders = "content-type;host;x-content-sha256;x-date"
        let canonicalRequest = [
            method.uppercased(),
            path,
            canonicalQuery,
            canonicalHeaders,
            signedHeaders,
            payloadHash,
        ].joined(separator: "\n")
        let credentialScope = "\(shortDate)/\(signingRegion)/\(signingService)/request"
        let stringToSign = [
            "HMAC-SHA256",
            xDate,
            credentialScope,
            sha256Hex(Data(canonicalRequest.utf8)),
        ].joined(separator: "\n")
        let signingKey = derivedSigningKey(
            secret: secretKey,
            shortDate: shortDate,
            region: signingRegion,
            service: signingService
        )
        let signature = hmacHex(key: signingKey, data: Data(stringToSign.utf8))
        let authorization =
            "HMAC-SHA256 Credential=\(accessKey)/\(credentialScope), "
            + "SignedHeaders=\(signedHeaders), Signature=\(signature)"
        return [
            "Content-Type": contentType,
            "Host": host,
            "X-Date": xDate,
            "X-Content-Sha256": payloadHash,
            "Authorization": authorization,
        ]
    }

    static func normalizedQuery(_ params: [String: String]) -> String {
        params.keys.sorted().map { key in
            "\(percentEncode(key))=\(percentEncode(params[key] ?? ""))"
        }.joined(separator: "&")
    }

    /// Volc / AWS 风格 percentEncode：空格→%20，*→%2A，~ 保留。
    static func percentEncode(_ raw: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-_.~")
        return raw.addingPercentEncoding(withAllowedCharacters: allowed) ?? raw
    }

    static func amzDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter.string(from: date)
    }

    static func sha256Hex(_ data: Data) -> String {
        MeterDigest.sha256(data).map { String(format: "%02x", $0) }.joined()
    }

    static func hmac(key: Data, data: Data) -> Data {
        MeterHMAC.sha256(key: key, message: data)
    }

    static func hmacHex(key: Data, data: Data) -> String {
        hmac(key: key, data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func derivedSigningKey(
        secret: String,
        shortDate: String,
        region: String,
        service: String
    ) -> Data {
        let kDate = hmac(key: Data(secret.utf8), data: Data(shortDate.utf8))
        let kRegion = hmac(key: kDate, data: Data(region.utf8))
        let kService = hmac(key: kRegion, data: Data(service.utf8))
        return hmac(key: kService, data: Data("request".utf8))
    }

    struct Envelope: Decodable, Sendable {
        var ResponseMetadata: ResponseMetadata?
        var Result: BillResult?
    }

    struct ResponseMetadata: Decodable, Sendable {
        var Error: APIError?
        var RequestId: String?
        var Action: String?
    }

    struct APIError: Decodable, Sendable {
        var Code: String?
        var Message: String?
    }

    struct BillResult: Decodable, Sendable {
        var List: [BillDetail]?
        var Total: Int?
        var Limit: Int?
        var Offset: Int?
    }

    struct BillDetail: Decodable, Sendable {
        var BillID: String?
        var BillPeriod: String?
        var Product: String?
        var ProductZh: String?
        var ProductName: String?
        var BillingMode: String?
        var BillCategory: String?
        var Currency: String?
        var PayableAmount: FlexibleDecimal?
        var PaidAmount: FlexibleDecimal?
        var DiscountBillAmount: FlexibleDecimal?
        var OriginalBillAmount: FlexibleDecimal?
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
