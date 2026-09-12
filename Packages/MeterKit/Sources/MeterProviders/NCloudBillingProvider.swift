import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// NAVER Cloud Platform 月度请款（`GET /billing/v1/cost/getDemandCostList`）。
///
/// 文档：https://api.ncloud-docs.com/docs/en/platform-costandusage-getdemandcostlist
/// 认证：`x-ncp-apigw-timestamp` + `x-ncp-iam-access-key` + `x-ncp-apigw-signature-v2`
/// （HMAC-SHA256 Base64；`GET {path}?{query}\\n{timestamp}\\n{accessKey}`）。
/// Host：`billingapi.apigw.ntruss.com`。
/// 金额：`totalDemandAmount` + `payCurrency.code`（常见 KRW）。
/// 单次最多查 3 个月；**忽略**余额 / coin 类字段。
/// 凭据：`accessKeyID`/`apiKey` + `secretAccessKey`/`clientSecret`/`apiToken`。
public struct NCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.ncloud }
    public static let apiHost = "billingapi.apigw.ntruss.com"
    public static let costPath = "/billing/v1/cost/getDemandCostList"
    /// API 单次 start/end 跨度上限（含端点）。
    public static let maxMonthSpan = 3

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
        if let primary = try? RequiredCredential.value(.accessKeyID, in: credential, providerID: .ncloud) {
            accessKey = primary
        } else {
            accessKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .ncloud)
        }
        let secret: String
        if let primary = try? RequiredCredential.value(.secretAccessKey, in: credential, providerID: .ncloud) {
            secret = primary
        } else if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .ncloud) {
            secret = primary
        } else {
            secret = try RequiredCredential.value(.apiToken, in: credential, providerID: .ncloud)
        }
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        for chunk in Self.monthChunks(months, size: Self.maxMonthSpan) {
            guard let first = chunk.first, let last = chunk.last else { continue }
            let startYM = Self.yearMonth(first.start, calendar: calendar)
            let endYM = Self.yearMonth(last.start, calendar: calendar)
            let url = Self.demandCostURL(startMonth: startYM, endMonth: endYM)
            let timestamp = String(Int(now.timeIntervalSince1970 * 1000))
            let headers = Self.signedHeaders(
                method: "GET",
                uri: Self.signedURI(startMonth: startYM, endMonth: endYM),
                timestamp: timestamp,
                accessKey: accessKey,
                secret: secret
            )
            let data = try await ProviderHTTP.get(
                url: url, headers: headers, client: httpClient, providerID: .ncloud
            )
            let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .ncloud)
            let rows = envelope.getDemandCostListResponse?.demandCostList ?? []
            for row in rows {
                let amount = row.totalDemandAmount?.value ?? 0
                guard amount != 0 else { continue }
                let code = row.payCurrency?.code?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                try currencies.observe(
                    (code?.isEmpty == false) ? code!.uppercased() : "KRW",
                    providerID: .ncloud
                )
                let stamp = Self.date(fromDemandMonth: row.demandMonth, calendar: calendar)
                    ?? first.start
                let label = row.demandNo ?? row.demandMonth ?? startYM
                if current.contains(stamp)
                    || calendar.isDate(stamp, equalTo: current.start, toGranularity: .month)
                {
                    currentTotal += amount
                    daily.add(day: current.contains(stamp) ? stamp : current.start, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: "invoice",
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
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .ncloud
        )
        return Snapshot(
            providerID: .ncloud,
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

    static func yearMonth(_ date: Date, calendar: Calendar) -> String {
        String(
            format: "%04d%02d",
            calendar.component(.year, from: date),
            calendar.component(.month, from: date)
        )
    }

    static func date(fromDemandMonth raw: String?, calendar: Calendar) -> Date? {
        guard let raw, raw.count == 6, let y = Int(raw.prefix(4)), let m = Int(raw.suffix(2)) else {
            return nil
        }
        var components = DateComponents()
        components.year = y
        components.month = m
        components.day = 1
        return calendar.date(from: components)
    }

    static func monthChunks(_ months: [CalendarMonthWindow], size: Int) -> [[CalendarMonthWindow]] {
        guard size > 0, !months.isEmpty else { return [] }
        var out: [[CalendarMonthWindow]] = []
        var i = 0
        while i < months.count {
            let end = min(i + size, months.count)
            out.append(Array(months[i..<end]))
            i = end
        }
        return out
    }

    static func demandCostURL(startMonth: String, endMonth: String) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: costPath,
            query: [
                URLQueryItem(name: "startMonth", value: startMonth),
                URLQueryItem(name: "endMonth", value: endMonth),
                URLQueryItem(name: "responseFormatType", value: "json"),
            ]
        )
    }

    static func signedURI(startMonth: String, endMonth: String) -> String {
        "\(costPath)?startMonth=\(startMonth)&endMonth=\(endMonth)&responseFormatType=json"
    }

    static func signedHeaders(
        method: String,
        uri: String,
        timestamp: String,
        accessKey: String,
        secret: String
    ) -> [String: String] {
        [
            "x-ncp-apigw-timestamp": timestamp,
            "x-ncp-iam-access-key": accessKey,
            "x-ncp-apigw-signature-v2": signature(
                method: method, uri: uri, timestamp: timestamp,
                accessKey: accessKey, secret: secret
            ),
            "Accept": "application/json",
        ]
    }

    static func signature(
        method: String,
        uri: String,
        timestamp: String,
        accessKey: String,
        secret: String
    ) -> String {
        let message = "\(method) \(uri)\n\(timestamp)\n\(accessKey)"
        let mac = MeterHMAC.sha256(key: Data(secret.utf8), message: Data(message.utf8))
        return Data(mac).base64EncodedString()
    }

    struct Envelope: Decodable, Sendable {
        var getDemandCostListResponse: Response?
    }

    struct Response: Decodable, Sendable {
        var demandCostList: [DemandCost]?
        var returnCode: String?
        var returnMessage: String?
    }

    struct DemandCost: Decodable, Sendable {
        var demandMonth: String?
        var demandNo: String?
        var totalDemandAmount: FlexibleDecimal?
        var payCurrency: PayCurrency?
    }

    struct PayCurrency: Decodable, Sendable {
        var code: String?
        var codeName: String?
    }
}
