import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// InterNetX AutoDNS 发票（`POST /invoice/_search`）。
///
/// 文档：https://help.internetx.com/display/APIXMLEN/Invoice+list
/// 认证：HTTP Basic + `X-Domainrobot-Context`（默认 `4`）。`User-Agent` 必填。
/// Host：`api.autodns.com`。
/// 金额：`amount`（NET）+ `vatAmount` → 应付总额 + `currency`。
/// 只计 `type == INVOICE` 且 `failed != true`。
/// 凭据：`clientID`/`email` + `clientSecret`/`apiToken`，可选 `accountID`=context。
public struct InterNetXBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.internetx }
    public static let apiHost = "api.autodns.com"
    public static let defaultContext = "4"
    public static let userAgent = "TollCat"

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
        let username: String
        if let primary = try? RequiredCredential.value(.clientID, in: credential, providerID: .internetx) {
            username = primary
        } else if let primary = try? RequiredCredential.value(.email, in: credential, providerID: .internetx) {
            username = primary
        } else {
            username = try RequiredCredential.value(.accountID, in: credential, providerID: .internetx)
        }
        let password: String
        if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .internetx) {
            password = primary
        } else if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .internetx) {
            password = primary
        } else {
            password = try RequiredCredential.value(.apiKey, in: credential, providerID: .internetx)
        }
        let contextRaw = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let context = (contextRaw?.isEmpty == false) ? contextRaw! : Self.defaultContext
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let from: Date
        if horizon == .availableHistory {
            from = calendar.date(byAdding: .month, value: -12, to: current.start) ?? current.start
        } else {
            from = current.start
        }
        let headers = [
            "Authorization": "Basic \(ProviderOAuth.basicValue(id: username, secret: password))",
            "X-Domainrobot-Context": context,
            "User-Agent": Self.userAgent,
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]
        let bodyObject: [String: Any] = [
            "view": [
                "limit": 100,
                "from": Self.iso(from),
                "to": Self.iso(current.endInclusive),
            ]
        ]
        let body = try JSONSerialization.data(withJSONObject: bodyObject)
        let data = try await ProviderHTTP.post(
            url: Self.searchURL,
            headers: headers,
            body: body,
            client: httpClient,
            providerID: .internetx
        )
        let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .internetx)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        for inv in envelope.data ?? [] {
            let type = (inv.type ?? "INVOICE").uppercased()
            guard type == "INVOICE" else { continue }
            if inv.failed == true { continue }
            let net = inv.amount?.value ?? 0
            let vat = inv.vatAmount?.value ?? 0
            let amount = net + vat
            guard amount != 0 else { continue }
            let currency = inv.currency?.trimmingCharacters(in: .whitespacesAndNewlines)
            try currencies.observe((currency?.isEmpty == false) ? currency! : "EUR", providerID: .internetx)
            let stamp = inv.created.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.number ?? inv.id.map(String.init) ?? "invoice"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
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

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .internetx
        )
        return Snapshot(
            providerID: .internetx,
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

    static let searchURL = ProviderURL.https(host: apiHost, path: "/v1/invoice/_search")

    static func iso(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    struct Envelope: Decodable, Sendable {
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: Int?
        var number: String?
        var amount: FlexibleDecimal?
        var vatAmount: FlexibleDecimal?
        var currency: String?
        var type: String?
        var failed: Bool?
        var created: String?
        var status: String?
    }
}
