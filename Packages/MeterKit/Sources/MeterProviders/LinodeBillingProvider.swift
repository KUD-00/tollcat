import Foundation
import MeterCore

/// Linode（Akamai）本月未出账余额。
///
/// 文档：`GET /v4/account`
/// 认证：PAT，`Authorization: Bearer`，OAuth scope `account:read_only`。
///
/// `balance_uninvoiced` 是当期估出发票美元。传输超额不在这个字段里。
/// 官方说明这是估算，不是最终账单。
public struct LinodeBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.linode }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .linode)
        let headers = [
            "Authorization": "Bearer \(token)",
        ]
        let data = try await ProviderHTTP.get(
            url: Self.accountURL,
            headers: headers,
            client: httpClient,
            providerID: .linode
        )
        let payload = try ProviderHTTP.decode(Account.self, from: data, providerID: .linode)
        guard let usage = payload.balance_uninvoiced?.value else {
            throw ProviderError.malformedResponse(providerID: .linode)
        }
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        var daily = DailySpendAccumulator()
        if horizon == .availableHistory {
            let invoicesData = try await ProviderHTTP.get(
                url: Self.invoicesURL,
                headers: headers,
                client: httpClient,
                providerID: .linode
            )
            let list = try ProviderHTTP.decode(InvoiceList.self, from: invoicesData, providerID: .linode)
            for invoice in list.data ?? [] {
                let amount = invoice.total?.value ?? 0
                let start = invoice.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
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
            providerID: .linode,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: Money(usd: usage),
            dailyUSD: daily.snapshotDaily
        )
    }

    static let accountURL = URL(string: "https://api.linode.com/v4/account")!
    static let invoicesURL = URL(string: "https://api.linode.com/v4/account/invoices")!

    struct Account: Decodable, Sendable {
        var balance_uninvoiced: FlexibleDecimal?
        var balance: FlexibleDecimal?
    }

    struct InvoiceList: Decodable, Sendable {
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var date: String?
        var total: FlexibleDecimal?
    }
}
