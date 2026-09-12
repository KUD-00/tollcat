import Foundation
import MeterCore

/// MongoDB Atlas 本计费周期的待结发票。
///
/// 文档：`GET /api/atlas/v2/orgs/{orgId}/invoices/pending`
/// 认证：服务账号 `client_credentials` 换 Bearer（`POST /api/oauth/token`）。
///
/// **不走 legacy API Key。** 那套是 HTTP Digest，需要在 401 challenge 上回签名，
/// 而 `HTTPClient` 这个接缝只交出 `URLRequest`，拿不到 challenge。向导里只给服务账号。
///
/// Atlas v2 的 `Accept` 必须带日期版本，否则 406。
public struct AtlasBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.atlas }
    public static let acceptVersion = "application/vnd.atlas.2023-01-01+json"

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
        let clientID = try RequiredCredential.value(.clientID, in: credential, providerID: .atlas)
        let clientSecret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .atlas)

        let token = try await ProviderOAuth.clientCredentialsToken(
            url: Self.tokenURL,
            basic: (id: clientID, secret: clientSecret),
            form: ["grant_type": "client_credentials"],
            client: httpClient,
            providerID: .atlas
        )
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": Self.acceptVersion,
        ]

        let orgID: String
        if let pinned = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !pinned.isEmpty {
            orgID = pinned
        } else {
            orgID = try await loadFirstOrganizationID(headers: headers)
        }

        let data = try await ProviderHTTP.get(
            url: Self.pendingInvoicesURL(orgID: orgID),
            headers: headers,
            client: httpClient,
            providerID: .atlas
        )
        let all = try Self.decodeInvoices(data)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        var pastDaily = DailySpendAccumulator()
        if horizon == .availableHistory {
            let historyData = try await ProviderHTTP.get(
                url: Self.invoicesURL(orgID: orgID),
                headers: headers,
                client: httpClient,
                providerID: .atlas
            )
            let history = try Self.decodeInvoices(historyData)
            for invoice in history {
                guard let range = Self.range(of: invoice, calendar: calendar) else { continue }
                pastDaily.addPastMonth(
                    start: range.start,
                    amount: Self.money(invoice.amountBilledCents ?? 0),
                    current: window,
                    calendar: calendar
                )
            }
        }
        // "pending" 是复数：月初交界时上个月那张还没结、这个月这张已经在攒，
        // 两张一起回来。全加进去等于把上月的钱记成本月的——行项目再被
        // `window.clamp` 拽进本月，图和总数一起错。只收和本月有重叠的。
        let invoices = Self.overlappingCurrentMonth(all, window: window, calendar: calendar)

        var daily = DailySpendAccumulator()
        var billedCents: Int64 = 0
        for invoice in invoices {
            billedCents += invoice.amountBilledCents ?? 0
            for item in invoice.lineItems ?? [] {
                guard let cents = item.totalPriceCents, cents != 0 else { continue }
                let day = item.startDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? window.start
                daily.add(day: window.clamp(day), amount: Self.money(cents))
            }
        }

        // 周期跟着"覆盖今天的那张"走，不是数组第一张——顺序是厂商说了算。
        let current = Self.currentInvoice(invoices, now: now, calendar: calendar)
        let period = BillingPeriodResolver.resolve(
            startRaw: current?.startDate,
            endRaw: current?.endDate,
            // Atlas 的 endDate 是下期开始那天，收进来要退一天，否则周期多算 24 小时。
            endConvention: .exclusive,
            fallback: window,
            calendar: calendar
        )
        // 行项目摊完和 amountBilledCents 差的那点（税、余额结转）落回月初，两个数字不打架。
        var dailyUSD = daily.snapshotDaily ?? [:]
        let headline = Self.money(billedCents)
        if headline.usd != daily.total.usd {
            dailyUSD[period.start, default: .zero] += Money(usd: headline.usd - daily.total.usd)
        }
        for (day, amount) in pastDaily.snapshotDaily ?? [:] {
            dailyUSD[day, default: .zero] += amount
        }

        return Snapshot(
            providerID: .atlas,
            kind: .usage,
            fetchedAt: now,
            periodStart: period.start,
            periodEnd: period.end,
            currentSpendUSD: headline,
            dailyUSD: dailyUSD.isEmpty ? nil : dailyUSD
        )
    }

    private func loadFirstOrganizationID(headers: [String: String]) async throws -> String {
        let data = try await ProviderHTTP.get(
            url: Self.organizationsURL,
            headers: headers,
            client: httpClient,
            providerID: .atlas
        )
        let payload = try ProviderHTTP.decode(OrganizationList.self, from: data, providerID: .atlas)
        guard let id = payload.results?.first?.id, !id.isEmpty else {
            throw ProviderError.malformedResponse(providerID: .atlas)
        }
        return id
    }

    static func money(_ cents: Int64) -> Money {
        Money(usd: Decimal(cents) / 100)
    }

    /// 账期和本月有重叠的发票。一张都判不出日期就照旧全收——单张的老路子不变，
    /// 宁可少筛也不要因为解析不出日期把唯一那张发票丢掉、显示 $0。
    static func overlappingCurrentMonth(
        _ invoices: [Invoice],
        window: CalendarMonthWindow,
        calendar: Calendar
    ) -> [Invoice] {
        let matched = invoices.filter { invoice in
            guard let range = range(of: invoice, calendar: calendar) else { return false }
            return range.start < window.nextStart && range.exclusiveEnd > window.start
        }
        return matched.isEmpty ? invoices : matched
    }

    /// 覆盖 `now` 的那张；都不覆盖就取账期最晚的，再不行才回落到第一张。
    static func currentInvoice(_ invoices: [Invoice], now: Date, calendar: Calendar) -> Invoice? {
        let dated = invoices.compactMap { invoice -> (Invoice, start: Date, exclusiveEnd: Date)? in
            guard let range = range(of: invoice, calendar: calendar) else { return nil }
            return (invoice, range.start, range.exclusiveEnd)
        }
        if let covering = dated.first(where: { $0.start <= now && $0.exclusiveEnd > now }) {
            return covering.0
        }
        if let latest = dated.max(by: { $0.start < $1.start }) {
            return latest.0
        }
        return invoices.first
    }

    /// `endDate` 是下期开始那天，本来就是开区间，这里不退一天——退一天是
    /// `BillingPeriodResolver` 出对外周期时的事，重叠判断要用原口径。
    private static func range(
        of invoice: Invoice,
        calendar: Calendar
    ) -> (start: Date, exclusiveEnd: Date)? {
        guard
            let startRaw = invoice.startDate,
            let endRaw = invoice.endDate,
            let start = BillingDateParser.parse(startRaw, calendar: calendar),
            let end = BillingDateParser.parse(endRaw, calendar: calendar),
            end > start
        else {
            return nil
        }
        return (start, end)
    }

    /// v2 列表接口包一层 `results`，但待结发票在部分部署上直接返回数组。两种都收。
    static func decodeInvoices(_ data: Data) throws -> [Invoice] {
        if let list = try? JSONDecoder().decode(InvoiceList.self, from: data), list.results != nil {
            return list.results ?? []
        }
        if let array = try? JSONDecoder().decode([Invoice].self, from: data) {
            return array
        }
        throw ProviderError.malformedResponse(providerID: .atlas)
    }

    static let tokenURL = URL(string: "https://cloud.mongodb.com/api/oauth/token")!
    static let organizationsURL = URL(string: "https://cloud.mongodb.com/api/atlas/v2/orgs")!

    static func pendingInvoicesURL(orgID: String) -> URL {
        return ProviderURL.https(host: "cloud.mongodb.com", path: "/api/atlas/v2/orgs/\(orgID)/invoices/pending")
    }

    static func invoicesURL(orgID: String) -> URL {
        ProviderURL.https(host: "cloud.mongodb.com", path: "/api/atlas/v2/orgs/\(orgID)/invoices")
    }

    struct OrganizationList: Decodable, Sendable {
        var results: [Organization]?
    }

    struct Organization: Decodable, Sendable {
        var id: String?
    }

    struct InvoiceList: Decodable, Sendable {
        var results: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var amountBilledCents: Int64?
        var startDate: String?
        var endDate: String?
        var statusName: String?
        var lineItems: [LineItem]?
    }

    struct LineItem: Decodable, Sendable {
        var startDate: String?
        var endDate: String?
        var totalPriceCents: Int64?
        var sku: String?
    }
}
