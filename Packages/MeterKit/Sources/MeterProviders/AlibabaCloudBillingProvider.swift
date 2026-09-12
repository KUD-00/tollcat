import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Alibaba Cloud BSS 账单总览（`QueryBillOverview`）。
///
/// 文档：https://www.alibabacloud.com/help/en/user-center/developer-reference/api-bssopenapi-2017-12-14-querybilloverview
/// 认证：AccessKey ID + Secret（RPC HMAC-SHA1；`accessKeyID` / `secretAccessKey`）。
/// Host：国际站 `business.ap-southeast-1.aliyuncs.com`；国内站 `business.aliyuncs.com`
/// （`accountID=cn` 切国内，默认国际）。
/// 金额：`Data.Items.Item[]` 同资源 `PretaxAmount`/`PaymentAmount` + `Currency`（CNY/USD/JPY）。
public struct AlibabaCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.alibabacloud }
    public static let intlHost = "business.ap-southeast-1.aliyuncs.com"
    public static let cnHost = "business.aliyuncs.com"
    public static let apiVersion = "2017-12-14"

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
        if let primary = try? RequiredCredential.value(.accessKeyID, in: credential, providerID: .alibabacloud) {
            accessKey = primary
        } else {
            accessKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .alibabacloud)
        }
        let secretKey: String
        if let primary = try? RequiredCredential.value(.secretAccessKey, in: credential, providerID: .alibabacloud) {
            secretKey = primary
        } else if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .alibabacloud) {
            secretKey = primary
        } else {
            secretKey = try RequiredCredential.value(.apiToken, in: credential, providerID: .alibabacloud)
        }
        let site = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let host = (site == "cn" || site == "china") ? Self.cnHost : Self.intlHost

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
            let cycle = Self.billCycle(window.start, calendar: calendar)
            let payload = try await queryBillOverview(
                host: host,
                accessKey: accessKey,
                secretKey: secretKey,
                billingCycle: cycle,
                now: now
            )
            guard payload.Success != false else {
                throw ProviderError.malformedResponse(providerID: .alibabacloud)
            }
            for item in payload.Data?.Items?.Item ?? [] {
                let amount = item.PaymentAmount?.value
                    ?? item.PretaxAmount?.value
                    ?? item.CashAmount?.value
                    ?? 0
                guard amount != 0 else { continue }
                let currency = item.Currency?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
                guard let currency, !currency.isEmpty else { continue }
                try currencies.observe(currency, providerID: .alibabacloud)
                let label = [
                    item.ProductName,
                    item.ProductDetail,
                    item.ProductCode,
                    item.Item,
                ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty } ?? "bill"
                let category = item.SubscriptionType?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .nonEmpty
                    ?? item.Item?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
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
            providerID: .alibabacloud
        )
        return Snapshot(
            providerID: .alibabacloud,
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

    static func billCycle(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    static func host(for accountID: String?) -> String {
        let site = accountID?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return (site == "cn" || site == "china") ? cnHost : intlHost
    }

    func queryBillOverview(
        host: String,
        accessKey: String,
        secretKey: String,
        billingCycle: String,
        now: Date
    ) async throws -> Envelope {
        let url = Self.signedURL(
            host: host,
            accessKey: accessKey,
            secretKey: secretKey,
            billingCycle: billingCycle,
            now: now,
            nonce: UUID().uuidString
        )
        let data = try await ProviderHTTP.get(
            url: url,
            headers: ["Accept": "application/json"],
            client: httpClient,
            providerID: .alibabacloud
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .alibabacloud)
    }

    /// 可测的签名 URL 拼装（nonce / now 注入）。
    static func signedURL(
        host: String,
        accessKey: String,
        secretKey: String,
        billingCycle: String,
        now: Date,
        nonce: String
    ) -> URL {
        var params: [String: String] = [
            "AccessKeyId": accessKey,
            "Action": "QueryBillOverview",
            "BillingCycle": billingCycle,
            "Format": "JSON",
            "SignatureMethod": "HMAC-SHA1",
            "SignatureNonce": nonce,
            "SignatureVersion": "1.0",
            "Timestamp": iso8601(now),
            "Version": apiVersion,
        ]
        let signature = sign(params: params, secretKey: secretKey)
        params["Signature"] = signature
        let query = params.keys.sorted().map { key in
            URLQueryItem(name: key, value: params[key])
        }
        return ProviderURL.https(host: host, path: "/", query: query)
    }

    static func sign(params: [String: String], secretKey: String) -> String {
        let canonical = params.keys.sorted().map { key in
            "\(percentEncode(key))=\(percentEncode(params[key] ?? ""))"
        }.joined(separator: "&")
        let stringToSign = "GET&\(percentEncode("/"))&\(percentEncode(canonical))"
        let mac = MeterHMAC.sha1(
            key: Data("\(secretKey)&".utf8),
            message: Data(stringToSign.utf8)
        )
        return Data(mac).base64EncodedString()
    }

    /// Alibaba RPC 百分号编码：空格→%20，*→%2A，~ 不编码。
    static func percentEncode(_ raw: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-_.~")
        return raw.addingPercentEncoding(withAllowedCharacters: allowed) ?? raw
    }

    static func iso8601(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter.string(from: date)
    }

    struct Envelope: Decodable, Sendable {
        var Code: String?
        var Message: String?
        var Success: Bool?
        var Data: BillData?
    }

    struct BillData: Decodable, Sendable {
        var BillingCycle: String?
        var Items: ItemList?
    }

    struct ItemList: Decodable, Sendable {
        var Item: [BillItem]?
    }

    struct BillItem: Decodable, Sendable {
        var Item: String?
        var Currency: String?
        var SubscriptionType: String?
        var PretaxAmount: FlexibleDecimal?
        var PaymentAmount: FlexibleDecimal?
        var CashAmount: FlexibleDecimal?
        var ProductName: String?
        var ProductDetail: String?
        var ProductCode: String?
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
