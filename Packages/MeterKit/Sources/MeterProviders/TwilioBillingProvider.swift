import Foundation
import MeterCore

/// Twilio Usage Records。
///
/// 合计：`GET .../Usage/Records/Daily.json?Category=totalprice`
/// 明细：同窗 `GET .../Usage/Records.json`，不带 Category，每个 usage category 一条。
/// 认证：HTTP Basic，用户名 API Key SID（`SK…`），密码 API Key Secret。
/// Account SID 只出现在 URL 路径，不进 Basic。
///
/// 日线和本月合计**只认 totalprice**。分类是父子树（`sms` 含 `sms-inbound` 含
/// `sms-inbound-shortcode`），加总会双计；官方也说各类 Price 之和不一定等于
/// totalprice。明细丢掉 `totalprice`、丢掉有子类的父节点、丢掉零元行，只把
/// 有钱的叶子写成 `SpendLine`。
///
/// `StartDate` / `EndDate` 按 Twilio 文档是 GMT。设备日历在东边时区会先跨月，
/// 把还没开始的 GMT 日写进去，Daily 对空窗回 20404。EndDate 钳到 GMT 今天；
/// 整段都在未来就当本月 $0。单日窗口的 20404 也当空月，整月 404 仍往上抛。
public struct TwilioBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.twilio }
    static let maxPages = 20
    /// Twilio 上限 1000。分类列表很长，一次尽量拿完，少翻页。
    static let categoryPageSize = 1000

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar
    /// 厂商用非美元结算时按这张表换。默认只认美元，行为和加它之前一样。
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
        var currency = CurrencyAccumulator()
        let sid = try RequiredCredential.value(.accountID, in: credential, providerID: .twilio)
        let keySID = try RequiredCredential.value(.accessKeyID, in: credential, providerID: .twilio)
        let secret = try RequiredCredential.value(.apiToken, in: credential, providerID: .twilio)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let fetchWindow = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let headers = [
            "Authorization": Self.basicAuthorization(username: keySID, password: secret),
        ]

        let dailyRecords = try await loadDaily(
            accountSID: sid,
            from: fetchWindow.start,
            to: now,
            headers: headers
        )
        var daily = DailySpendAccumulator()
        for record in dailyRecords {
            try currency.observe(record.price_unit, providerID: .twilio)
            let amount = record.price?.money ?? .zero
            let day = record.start_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            daily.add(day: day, amount: amount)
        }

        let monthSpend = daily.total(in: current, calendar: calendar)
        var lines = SpendLineAccumulator()
        // 合计已经是 0 时，分类接口会回几百条零元行，没有可画的细则。
        // 历史窗口的日线可以很长，明细仍只问本月——分类加总跨月会和本月数字对不上。
        if monthSpend != .zero {
            let categoryRecords = try await loadPages(
                startingAt: Self.categoryURL(
                    accountSID: sid,
                    from: current.start,
                    to: now,
                    calendar: calendar
                ),
                headers: headers
            )
            for record in categoryRecords {
                try currency.observe(record.price_unit, providerID: .twilio)
            }
            for line in Self.lines(from: categoryRecords) {
                lines.add(line)
            }
        }

        return try Snapshot(
            providerID: .twilio,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: monthSpend,
            dailyUSD: daily.snapshotDaily ?? [:],
            lines: lines.snapshot
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    static func dailyURL(accountSID: String, from: Date, to: Date, calendar: Calendar) -> URL {
        usageURL(
            path: "/2010-04-01/Accounts/\(accountSID)/Usage/Records/Daily.json",
            from: from,
            to: to,
            calendar: calendar,
            extra: [
                URLQueryItem(name: "Category", value: "totalprice"),
                URLQueryItem(name: "PageSize", value: String(categoryPageSize)),
            ]
        )
    }

    static func categoryURL(accountSID: String, from: Date, to: Date, calendar: Calendar) -> URL {
        usageURL(
            path: "/2010-04-01/Accounts/\(accountSID)/Usage/Records.json",
            from: from,
            to: to,
            calendar: calendar,
            extra: [URLQueryItem(name: "PageSize", value: String(categoryPageSize))]
        )
    }

    /// Twilio 按 GMT 读这两个日期。本地日历比 GMT 快一天时，把 EndDate 钳回去；
    /// 整段都还没开始就返回 `nil`，调用方不要打 Daily。
    static func queryDateRange(from: Date, to: Date, calendar: Calendar) -> (start: String, end: String)? {
        let start = dayString(from, calendar: calendar)
        let localEnd = dayString(to, calendar: calendar)
        let gmtToday = dayString(to, calendar: gmtCalendar)
        let end = min(localEnd, gmtToday)
        guard start <= end else { return nil }
        return (start, end)
    }

    private static var gmtCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func dayString(_ date: Date, calendar: Calendar) -> String {
        CalendarMonthWindow.current(now: date, calendar: calendar)
            .dayString(date, calendar: calendar)
    }

    private static func usageURL(
        path: String,
        from: Date,
        to: Date,
        calendar: Calendar,
        extra: [URLQueryItem]
    ) -> URL {
        let dates = queryDateRange(from: from, to: to, calendar: calendar)
            ?? (start: dayString(from, calendar: calendar), end: dayString(to, calendar: calendar))
        var query = extra
        query.append(URLQueryItem(name: "StartDate", value: dates.start))
        query.append(URLQueryItem(name: "EndDate", value: dates.end))
        return ProviderURL.https(host: apiHost, path: path, query: query)
    }

    static let apiHost = "api.twilio.com"

    /// 分页地址来自厂商响应，按不可信输入处理（同 `ConfluentBillingProvider.nextPageURL`）。
    /// 绝对 URL 必须是 https 且 host 正好是本家——白名单是整段相等匹配，`github.com`
    /// 这类也在名单里，不钉死就能把 `Basic(keySID:secret)` 送到别人家。
    static func absoluteURL(from nextPageURI: String) -> URL? {
        if let absolute = URL(string: nextPageURI), absolute.host != nil {
            guard absolute.scheme == "https", absolute.host == apiHost else { return nil }
            return absolute
        }
        // 相对路径才拼到官方 host；不以 / 开头的一律不认。
        guard nextPageURI.hasPrefix("/") else { return nil }
        return URL(string: "https://\(apiHost)\(nextPageURI)")
    }

    static func basicAuthorization(username: String, password: String) -> String {
        let raw = Data("\(username):\(password)".utf8).base64EncodedString()
        return "Basic \(raw)"
    }

    /// 有钱的叶子 → 明细。`sms-inbound-shortcode` 的产品线是第一段 `sms`，
    /// 行名用厂商 `description`，不自己翻译。
    static func lines(from records: [Record]) -> [SpendLine] {
        let billed = records.filter(\.isLineCandidate)
        let categories = Set(billed.compactMap(\.normalizedCategory))
        var accumulator = SpendLineAccumulator()
        for record in billed {
            guard let line = line(from: record, among: categories) else { continue }
            accumulator.add(line)
        }
        return accumulator.snapshot ?? []
    }

    static func line(from record: Record, among categories: Set<String>) -> SpendLine? {
        guard let category = record.normalizedCategory else { return nil }
        guard !isParent(category, among: categories) else { return nil }
        let label = record.description?.trimmed ?? category
        let unit = record.usageUnitForQuantity
        return SpendLine(
            category: family(of: category),
            label: label,
            amountUSD: record.price?.money ?? .zero,
            quantity: unit == nil ? nil : record.usage?.value,
            unit: unit
        )
    }

    /// `sms-inbound` 在集合里还有 `sms-inbound-shortcode` 时，前者是汇总。
    static func isParent(_ category: String, among categories: Set<String>) -> Bool {
        let prefix = category + "-"
        return categories.contains { $0.hasPrefix(prefix) }
    }

    static func family(of category: String) -> String {
        guard let dash = category.firstIndex(of: "-") else { return category }
        return String(category[..<dash])
    }

    private func loadDaily(
        accountSID: String,
        from: Date,
        to: Date,
        headers: [String: String]
    ) async throws -> [Record] {
        guard let range = Self.queryDateRange(from: from, to: to, calendar: calendar) else {
            return []
        }
        do {
            return try await loadPages(
                startingAt: Self.dailyURL(
                    accountSID: accountSID,
                    from: from,
                    to: to,
                    calendar: calendar
                ),
                headers: headers
            )
        } catch let error as ProviderError where error.code == .billingAPIUnavailable {
            // 单日空窗（新月第一天）Daily 回 20404。整月 404 更像 SID 错了或接口没了。
            if range.start == range.end { return [] }
            throw error
        }
    }

    private func loadPages(startingAt url: URL, headers: [String: String]) async throws -> [Record] {
        var records: [Record] = []
        var next: URL? = url
        var pages = 0
        while let url = next {
            pages += 1
            let data = try await ProviderHTTP.get(
                url: url,
                headers: headers,
                client: httpClient,
                providerID: .twilio
            )
            let page = try ProviderHTTP.decode(Page.self, from: data, providerID: .twilio)
            records.append(contentsOf: page.usage_records ?? [])
            next = page.next_page_uri.flatMap(Self.absoluteURL(from:))
            // 打满上限还有下一页：截断的合计不是完整账单，宁可失败（同 Stripe）。
            if next != nil, pages >= Self.maxPages {
                throw ProviderError.malformedResponse(providerID: .twilio)
            }
        }
        return records
    }

    struct Page: Decodable, Sendable {
        var usage_records: [Record]?
        var next_page_uri: String?
    }

    struct Record: Decodable, Sendable {
        var category: String?
        var description: String?
        var price: FlexibleDecimal?
        var price_unit: String?
        var usage: FlexibleDecimal?
        var usage_unit: String?
        var start_date: String?
        var end_date: String?

        var normalizedCategory: String? { category?.trimmed }

        var isLineCandidate: Bool {
            guard let category = normalizedCategory else { return false }
            guard category.lowercased() != "totalprice" else { return false }
            return (price?.money ?? .zero) != .zero
        }

        /// `usage_unit` 和 `price_unit` 相同时，usage 只是把价钱又写一遍，不是用量。
        var usageUnitForQuantity: String? {
            guard let unit = usage_unit?.trimmed else { return nil }
            if let priceUnit = price_unit?.trimmed, unit.lowercased() == priceUnit.lowercased() {
                return nil
            }
            return unit
        }
    }
}

private extension String {
    /// 空字符串当没有：厂商偶尔回 `""` 而不是省略字段，别让界面出现空白分类。
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
