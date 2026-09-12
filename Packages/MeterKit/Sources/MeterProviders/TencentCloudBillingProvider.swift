import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// 腾讯云计费账单明细（`DescribeBillDetail`）。
///
/// 文档：https://cloud.tencent.com/document/product/555/35761
/// 认证：SecretId + SecretKey（TC3-HMAC-SHA256；`accessKeyID` / `secretAccessKey`）。
/// Host：国内 `billing.tencentcloudapi.com`；国际 `billing.intl.tencentcloudapi.com`
/// （`accountID=intl` 切国际，默认国内）。Service `billing`；Version `2018-07-09`。
/// 金额：同资源 `BillDetail.Currency` + `BillDetailComponent.RealCost`（CNY/USD）；分页 Limit≤300。
public struct TencentCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.tencentcloud }
    public static let cnHost = "billing.tencentcloudapi.com"
    public static let intlHost = "billing.intl.tencentcloudapi.com"
    public static let apiVersion = "2018-07-09"
    public static let signingService = "billing"
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
        if let primary = try? RequiredCredential.value(.accessKeyID, in: credential, providerID: .tencentcloud) {
            accessKey = primary
        } else {
            accessKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .tencentcloud)
        }
        let secretKey: String
        if let primary = try? RequiredCredential.value(.secretAccessKey, in: credential, providerID: .tencentcloud) {
            secretKey = primary
        } else if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .tencentcloud) {
            secretKey = primary
        } else {
            secretKey = try RequiredCredential.value(.apiToken, in: credential, providerID: .tencentcloud)
        }
        let host = Self.host(for: credential.value(for: .accountID))

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
            let month = Self.billMonth(window.start, calendar: calendar)
            let details = try await listAllBillDetails(
                host: host,
                accessKey: accessKey,
                secretKey: secretKey,
                month: month,
                now: now
            )
            for detail in details {
                let currency = detail.Currency?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
                guard let currency, !currency.isEmpty else { continue }
                try currencies.observe(currency, providerID: .tencentcloud)
                let components = detail.ComponentSet ?? []
                let label = [
                    detail.BusinessCodeName,
                    detail.ProductCodeName,
                    detail.BusinessCode,
                    detail.ProductCode,
                    detail.ResourceId,
                ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty } ?? "bill"
                let category = detail.BusinessCode?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .nonEmpty
                    ?? detail.ActionType?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .nonEmpty
                    ?? "bill"
                var resourceAmount: Decimal = 0
                if components.isEmpty {
                    // 无组件时回落资源级实付（仍要求同资源 Currency 已观察）。
                    resourceAmount = detail.RealTotalCost?.value
                        ?? detail.CashPayAmount?.value
                        ?? 0
                } else {
                    for component in components {
                        let amount = component.RealCost?.value
                            ?? component.CashPayAmount?.value
                            ?? 0
                        resourceAmount += amount
                    }
                }
                guard resourceAmount != 0 else { continue }
                if window.start == current.start {
                    currentTotal += resourceAmount
                    daily.add(day: current.start, amount: Money(usd: resourceAmount))
                    lines.add(
                        SpendLine(
                            category: category,
                            label: label,
                            amountUSD: Money(usd: resourceAmount)
                        )
                    )
                } else if horizon == .availableHistory {
                    daily.addPastMonth(
                        start: window.start,
                        amount: Money(usd: resourceAmount),
                        current: current,
                        calendar: calendar
                    )
                }
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .tencentcloud
        )
        return Snapshot(
            providerID: .tencentcloud,
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

    static func host(for accountID: String?) -> String {
        let site = accountID?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if site == "intl" || site == "international" || site == "global" {
            return intlHost
        }
        return cnHost
    }

    func listAllBillDetails(
        host: String,
        accessKey: String,
        secretKey: String,
        month: String,
        now: Date
    ) async throws -> [BillDetail] {
        var offset = 0
        var collected: [BillDetail] = []
        while true {
            let page = try await describeBillDetail(
                host: host,
                accessKey: accessKey,
                secretKey: secretKey,
                month: month,
                offset: offset,
                now: now
            )
            if let err = page.Response?.Error, err.Code != nil || err.Message != nil {
                throw ProviderError.malformedResponse(providerID: .tencentcloud)
            }
            let batch = page.Response?.DetailSet ?? []
            collected.append(contentsOf: batch)
            let total = page.Response?.Total ?? batch.count
            offset += batch.count
            if batch.isEmpty || offset >= total || batch.count < Self.pageLimit {
                break
            }
        }
        return collected
    }

    func describeBillDetail(
        host: String,
        accessKey: String,
        secretKey: String,
        month: String,
        offset: Int,
        now: Date
    ) async throws -> Envelope {
        let bodyObject: [String: Any] = [
            "Offset": offset,
            "Limit": Self.pageLimit,
            "Month": month,
            "NeedRecordNum": 1,
        ]
        let body = try JSONSerialization.data(withJSONObject: bodyObject, options: [.sortedKeys])
        let url = URL(string: "https://\(host)/")!
        let headers = Self.sign(
            host: host,
            action: "DescribeBillDetail",
            body: body,
            secretId: accessKey,
            secretKey: secretKey,
            now: now
        )
        let data = try await ProviderHTTP.post(
            url: url,
            headers: headers,
            body: body,
            client: httpClient,
            providerID: .tencentcloud
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .tencentcloud)
    }

    /// TC3-HMAC-SHA256（官方签名 v3；可测）。
    static func sign(
        host: String,
        action: String,
        body: Data,
        secretId: String,
        secretKey: String,
        now: Date,
        service: String = signingService,
        version: String = apiVersion
    ) -> [String: String] {
        let timestamp = String(Int(now.timeIntervalSince1970))
        let date = utcDate(now)
        let contentType = "application/json; charset=utf-8"
        let payloadHash = sha256Hex(body)
        let canonicalHeaders =
            "content-type:\(contentType)\n"
            + "host:\(host)\n"
        let signedHeaders = "content-type;host"
        let canonicalRequest = [
            "POST",
            "/",
            "",
            canonicalHeaders,
            signedHeaders,
            payloadHash,
        ].joined(separator: "\n")
        let credentialScope = "\(date)/\(service)/tc3_request"
        let stringToSign = [
            "TC3-HMAC-SHA256",
            timestamp,
            credentialScope,
            sha256Hex(Data(canonicalRequest.utf8)),
        ].joined(separator: "\n")
        let signingKey = derivedSigningKey(secret: secretKey, date: date, service: service)
        let signature = hmacHex(key: signingKey, data: Data(stringToSign.utf8))
        let authorization =
            "TC3-HMAC-SHA256 Credential=\(secretId)/\(credentialScope), "
            + "SignedHeaders=\(signedHeaders), Signature=\(signature)"
        return [
            "Content-Type": contentType,
            "Host": host,
            "X-TC-Action": action,
            "X-TC-Timestamp": timestamp,
            "X-TC-Version": version,
            "Authorization": authorization,
        ]
    }

    static func utcDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
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

    static func derivedSigningKey(secret: String, date: String, service: String) -> Data {
        let kDate = hmac(key: Data("TC3\(secret)".utf8), data: Data(date.utf8))
        let kService = hmac(key: kDate, data: Data(service.utf8))
        return hmac(key: kService, data: Data("tc3_request".utf8))
    }

    struct Envelope: Decodable, Sendable {
        var Response: BillResponse?
    }

    struct BillResponse: Decodable, Sendable {
        var DetailSet: [BillDetail]?
        var Total: Int?
        var RequestId: String?
        var Error: APIError?
    }

    struct APIError: Decodable, Sendable {
        var Code: String?
        var Message: String?
    }

    struct BillDetail: Decodable, Sendable {
        var BusinessCode: String?
        var BusinessCodeName: String?
        var ProductCode: String?
        var ProductCodeName: String?
        var ActionType: String?
        var ResourceId: String?
        var Currency: String?
        var RealTotalCost: FlexibleDecimal?
        var CashPayAmount: FlexibleDecimal?
        var ComponentSet: [BillDetailComponent]?
        var BillMonth: String?
        var BillDay: String?
    }

    struct BillDetailComponent: Decodable, Sendable {
        var ComponentCode: String?
        var ComponentCodeName: String?
        var ItemCode: String?
        var ItemCodeName: String?
        var RealCost: FlexibleDecimal?
        var CashPayAmount: FlexibleDecimal?
        var Cost: FlexibleDecimal?
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
