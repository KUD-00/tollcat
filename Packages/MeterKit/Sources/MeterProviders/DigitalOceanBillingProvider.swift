import Foundation
import MeterCore

/// DigitalOcean 本月用量。
///
/// 文档：`GET /v2/customers/my/balance`
/// 认证：PAT，scope `billing:read`。`month_to_date_usage` 就是本周期已花。
///
/// 同一份响应里的 `account_balance` / `month_to_date_balance` 是上期结余加减本月
/// 用量后的应付或授信，不是预充值钱包。默认月末出票后付；有 credit 也只是抵扣，
/// 花费仍看 `month_to_date_usage`。改成 `.prepaid` 会让后付费账号把本月用量折成 $0；
/// 两个字段都填，折算会双计。
public struct DigitalOceanBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.digitalocean }

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(httpClient: any HTTPClient, now: @escaping @Sendable () -> Date, calendar: Calendar) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .digitalocean)
        let headers = [
            "Authorization": "Bearer \(token)",
        ]
        let data = try await ProviderHTTP.get(
            url: Self.balanceURL,
            headers: headers,
            client: httpClient,
            providerID: .digitalocean
        )
        let payload = try ProviderHTTP.decode(Balance.self, from: data, providerID: .digitalocean)
        guard let usage = payload.month_to_date_usage?.value else {
            throw ProviderError.malformedResponse(providerID: .digitalocean)
        }
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        var daily = DailySpendAccumulator()
        if horizon == .availableHistory {
            let invoicesData = try await ProviderHTTP.get(
                url: Self.invoicesURL,
                headers: headers,
                client: httpClient,
                providerID: .digitalocean
            )
            let list = try ProviderHTTP.decode(InvoiceList.self, from: invoicesData, providerID: .digitalocean)
            for invoice in list.invoices ?? [] {
                let amount = invoice.amount?.value ?? 0
                let start = invoice.invoice_period.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                guard amount != 0, let start else { continue }
                daily.addPastMonth(
                    start: start,
                    amount: Money(usd: amount),
                    current: window,
                    calendar: calendar
                )
            }
        }
        return Snapshot(
            providerID: .digitalocean,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: Money(usd: usage),
            dailyUSD: daily.snapshotDaily
        )
    }

    static let balanceURL = URL(string: "https://api.digitalocean.com/v2/customers/my/balance")!
    static let invoicesURL = URL(string: "https://api.digitalocean.com/v2/customers/my/invoices")!

    struct Balance: Decodable, Sendable {
        var month_to_date_usage: FlexibleDecimal?
        var account_balance: FlexibleDecimal?
        var month_to_date_balance: FlexibleDecimal?
    }

    struct InvoiceList: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var invoice_uuid: String?
        var amount: FlexibleDecimal?
        var invoice_period: String?
    }
}
