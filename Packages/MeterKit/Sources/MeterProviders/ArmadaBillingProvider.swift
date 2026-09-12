import Foundation
import MeterCore

/// Armada Delivery 周期结算发票（`GET /v2/invoices`）。
///
/// 文档：https://docs.armadadelivery.com/v2/invoices/
/// 认证：`Authorization: Key <apiKey>` + HMAC-SHA256
/// （`x-armada-timestamp` ms + `x-armada-signature`；payload = `ts.METHOD.pathWithQuery.body`）。
/// Host：`api.armadadelivery.com`。
/// 金额：`amount` + `currency`；周期 `periodBegin`/`periodEnd`。
/// **只计 `REGULAR`**；忽略 `TOPUP_WALLET` / `TAP_WALLET` 等钱包充值（prepaid）。
/// 凭据：`apiKey` + `clientSecret`（或 `secretAccessKey`）。
public struct ArmadaBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.armada }
    public static let apiHost = "api.armadadelivery.com"
    static let maxPages = 20
    static let pageSize = 100

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .armada)
        let secret: String
        if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .armada) {
            secret = primary
        } else {
            secret = try RequiredCredential.value(.secretAccessKey, in: credential, providerID: .armada)
        }
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var page = 1
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let batch = try await loadInvoices(page: page, apiKey: apiKey, secret: secret)
            if batch.isEmpty { break }
            for inv in batch {
                let type = (inv.type ?? "").uppercased()
                if type != "REGULAR" { continue }
                let status = (inv.status ?? "").uppercased()
                if status == "CANCELED" || status == "CANCELLED" { continue }
                let amount = inv.amount?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(inv.currency, providerID: .armada)
                let stamp = inv.periodBegin.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.periodEnd.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = inv.invoiceNo ?? inv.id ?? "invoice"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: inv.type ?? "REGULAR",
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
            if batch.count < Self.pageSize { break }
            page += 1
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .armada
        )
        return Snapshot(
            providerID: .armada,
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

    private func loadInvoices(page: Int, apiKey: String, secret: String) async throws -> [Invoice] {
        let path = "/v2/invoices?page=\(page)&perPage=\(Self.pageSize)&status=all"
        let url = ProviderURL.https(
            host: Self.apiHost,
            path: "/v2/invoices",
            query: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "perPage", value: String(Self.pageSize)),
                URLQueryItem(name: "status", value: "all"),
            ]
        )
        let signed = Self.sign(method: "GET", path: path, body: "", secret: secret, now: now())
        let data = try await ProviderHTTP.get(
            url: url,
            headers: [
                "Authorization": "Key \(apiKey)",
                "x-armada-timestamp": signed.timestamp,
                "x-armada-signature": signed.signature,
                "Accept": "application/json",
            ],
            client: httpClient,
            providerID: .armada
        )
        if let env = try? ProviderHTTP.decode(Envelope.self, from: data, providerID: .armada) {
            return env.invoices ?? env.data ?? []
        }
        return try ProviderHTTP.decode([Invoice].self, from: data, providerID: .armada)
    }

    static func sign(
        method: String,
        path: String,
        body: String,
        secret: String,
        now: Date
    ) -> (timestamp: String, signature: String) {
        let timestamp = String(Int((now.timeIntervalSince1970 * 1000).rounded()))
        let payload = "\(timestamp).\(method.uppercased()).\(path).\(body)"
        let mac = MeterHMAC.sha256(key: Data(secret.utf8), message: Data(payload.utf8))
        let signature = mac.map { String(format: "%02x", $0) }.joined()
        return (timestamp, signature)
    }

    /// 固定时间戳签名，仅测试用。
    static func signForTests(
        method: String,
        path: String,
        body: String,
        secret: String,
        timestampMillis: String
    ) -> String {
        let payload = "\(timestampMillis).\(method.uppercased()).\(path).\(body)"
        let mac = MeterHMAC.sha256(key: Data(secret.utf8), message: Data(payload.utf8))
        return mac.map { String(format: "%02x", $0) }.joined()
    }

    struct Envelope: Decodable, Sendable {
        var invoices: [Invoice]?
        var data: [Invoice]?
        var page: Int?
        var perPage: Int?
        var total: Int?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var invoiceNo: String?
        var type: String?
        var status: String?
        var amount: FlexibleDecimal?
        var currency: String?
        var periodBegin: String?
        var periodEnd: String?
        var createdAt: String?
    }
}
