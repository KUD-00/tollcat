import Foundation
import MeterCore

/// Soracom 用量账单：`GET /v1/bills/latest` → `amount` + `currency`（JPY|USD|EUR）；
/// 日粒度 `GET /v1/bills/{yyyyMM}/daily` → `DailyBill.amount` + `currency`。
///
/// 文档：https://developers.soracom.io/en/docs/account/billing/
/// OpenAPI：soracom-cli / developers.soracom.io/en/api
/// 认证：`X-Soracom-API-Key` + `X-Soracom-Token`；若仅有 AuthKey 则先 `POST /v1/auth`。
/// Host：`g.api.soracom.io`（全球）与 `api.soracom.io`（日本）。
public struct SoracomBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.soracom }

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
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let (apiKey, apiToken) = try await resolveAuth(credential: credential)
        let headers = [
            "X-Soracom-API-Key": apiKey,
            "X-Soracom-Token": apiToken,
            "Accept": "application/json",
        ]
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let latest = try await getLatest(headers: headers)
        if let amount = latest.amount?.value, amount != 0 {
            try currencies.observe(latest.currency, providerID: .soracom)
            currentTotal += amount
            lines.add(
                SpendLine(
                    category: "bill",
                    label: "latest",
                    amountUSD: Money(usd: amount)
                )
            )
        }

        let yyyyMM = Self.yearMonth(current.start, calendar: calendar)
        if let dailyBill = try? await getDaily(yyyyMM: yyyyMM, headers: headers) {
            for row in dailyBill.billList ?? [] {
                let amount = row.amount?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(row.currency ?? latest.currency, providerID: .soracom)
                let stamp = row.date.flatMap { Self.parseYMD($0, calendar: calendar) } ?? current.start
                if current.contains(stamp) {
                    if latest.amount == nil {
                        currentTotal += amount
                    }
                    daily.add(day: stamp, amount: Money(usd: amount))
                }
            }
        }

        if horizon == .availableHistory {
            let lookback = max(Self.descriptor.historyLookbackMonths, 1)
            for offset in 1 ..< lookback {
                guard let monthStart = calendar.date(
                    byAdding: .month, value: -offset, to: current.start
                ) else { continue }
                let ym = Self.yearMonth(monthStart, calendar: calendar)
                guard let bill = try? await getMonth(yyyyMM: ym, headers: headers) else { continue }
                let amount = bill.amount?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(bill.currency ?? latest.currency, providerID: .soracom)
                daily.addPastMonth(
                    start: monthStart,
                    amount: Money(usd: amount),
                    current: current,
                    calendar: calendar
                )
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .soracom
        )
        return Snapshot(
            providerID: .soracom,
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

    private func resolveAuth(credential: Credential) async throws -> (String, String) {
        if let key = credential.value(for: .apiKey), let token = credential.value(for: .apiToken),
           !key.isEmpty, !token.isEmpty
        {
            return (key, token)
        }
        let authKeyId = try RequiredCredential.value(.accessKeyID, in: credential, providerID: .soracom)
        let authKey = try RequiredCredential.value(.secretAccessKey, in: credential, providerID: .soracom)
        let body = try JSONSerialization.data(
            withJSONObject: ["authKeyId": authKeyId, "authKey": authKey]
        )
        let url = ProviderURL.https(host: Self.globalHost, path: "/v1/auth")
        let data = try await ProviderHTTP.post(
            url: url,
            headers: [
                "Content-Type": "application/json",
                "Accept": "application/json",
            ],
            body: body,
            client: httpClient,
            providerID: .soracom
        )
        let auth = try ProviderHTTP.decode(AuthResponse.self, from: data, providerID: .soracom)
        guard let key = auth.apiKey, let token = auth.token, !key.isEmpty, !token.isEmpty else {
            throw ProviderError.unauthorized(providerID: .soracom)
        }
        return (key, token)
    }

    private func getLatest(headers: [String: String]) async throws -> Bill {
        let data = try await get(path: "/v1/bills/latest", headers: headers)
        return try ProviderHTTP.decode(Bill.self, from: data, providerID: .soracom)
    }

    private func getMonth(yyyyMM: String, headers: [String: String]) async throws -> Bill {
        let data = try await get(path: "/v1/bills/\(yyyyMM)", headers: headers)
        return try ProviderHTTP.decode(Bill.self, from: data, providerID: .soracom)
    }

    private func getDaily(yyyyMM: String, headers: [String: String]) async throws -> DailyResponse {
        let data = try await get(path: "/v1/bills/\(yyyyMM)/daily", headers: headers)
        return try ProviderHTTP.decode(DailyResponse.self, from: data, providerID: .soracom)
    }

    private func get(path: String, headers: [String: String]) async throws -> Data {
        let url = ProviderURL.https(host: Self.globalHost, path: path)
        do {
            return try await ProviderHTTP.get(
                url: url, headers: headers, client: httpClient, providerID: .soracom
            )
        } catch {
            let jp = ProviderURL.https(host: Self.japanHost, path: path)
            return try await ProviderHTTP.get(
                url: jp, headers: headers, client: httpClient, providerID: .soracom
            )
        }
    }

    static let globalHost = "g.api.soracom.io"
    static let japanHost = "api.soracom.io"

    static func yearMonth(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d%02d", c.year ?? 0, c.month ?? 0)
    }

    static func parseYMD(_ raw: String, calendar: Calendar) -> Date? {
        let digits = raw.filter(\.isNumber)
        guard digits.count >= 8 else { return BillingDateParser.parse(raw, calendar: calendar) }
        var comps = DateComponents()
        comps.year = Int(digits.prefix(4))
        comps.month = Int(digits.dropFirst(4).prefix(2))
        comps.day = Int(digits.dropFirst(6).prefix(2))
        return calendar.date(from: comps)
    }

    struct AuthResponse: Decodable, Sendable {
        var apiKey: String?
        var token: String?
    }

    struct Bill: Decodable, Sendable {
        var amount: FlexibleDecimal?
        var currency: String?
        var yearMonth: String?
        var lastEvaluatedTime: String?
    }

    struct DailyResponse: Decodable, Sendable {
        var billList: [DailyBill]?
    }

    struct DailyBill: Decodable, Sendable {
        var amount: FlexibleDecimal?
        var currency: String?
        var date: String?
    }
}
