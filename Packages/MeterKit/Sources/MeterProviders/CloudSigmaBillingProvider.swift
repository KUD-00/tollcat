import Foundation
import MeterCore

/// CloudSigma 用量账本（`GET /api/2.0/ledger/`）+ 币种（`GET /api/2.0/balance/`）。
///
/// 文档：https://docs.cloudsigma.com/en/latest/billing.html
/// 认证：HTTP Basic（`email`/`clientID` + `apiKey`/`apiToken`/`clientSecret`）。
/// Host：凭据 `projectID`（区位主机，如 `zrh.cloudsigma.com` / `sjc.cloudsigma.com`）。
/// 金额：账本行 `amount`（正数为用量扣费）；日期：`time` / `poll_time`。
/// **忽略** `/balance/` 的余额数值（预付 wallet）；只取其 `currency`。
public struct CloudSigmaBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.cloudsigma }
    static let maxPages = 30
    static let pageLimit = 100

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
        let host = try Self.resolveHost(credential: credential)
        let username: String
        if let primary = try? RequiredCredential.value(.email, in: credential, providerID: .cloudsigma) {
            username = primary
        } else {
            username = try RequiredCredential.value(.clientID, in: credential, providerID: .cloudsigma)
        }
        let password: String
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .cloudsigma) {
            password = primary
        } else if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .cloudsigma) {
            password = primary
        } else {
            password = try RequiredCredential.value(.clientSecret, in: credential, providerID: .cloudsigma)
        }
        let headers = [
            "Authorization": "Basic \(ProviderOAuth.basicValue(id: username, secret: password))",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let currency = try await loadCurrency(host: host, headers: headers)
        try currencies.observe(currency, providerID: .cloudsigma)

        var offset = 0
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let batch = try await loadLedger(host: host, offset: offset, headers: headers)
            if batch.objects.isEmpty { break }
            for row in batch.objects {
                let amount = row.amount?.value ?? 0
                // 正数 = 用量扣费；负数 = 充值/退款，不计为周期花费。
                guard amount > 0 else { continue }
                let stamp = row.time.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? row.poll_time.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = row.reason ?? row.id ?? "usage"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: "ledger",
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
            if batch.objects.count < Self.pageLimit { break }
            offset += Self.pageLimit
            if let total = batch.meta?.total_count, offset >= total { break }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .cloudsigma
        )
        return Snapshot(
            providerID: .cloudsigma,
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

    static func resolveHost(credential: Credential) throws -> String {
        let raw = credential.value(for: .projectID)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let raw, !raw.isEmpty else {
            throw ProviderError.missingCredential(providerID: .cloudsigma)
        }
        var host = raw
        if let url = URL(string: raw), let h = url.host, !h.isEmpty {
            host = h
        } else {
            host = raw
                .replacingOccurrences(of: "https://", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if let slash = host.firstIndex(of: "/") {
                host = String(host[..<slash])
            }
        }
        guard host.contains("cloudsigma") else {
            throw ProviderError.missingCredential(providerID: .cloudsigma)
        }
        return host
    }

    static func balanceURL(host: String) -> URL {
        ProviderURL.https(host: host, path: "/api/2.0/balance/")
    }

    static func ledgerURL(host: String, offset: Int) -> URL {
        ProviderURL.https(
            host: host,
            path: "/api/2.0/ledger/",
            query: [
                URLQueryItem(name: "limit", value: String(pageLimit)),
                URLQueryItem(name: "offset", value: String(offset)),
            ]
        )
    }

    private func loadCurrency(host: String, headers: [String: String]) async throws -> String {
        let data = try await ProviderHTTP.get(
            url: Self.balanceURL(host: host),
            headers: headers,
            client: httpClient,
            providerID: .cloudsigma
        )
        if let balance = try? ProviderHTTP.decode(Balance.self, from: data, providerID: .cloudsigma),
           let code = balance.currency?.trimmingCharacters(in: .whitespacesAndNewlines),
           !code.isEmpty {
            return code
        }
        if let envelope = try? ProviderHTTP.decode(BalanceList.self, from: data, providerID: .cloudsigma),
           let code = envelope.objects?.first?.currency?.trimmingCharacters(in: .whitespacesAndNewlines),
           !code.isEmpty {
            return code
        }
        return "USD"
    }

    private func loadLedger(host: String, offset: Int, headers: [String: String]) async throws -> LedgerPage {
        let data = try await ProviderHTTP.get(
            url: Self.ledgerURL(host: host, offset: offset),
            headers: headers,
            client: httpClient,
            providerID: .cloudsigma
        )
        return try ProviderHTTP.decode(LedgerPage.self, from: data, providerID: .cloudsigma)
    }

    struct Balance: Decodable, Sendable {
        var currency: String?
        var balance: FlexibleDecimal?
    }

    struct BalanceList: Decodable, Sendable {
        var objects: [Balance]?
    }

    struct LedgerPage: Decodable, Sendable {
        var meta: Meta?
        var objects: [LedgerRow] = []
    }

    struct Meta: Decodable, Sendable {
        var limit: Int?
        var offset: Int?
        var total_count: Int?
    }

    struct LedgerRow: Decodable, Sendable {
        var id: String?
        var amount: FlexibleDecimal?
        var reason: String?
        var time: String?
        var poll_time: String?
    }
}
