import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// 金山云费用账单产品线汇总（`DescribeBillSummaryByProduct`）。
///
/// 文档：https://docs.ksyun.com/documents/39113
/// 认证：AccessKey + SecretKey（简化版 HMAC-SHA256；`accessKeyID` / `secretAccessKey`）。
/// Host：`bill-union.api.ksyun.com`；Service `bill-union`；Region `cn-beijing-6`；Version `2020-01-01`。
/// 金额：同资源 `RealTotalCost`/`Cash` + `Currency`（CNY/USD）；产品线见 `SummaryOverview`。
public struct KingsoftCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.kingsoftcloud }
    public static let apiHost = "bill-union.api.ksyun.com"
    public static let apiVersion = "2020-01-01"
    public static let signingService = "bill-union"
    public static let signingRegion = "cn-beijing-6"

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
        if let primary = try? RequiredCredential.value(.accessKeyID, in: credential, providerID: .kingsoftcloud) {
            accessKey = primary
        } else {
            accessKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .kingsoftcloud)
        }
        let secretKey: String
        if let primary = try? RequiredCredential.value(.secretAccessKey, in: credential, providerID: .kingsoftcloud) {
            secretKey = primary
        } else if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .kingsoftcloud) {
            secretKey = primary
        } else {
            secretKey = try RequiredCredential.value(.apiToken, in: credential, providerID: .kingsoftcloud)
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
            let cycle = Self.billMonth(window.start, calendar: calendar)
            let payload = try await describeBillSummaryByProduct(
                accessKey: accessKey,
                secretKey: secretKey,
                billMonth: cycle,
                now: now
            )
            let currency = payload.Currency?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            guard let currency, !currency.isEmpty else {
                throw ProviderError.malformedResponse(providerID: .kingsoftcloud)
            }
            try currencies.observe(currency, providerID: .kingsoftcloud)

            let items = payload.SummaryOverview ?? []
            if items.isEmpty {
                let amount = payload.RealTotalCost?.value ?? payload.Cash?.value ?? 0
                if amount != 0, window.start == current.start {
                    currentTotal += amount
                    daily.add(day: current.start, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(category: "bill", label: "bill", amountUSD: Money(usd: amount))
                    )
                } else if amount != 0, horizon == .availableHistory {
                    daily.addPastMonth(
                        start: window.start,
                        amount: Money(usd: amount),
                        current: current,
                        calendar: calendar
                    )
                }
                continue
            }

            for item in items {
                let amount = item.RealTotalCost?.value ?? item.Cash?.value ?? 0
                guard amount != 0 else { continue }
                let label = [
                    item.ProductName,
                    item.ProductCode,
                ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty } ?? "bill"
                let category = item.ProductCode?
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
            providerID: .kingsoftcloud
        )
        return Snapshot(
            providerID: .kingsoftcloud,
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

    static func billMonth(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    func describeBillSummaryByProduct(
        accessKey: String,
        secretKey: String,
        billMonth: String,
        now: Date
    ) async throws -> Envelope {
        let url = Self.signedURL(
            accessKey: accessKey,
            secretKey: secretKey,
            billMonth: billMonth,
            now: now
        )
        let data = try await ProviderHTTP.get(
            url: url,
            headers: ["Accept": "application/json"],
            client: httpClient,
            providerID: .kingsoftcloud
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .kingsoftcloud)
    }

    /// 可测的签名 URL 拼装（Timestamp 由 now 注入）。
    static func signedURL(
        accessKey: String,
        secretKey: String,
        billMonth: String,
        now: Date
    ) -> URL {
        var params: [String: String] = [
            "Accesskey": accessKey,
            "Action": "DescribeBillSummaryByProduct",
            "BillBeginMonth": billMonth,
            "BillEndMonth": billMonth,
            "Format": "json",
            "Region": signingRegion,
            "Service": signingService,
            "SignatureMethod": "HMAC-SHA256",
            "SignatureVersion": "1.0",
            "Timestamp": iso8601(now),
            "Version": apiVersion,
        ]
        params["Signature"] = sign(params: params, secretKey: secretKey)
        var items = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        items.sort { $0.name < $1.name }
        return ProviderURL.https(host: apiHost, path: "/", query: items)
    }

    /// 官方简化版：HMAC-SHA256(CanonicalizedQueryString, SK) → 小写 hex。
    static func sign(params: [String: String], secretKey: String) -> String {
        let canonical = params
            .filter { $0.key != "Signature" }
            .sorted { $0.key < $1.key }
            .map { "\(percentEncode($0.key))=\(percentEncode($0.value))" }
            .joined(separator: "&")
        let mac = MeterHMAC.sha256(key: Data(secretKey.utf8), message: Data(canonical.utf8))
        return mac.map { String(format: "%02x", $0) }.joined()
    }

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
        var RequestId: String?
        var Currency: String?
        var RealTotalCost: FlexibleDecimal?
        var Cash: FlexibleDecimal?
        var Reward: FlexibleDecimal?
        var Voucher: FlexibleDecimal?
        var CloudTicketCost: FlexibleDecimal?
        var SummaryOverview: [ProductSummary]?
    }

    struct ProductSummary: Decodable, Sendable {
        var ProductCode: String?
        var ProductName: String?
        var RealTotalCost: FlexibleDecimal?
        var Cash: FlexibleDecimal?
        var BillMonth: String?
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
