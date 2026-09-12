import Foundation
import MeterCore

/// Heroku 当月发票。
///
/// 文档：`GET /account/invoices`，`Accept: application/vnd.heroku+json; version=3`
/// 认证：`Authorization: Bearer <API Key>`
///
/// **走 `/account/invoices` 而不是 `/teams/{id}/usage/daily`。** 后者只对 Enterprise Team
/// 开放，而且给的是 credits 和 dyno 数不是美元，独立开发者的个人账号既够不着也用不上。
/// 发票这条个人账号能读，`total` 直接是美元。
///
/// 代价：Heroku 是月末出账，当月那张发票**不一定已经存在**。找不到就返回一条没有读数的
/// 快照（不是 $0），交给上层显示「这次没读到」。
public struct HerokuBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.heroku }
    public static let acceptVersion = "application/vnd.heroku+json; version=3"

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .heroku)
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL,
            headers: [
                "Authorization": "Bearer \(token)",
                "Accept": Self.acceptVersion,
            ],
            client: httpClient,
            providerID: .heroku
        )
        let invoices = try ProviderHTTP.decode([Invoice].self, from: data, providerID: .heroku)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        var daily = DailySpendAccumulator()
        if horizon == .availableHistory {
            for invoice in invoices {
                let amount = invoice.total?.value ?? invoice.charges_total?.value ?? 0
                guard amount != 0 else { continue }
                let start = invoice.period_start.flatMap { Self.parseSlashDate($0, calendar: calendar) }
                guard let start else { continue }
                daily.addPastMonth(
                    start: start,
                    amount: Money(usd: amount),
                    current: window,
                    calendar: calendar
                )
            }
        }

        guard let current = Self.currentMonthInvoice(invoices, window: window, calendar: calendar) else {
            return Snapshot(
                providerID: .heroku,
                kind: .usage,
                fetchedAt: now,
                periodStart: window.start,
                periodEnd: window.endInclusive,
                dailyUSD: daily.snapshotDaily
            )
        }

        return Snapshot(
            providerID: .heroku,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: Money(usd: current.total?.value ?? current.charges_total?.value ?? 0),
            dailyUSD: daily.snapshotDaily
        )
    }

    /// 周期起点落在本月的那张就是当月账。列表按时间倒序不一定稳，全表扫。
    static func currentMonthInvoice(
        _ invoices: [Invoice],
        window: CalendarMonthWindow,
        calendar: Calendar
    ) -> Invoice? {
        invoices.first { invoice in
            guard let raw = invoice.period_start,
                  let start = parseSlashDate(raw, calendar: calendar) else {
                return false
            }
            return window.contains(start)
        }
    }

    /// Heroku 发票的日期是 `01/31/2014` 这种美式写法，`BillingDateParser` 认不出来。
    static func parseSlashDate(_ raw: String, calendar: Calendar) -> Date? {
        let parts = raw.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "/")
        guard parts.count == 3,
              let month = Int(parts[0]),
              let day = Int(parts[1]),
              let year = Int(parts[2]) else {
            return BillingDateParser.parse(raw, calendar: calendar)
        }
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    static let invoicesURL = URL(string: "https://api.heroku.com/account/invoices")!

    struct Invoice: Decodable, Sendable {
        var id: String?
        var number: Int?
        var total: FlexibleDecimal?
        var charges_total: FlexibleDecimal?
        var credits_total: FlexibleDecimal?
        var period_start: String?
        var period_end: String?
        var state: Int?
    }
}
