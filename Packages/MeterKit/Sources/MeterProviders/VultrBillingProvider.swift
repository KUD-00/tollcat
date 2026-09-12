import Foundation
import MeterCore

/// Vultr 当月待扣 + 账户余额。
///
/// 文档：`GET /v2/account`、`GET /v2/billing/pending-charges`
/// 认证：`Authorization: Bearer <API Key>`
///
/// 两个都打：`pending_charges` 是本月至今的合计，`pending-charges` 的行项目带
/// `start_date`，日粒度只能从行项目来。行项目缺日期时整笔并进月初，不丢钱。
public struct VultrBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.vultr }

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(httpClient: any HTTPClient, now: @escaping @Sendable () -> Date, calendar: Calendar) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        let now = now()
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .vultr)
        let headers = [
            "Authorization": "Bearer \(apiKey)",
        ]
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)

        let accountData = try await ProviderHTTP.get(
            url: Self.accountURL,
            headers: headers,
            client: httpClient,
            providerID: .vultr
        )
        let account = try ProviderHTTP.decode(AccountEnvelope.self, from: accountData, providerID: .vultr)

        let chargesData = try await ProviderHTTP.get(
            url: Self.pendingChargesURL,
            headers: headers,
            client: httpClient,
            providerID: .vultr
        )
        let charges = try ProviderHTTP.decode(
            PendingChargesEnvelope.self,
            from: chargesData,
            providerID: .vultr
        )

        let daily = Self.accumulate(
            items: charges.pending_charges ?? [],
            window: window,
            calendar: calendar
        )
        // 行项目合计和 /v2/account 的 pending_charges 对不上时以后者为准：
        // 那是 Vultr 自己要收的数，行项目只负责把它摊到天上。
        let headline = account.account?.pending_charges?.value ?? daily.total.usd

        return Snapshot(
            providerID: .vultr,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: Money(usd: headline),
            balanceUSD: account.account?.balance.map { Money(usd: $0.value) },
            dailyUSD: Self.rescaled(daily, to: headline, window: window)
        )
    }

    /// 行项目按 `start_date` 落到当月的某一天。落在窗口外的（跨月的月租）并进月初。
    static func accumulate(
        items: [PendingCharge],
        window: CalendarMonthWindow,
        calendar: Calendar
    ) -> DailySpendAccumulator {
        var daily = DailySpendAccumulator()
        for item in items {
            guard let total = item.total?.value, total != 0 else { continue }
            let parsed = item.start_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
            let day: Date
            if let parsed, window.contains(parsed) {
                day = parsed
            } else {
                day = window.start
            }
            daily.add(day: day, amount: Money(usd: total))
        }
        return daily
    }

    /// 让日线合计等于 headline：差额落在月初那天，图和总数才不会互相打脸。
    static func rescaled(
        _ daily: DailySpendAccumulator,
        to headline: Decimal,
        window: CalendarMonthWindow
    ) -> [Date: Money]? {
        guard var result = daily.snapshotDaily else { return nil }
        let delta = headline - daily.total.usd
        if delta != 0 {
            result[window.start, default: .zero] += Money(usd: delta)
        }
        return result
    }

    static let accountURL = URL(string: "https://api.vultr.com/v2/account")!
    static let pendingChargesURL = URL(string: "https://api.vultr.com/v2/billing/pending-charges")!

    struct AccountEnvelope: Decodable, Sendable {
        var account: Account?
    }

    struct Account: Decodable, Sendable {
        var balance: FlexibleDecimal?
        var pending_charges: FlexibleDecimal?
    }

    struct PendingChargesEnvelope: Decodable, Sendable {
        var pending_charges: [PendingCharge]?
    }

    struct PendingCharge: Decodable, Sendable {
        var description: String?
        var product: String?
        var start_date: String?
        var end_date: String?
        var total: FlexibleDecimal?
    }
}
