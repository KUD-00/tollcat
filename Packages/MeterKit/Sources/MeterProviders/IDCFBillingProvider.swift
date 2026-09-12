import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// IDCF 云账单（`GET /api/v1/billings/{YYYY-MM}`）。
///
/// 文档：https://www.idcf.jp/help/cloud/docs/ · https://blog.idcf.jp/entry/2016/08/31/154810
/// 认证：`X-IDCF-APIKEY` + `X-IDCF-Expires` + `X-IDCF-Signature`
/// （HMAC-SHA256 Base64，`GET\\n{path}\\n{apiKey}\\n{expires}\\n{query}`）。
/// Host：`your.idcfcloud.com`。
/// 金额：`meta.total`（JPY 税込月额）。忽略余额类字段。
/// 凭据：`apiKey`/`accessKeyID` + `clientSecret`/`secretAccessKey`。
public struct IDCFBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.idcf }
    public static let apiHost = "your.idcfcloud.com"

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
        let apiKey: String
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .idcf) {
            apiKey = primary
        } else if let primary = try? RequiredCredential.value(.accessKeyID, in: credential, providerID: .idcf) {
            apiKey = primary
        } else {
            apiKey = try RequiredCredential.value(.clientID, in: credential, providerID: .idcf)
        }
        let secret: String
        if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .idcf) {
            secret = primary
        } else if let primary = try? RequiredCredential.value(.secretAccessKey, in: credential, providerID: .idcf) {
            secret = primary
        } else {
            secret = try RequiredCredential.value(.apiToken, in: credential, providerID: .idcf)
        }
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0
        try currencies.observe("JPY", providerID: .idcf)

        let months: [Date]
        if horizon == .availableHistory {
            months = (0..<12).compactMap { offset in
                calendar.date(byAdding: .month, value: -offset, to: current.start)
            }
        } else {
            months = [current.start]
        }

        for monthStart in months {
            let ym = Self.yearMonth(monthStart, calendar: calendar)
            let expires = String(Int(now.timeIntervalSince1970) + 60)
            let url = Self.billingURL(yearMonth: ym)
            let headers = Self.signedHeaders(
                method: "GET",
                path: url.path,
                query: "format=json",
                apiKey: apiKey,
                secret: secret,
                expires: expires
            )
            let data = try await ProviderHTTP.get(
                url: url, headers: headers, client: httpClient, providerID: .idcf
            )
            let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .idcf)
            let amount = envelope.meta?.total?.value
                ?? envelope.data?.meta?.total?.value
                ?? 0
            guard amount != 0 else { continue }
            let stamp = envelope.meta?.billingPeriodStartAt
                .flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? envelope.data?.meta?.billingPeriodStartAt
                .flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? monthStart
            if current.contains(stamp) || calendar.isDate(stamp, equalTo: current.start, toGranularity: .month) {
                currentTotal += amount
                daily.add(day: current.contains(stamp) ? stamp : current.start, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "invoice",
                        label: ym,
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

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .idcf
        )
        return Snapshot(
            providerID: .idcf,
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
            format: "%04d-%02d",
            calendar.component(.year, from: date),
            calendar.component(.month, from: date)
        )
    }

    static func billingURL(yearMonth: String) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/api/v1/billings/\(yearMonth)",
            query: [URLQueryItem(name: "format", value: "json")]
        )
    }

    static func signedHeaders(
        method: String,
        path: String,
        query: String,
        apiKey: String,
        secret: String,
        expires: String
    ) -> [String: String] {
        [
            "X-IDCF-APIKEY": apiKey,
            "X-IDCF-Expires": expires,
            "X-IDCF-Signature": signature(
                method: method, path: path, query: query,
                apiKey: apiKey, secret: secret, expires: expires
            ),
            "Accept": "application/json",
        ]
    }

    static func signature(
        method: String,
        path: String,
        query: String,
        apiKey: String,
        secret: String,
        expires: String
    ) -> String {
        let message = "\(method)\n\(path)\n\(apiKey)\n\(expires)\n\(query)"
        let mac = MeterHMAC.sha256(key: Data(secret.utf8), message: Data(message.utf8))
        return Data(mac).base64EncodedString()
    }

    struct Envelope: Decodable, Sendable {
        var meta: Meta?
        var data: Nested?
    }

    struct Nested: Decodable, Sendable {
        var meta: Meta?
    }

    struct Meta: Decodable, Sendable {
        var total: FlexibleDecimal?
        var billingPeriodStartAt: String?

        enum CodingKeys: String, CodingKey {
            case total
            case billingPeriodStartAt = "billing_period_start_at"
        }
    }
}
