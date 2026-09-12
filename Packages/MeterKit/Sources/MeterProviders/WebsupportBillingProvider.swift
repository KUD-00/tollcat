import Foundation
import MeterCore

/// Websupport 本月正式发票合计（`price` / `priceWithVat` + `currency`）。
///
/// 文档：`GET /v1/user/:userId/invoice`（`rest.websupport.se` / `.sk`）
/// 认证：HTTP Basic `apiKey:HMAC-SHA1(secret, "GET {path} {unix}")` + `Date`（GMT）。
/// 仅累计 `type == "invoice"`；优先 `priceWithVat`，回退 `price`。
public struct WebsupportBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.websupport }

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
        let rawUser = try RequiredCredential.value(.accountID, in: credential, providerID: .websupport)
        let host = Self.host(userIdRaw: rawUser)
        let userId: String = {
            if let idx = rawUser.lastIndex(of: "|") {
                return String(rawUser[..<idx])
            }
            return rawUser
        }()
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .websupport)
        let secret = try RequiredCredential.value(.apiToken, in: credential, providerID: .websupport)
        let path = "/v1/user/\(userId)/invoice"
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var page = 1
        while page <= 50 {
            let query = "?page=\(page)&pagesize=50"
            let signedPath = path + query
            let headers = Self.signedHeaders(
                method: "GET",
                path: signedPath,
                apiKey: apiKey,
                secret: secret,
                now: now
            )
            let data = try await ProviderHTTP.get(
                url: ProviderURL.https(host: host, path: path, query: [
                    URLQueryItem(name: "page", value: String(page)),
                    URLQueryItem(name: "pagesize", value: "50"),
                ]),
                headers: headers,
                client: httpClient,
                providerID: .websupport
            )
            let payload = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .websupport)
            let items = payload.items ?? []
            for invoice in items {
                let type = invoice.type?.trimmed ?? ""
                guard type == "invoice" else { continue }
                try currencies.observe(invoice.currency, providerID: .websupport)
                let amount = invoice.priceWithVat?.value ?? invoice.price?.value ?? 0
                guard amount != 0 else { continue }
                let stamp: Date
                if let unix = invoice.createTime?.value {
                    stamp = Date(timeIntervalSince1970: NSDecimalNumber(decimal: unix).doubleValue)
                } else {
                    stamp = current.start
                }
                if current.contains(stamp) {
                    currentTotal += amount
                    for line in invoice.items ?? [] {
                        let lineAmount = line.priceWithVat?.value ?? line.price?.value ?? 0
                        guard lineAmount != 0 else { continue }
                        lines.add(
                            SpendLine(
                                category: line.serviceName?.trimmed ?? "service",
                                label: line.name?.trimmed ?? line.serviceName?.trimmed ?? "item",
                                amountUSD: Money(usd: lineAmount)
                            )
                        )
                    }
                } else if horizon == .availableHistory {
                    daily.addPastMonth(
                        start: stamp,
                        amount: Money(usd: amount),
                        current: current,
                        calendar: calendar
                    )
                }
            }
            if items.count < 50 { break }
            page += 1
        }

        let converted = try currencies.convert(currentTotal, rates: rateSource.current, providerID: .websupport)
        return Snapshot(
            providerID: .websupport,
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

    /// `accountID` 以 `|sk` 结尾时走 `rest.websupport.sk`，否则默认 `.se`。
    static func host(userIdRaw: String) -> String {
        if userIdRaw.lowercased().hasSuffix("|sk") {
            return "rest.websupport.sk"
        }
        return "rest.websupport.se"
    }

    static func signedHeaders(
        method: String,
        path: String,
        apiKey: String,
        secret: String,
        now: Date
    ) -> [String: String] {
        let unix = Int(now.timeIntervalSince1970)
        let canonical = "\(method) \(path) \(unix)"
        let mac = MeterHMAC.sha1(key: Data(secret.utf8), message: Data(canonical.utf8))
        let signature = mac.map { String(format: "%02x", $0) }.joined()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return [
            "Authorization": "Basic \(ProviderOAuth.basicValue(id: apiKey, secret: signature))",
            "Date": formatter.string(from: now),
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
    }

    struct Envelope: Decodable, Sendable {
        var items: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: FlexibleDecimal?
        var type: String?
        var number: String?
        var createTime: FlexibleDecimal?
        var price: FlexibleDecimal?
        var priceWithVat: FlexibleDecimal?
        var currency: String?
        var items: [Line]?
    }

    struct Line: Decodable, Sendable {
        var serviceName: String?
        var name: String?
        var price: FlexibleDecimal?
        var priceWithVat: FlexibleDecimal?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
