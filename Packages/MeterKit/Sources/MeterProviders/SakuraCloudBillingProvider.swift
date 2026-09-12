import Foundation
import MeterCore

/// さくらのクラウド請求：`GET …/api/system/1.0/bill/by-contract/{accountid}` →
/// `Bills[].Amount`（請求金額・税込の日本円）。
///
/// ドキュメント：https://manual.sakura.ad.jp/cloud/api/billapi.html
/// 認証：HTTP Basic（`apiToken`=Access Token，`apiKey`/`clientSecret`=Access Token Secret）。
/// 需要「請求閲覧」権限。`accountID`=プロジェクト/契約 ID（auth-status の Account.ID）。
/// Host：`secure.sakura.ad.jp`（ゾーン path 任意；账单按项目合计）。
public struct SakuraCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.sakuracloud }
    static let zoneBase = "/cloud/zone/tk1a/api/system/1.0"

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .sakuracloud)
        let secret = (credential.value(for: .apiKey) ?? credential.value(for: .clientSecret))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let secretValue = try {
            if let secret, !secret.isEmpty { return secret }
            return try RequiredCredential.value(.apiKey, in: credential, providerID: .sakuracloud)
        }()
        let accountID = try RequiredCredential.value(.accountID, in: credential, providerID: .sakuracloud)
        let basic = Data("\(token):\(secretValue)".utf8).base64EncodedString()
        let headers = [
            "Authorization": "Basic \(basic)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal = Decimal(0)

        // Amount 文档固定为税込日本円
        try currencies.observe("JPY", providerID: .sakuracloud)

        let url = ProviderURL.https(
            host: "secure.sakura.ad.jp",
            path: "\(Self.zoneBase)/bill/by-contract/\(accountID)"
        )
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .sakuracloud
        )
        let payload = try ProviderHTTP.decode(BillList.self, from: data, providerID: .sakuracloud)

        for bill in payload.Bills ?? [] {
            let amount = bill.Amount?.value ?? 0
            guard amount != 0 else { continue }
            let stamp = bill.Date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = bill.BillID.map(String.init) ?? "bill"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "bill",
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
            providerID: .sakuracloud
        )
        return Snapshot(
            providerID: .sakuracloud,
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

    struct BillList: Decodable, Sendable {
        var Bills: [Bill]?
        var Count: Int?
        var is_ok: Bool?
    }

    struct Bill: Decodable, Sendable {
        var BillID: Int?
        var Amount: FlexibleDecimal?
        var Date: String?
        var MemberID: String?
        var Paid: Bool?
    }
}
