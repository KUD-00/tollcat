import Foundation
import MeterCore

/// OVHcloud APIv6：`GET /me/bill` → `GET /me/bill/{billId}` →
/// `priceWithTax.value` + `priceWithTax.currencyCode`（order.Price）。
///
/// 文档：https://api.ovh.com/console/#/me/bill~GET
/// Host：`eu.api.ovh.com`（`/1.0`）。认证：OVH 签名头
/// `X-Ovh-Application` + `X-Ovh-Consumer` + `X-Ovh-Timestamp` + `X-Ovh-Signature`
///（AK=`accessKeyID`，AS=`apiToken`，CK=`clientSecret`）。
public struct OVHCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.ovhcloud }

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
        let appKey = try RequiredCredential.value(.accessKeyID, in: credential, providerID: .ovhcloud)
        let appSecret = try RequiredCredential.value(.apiToken, in: credential, providerID: .ovhcloud)
        let consumerKey = try RequiredCredential.value(.clientSecret, in: credential, providerID: .ovhcloud)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal = Decimal(0)

        let listData = try await Self.signedGET(
            path: "/me/bill",
            appKey: appKey,
            appSecret: appSecret,
            consumerKey: consumerKey,
            now: now,
            client: httpClient
        )
        let billIDs = try ProviderHTTP.decode([String].self, from: listData, providerID: .ovhcloud)

        for billID in billIDs.prefix(200) {
            let detailData = try await Self.signedGET(
                path: "/me/bill/\(billID)",
                appKey: appKey,
                appSecret: appSecret,
                consumerKey: consumerKey,
                now: now,
                client: httpClient
            )
            let bill = try ProviderHTTP.decode(Bill.self, from: detailData, providerID: .ovhcloud)
            let amount = bill.priceWithTax?.value?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe(bill.priceWithTax?.currencyCode, providerID: .ovhcloud)
            let stamp = bill.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "bill",
                        label: bill.billId ?? billID,
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
            providerID: .ovhcloud
        )
        return Snapshot(
            providerID: .ovhcloud,
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

    static func signedGET(
        path: String,
        appKey: String,
        appSecret: String,
        consumerKey: String,
        now: Date,
        client: any HTTPClient
    ) async throws -> Data {
        let host = "eu.api.ovh.com"
        let urlPath = "/1.0\(path)"
        let url = ProviderURL.https(host: host, path: urlPath)
        let ts = String(Int(now.timeIntervalSince1970))
        let toSign = "\(appSecret)+\(consumerKey)+GET+\(url.absoluteString)++\(ts)"
        let digest = MeterDigest.sha1(Data(toSign.utf8))
        let signature = "$1$\(digest.map { String(format: "%02x", $0) }.joined())"
        return try await ProviderHTTP.get(
            url: url,
            headers: [
                "X-Ovh-Application": appKey,
                "X-Ovh-Consumer": consumerKey,
                "X-Ovh-Timestamp": ts,
                "X-Ovh-Signature": signature,
            ],
            client: client,
            providerID: .ovhcloud
        )
    }

    struct Bill: Decodable, Sendable {
        var billId: String?
        var date: String?
        var priceWithTax: Price?
    }

    struct Price: Decodable, Sendable {
        var value: FlexibleDecimal?
        var currencyCode: String?
    }
}
