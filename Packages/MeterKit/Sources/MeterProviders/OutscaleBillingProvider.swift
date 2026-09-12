import Foundation
import MeterCore

/// 3DS OUTSCALE 本月资源消费金额（`POST /api/v1/ReadConsumptionAccount`，`ShowPrice=true`）。
///
/// 文档：
/// - https://docs.outscale.com/en/userguide/Getting-Information-About-Your-Resource-Consumption.html
/// - https://docs.outscale.com/api.html#readconsumptionaccount
/// 认证：OSC SigV4（`accessKeyID` / `secretAccessKey`；可选 `accountID` = region，默认 `eu-west-2`）。
/// 金额：条目 `Price` + 响应级 ISO `Currency`；`ToDate` 为开区间右端。
public struct OutscaleBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.outscale }
    static let defaultRegion = "eu-west-2"
    /// JS SDK / curl 对 OUTSCALE API 使用的 SigV4 service 名。
    static let signingService = "api"

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
        let accessKey = try RequiredCredential.value(.accessKeyID, in: credential, providerID: .outscale)
        let secretKey = try RequiredCredential.value(.secretAccessKey, in: credential, providerID: .outscale)
        let regionRaw = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let region = (regionRaw?.isEmpty == false) ? regionRaw! : Self.defaultRegion
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let windows: [CalendarMonthWindow] = horizon == .availableHistory ? months : [current]

        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        for window in windows {
            let from = Self.apiDay(window.start, calendar: calendar)
            // ToDate is exclusive — first day of next month.
            let toExclusive = calendar.date(byAdding: .day, value: 1, to: window.endInclusive)
                ?? window.endInclusive
            let to = Self.apiDay(toExclusive, calendar: calendar)
            let payload = try await readConsumption(
                accessKey: accessKey,
                secretKey: secretKey,
                region: region,
                from: from,
                to: to
            )
            let currency = payload.Currency?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            try currencies.observe(currency, providerID: .outscale)

            var monthTotal: Decimal = 0
            for row in payload.ConsumptionEntries ?? [] {
                let amount = row.Price?.value ?? 0
                guard amount != 0 else { continue }
                monthTotal += amount
                let stamp = row.FromDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? window.start
                let label = [
                    row.Title,
                    row.entryType,
                    row.Operation,
                    row.ResourceId,
                ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty } ?? "consumption"

                if window.start == current.start {
                    daily.add(
                        day: current.contains(stamp) ? stamp : current.start,
                        amount: Money(usd: amount)
                    )
                    lines.add(
                        SpendLine(
                            category: row.Category ?? row.Service ?? "usage",
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
            if window.start == current.start {
                currentTotal = monthTotal
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .outscale
        )
        return Snapshot(
            providerID: .outscale,
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

    static func apiDay(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private func readConsumption(
        accessKey: String,
        secretKey: String,
        region: String,
        from: String,
        to: String
    ) async throws -> ReadResponse {
        let host = "api.\(region).outscale.com"
        let path = "/api/v1/ReadConsumptionAccount"
        let request = ReadRequest(FromDate: from, ToDate: to, ShowPrice: true)
        let body = try JSONEncoder().encode(request)
        let url = ProviderURL.https(host: host, path: path)
        let headers = Self.sign(
            method: "POST",
            host: host,
            path: path,
            body: body,
            accessKey: accessKey,
            secretKey: secretKey,
            region: region,
            now: now()
        )
        let data = try await ProviderHTTP.post(
            url: url,
            headers: headers,
            body: body,
            client: httpClient,
            providerID: .outscale
        )
        return try ProviderHTTP.decode(ReadResponse.self, from: data, providerID: .outscale)
    }

    /// AWS Signature Version 4（OUTSCALE 兼容；service = `api`）。
    static func sign(
        method: String,
        host: String,
        path: String,
        body: Data,
        accessKey: String,
        secretKey: String,
        region: String,
        now: Date
    ) -> [String: String] {
        let amzDate = Self.amzDate(now)
        let dateStamp = String(amzDate.prefix(8))
        let payloadHash = Self.sha256Hex(body)
        let canonicalHeaders =
            "content-type:application/json\n"
            + "host:\(host)\n"
            + "x-amz-date:\(amzDate)\n"
        let signedHeaders = "content-type;host;x-amz-date"
        let canonicalRequest = [
            method,
            path,
            "",
            canonicalHeaders,
            signedHeaders,
            payloadHash,
        ].joined(separator: "\n")
        let credentialScope = "\(dateStamp)/\(region)/\(signingService)/aws4_request"
        let stringToSign = [
            "AWS4-HMAC-SHA256",
            amzDate,
            credentialScope,
            Self.sha256Hex(Data(canonicalRequest.utf8)),
        ].joined(separator: "\n")
        let signingKey = Self.signingKey(
            secret: secretKey,
            dateStamp: dateStamp,
            region: region,
            service: signingService
        )
        let signature = Self.hmacHex(key: signingKey, data: Data(stringToSign.utf8))
        let authorization =
            "AWS4-HMAC-SHA256 Credential=\(accessKey)/\(credentialScope), "
            + "SignedHeaders=\(signedHeaders), Signature=\(signature)"
        return [
            "Content-Type": "application/json",
            "Host": host,
            "X-Amz-Date": amzDate,
            "Authorization": authorization,
        ]
    }

    static func amzDate(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let c = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        return String(
            format: "%04d%02d%02dT%02d%02d%02dZ",
            c.year ?? 0, c.month ?? 0, c.day ?? 0,
            c.hour ?? 0, c.minute ?? 0, c.second ?? 0
        )
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

    static func signingKey(
        secret: String,
        dateStamp: String,
        region: String,
        service: String
    ) -> Data {
        let kDate = hmac(key: Data("AWS4\(secret)".utf8), data: Data(dateStamp.utf8))
        let kRegion = hmac(key: kDate, data: Data(region.utf8))
        let kService = hmac(key: kRegion, data: Data(service.utf8))
        return hmac(key: kService, data: Data("aws4_request".utf8))
    }

    struct ReadRequest: Encodable, Sendable {
        var FromDate: String
        var ToDate: String
        var ShowPrice: Bool
    }

    struct ReadResponse: Decodable, Sendable {
        var Currency: String?
        var ConsumptionEntries: [ConsumptionRow]?
    }

    struct ConsumptionRow: Decodable, Sendable {
        var AccountId: String?
        var Category: String?
        var FromDate: String?
        var ToDate: String?
        var Operation: String?
        var Price: FlexibleDecimal?
        var UnitPrice: FlexibleDecimal?
        var ResourceId: String?
        var Service: String?
        var Title: String?
        var entryType: String?
        var Value: FlexibleDecimal?

        enum CodingKeys: String, CodingKey {
            case Category, FromDate, ToDate, Operation, Price, UnitPrice, ResourceId, Service, Title, Value
            case entryType = "Type"
        }
    }
}
