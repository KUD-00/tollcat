import Foundation
import MeterCore

/// Cloudflare Billable Usage API。
///
/// 文档：
/// - `GET /client/v4/accounts/{account_id}/billable-usage`
/// - `GET /client/v4/accounts/{account_id}/billable-usage/info`
/// 认证：`Authorization: Bearer <API Token>`，`Account · Billing · Read`
///
/// 带日期时区间必须盖住该周期的锚点日，且不要把下一个锚点也包进去，
/// 否则 result 会空或只回其中一段——读数明细里 7.16 / 5.21 来回跳就是这个。
///
/// **不带 `from` / `to` 回多少天是厂商说了算，不要假设"只有当前周期"。**
/// 真账号实测（锚点 8 号，2026-08-27 拉）：不带日期那次回的是 2026-07-08 →
/// 08-26，当前周期和上一周期一起给。照"只有当前周期"去补上一周期，8/1–8/7
/// 会被加两遍，8 月合计从 8.75 变成 17.51。所以补周期前先看已有的行盖到哪，
/// 盖住的段不再请求，行也按天挡一道。
public struct CloudflareBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.cloudflare }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .cloudflare)
        let accountID = try RequiredCredential.value(.accountID, in: credential, providerID: .cloudflare)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let headers = ["Authorization": "Bearer \(token)"]

        // 不带日期先打一次：401 在这里就失败，不必先打 info。回的天数不作假设。
        var rows = try await loadRows(
            accountID: accountID,
            headers: headers,
            from: nil,
            to: nil
        )
        let cycle = try await resolveCycle(
            accountID: accountID,
            headers: headers,
            rows: rows,
            now: now,
            window: window
        )
        var covered = Self.coveredDays(in: rows, calendar: calendar)
        for period in Self.extraPeriods(
            for: horizon,
            cycle: cycle,
            window: window,
            calendar: calendar
        ) {
            // 上一次的行已经盖满这一段就别再要一遍。省一次请求是顺带的，
            // 主要是不给自己制造重叠。
            if Self.isCovered(period, by: covered, calendar: calendar) { continue }
            let extra = try await loadPeriod(
                period,
                accountID: accountID,
                headers: headers
            )
            Self.merge(extra, into: &rows, covered: &covered, calendar: calendar)
        }

        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        for row in rows {
            try currency.observe(row.BillingCurrency, providerID: .cloudflare)
            let amount = (row.BilledCost ?? row.ContractedCost ?? row.EffectiveCost)?.money ?? .zero
            let day = Self.day(of: row, calendar: calendar) ?? window.start
            daily.add(day: day, amount: amount)
            // 明细的口径要和 `currentSpendUSD` 一致：那个数只认日历月，
            // 明细跨到上一周期就会出现"分项合计比总数大"。
            // 也因为有这道窗，历史那次刷新照样能给出正确的本月明细，
            // 不用像 GitHub 那样整份跳过。
            if window.contains(day), let line = Self.line(from: row, amount: amount) {
                lines.add(line)
            }
        }

        let monthSpend = Self.spend(
            in: daily,
            from: window.start,
            before: window.nextStart,
            calendar: calendar
        )
        return try Snapshot(
            providerID: .cloudflare,
            kind: .usage,
            fetchedAt: now,
            periodStart: cycle.start,
            periodEnd: cycle.endInclusive(calendar: calendar),
            currentSpendUSD: monthSpend,
            dailyUSD: daily.snapshotDaily ?? [:],
            lines: lines.snapshot
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    /// 日历月合计要完整：周期从月中起，才去拉上一周期。历史再按锚点一段一段往回。
    /// 不一次覆盖两个锚点——那正是宽 `from`/`to` 会空或少一段的原因。
    static func extraPeriods(
        for horizon: BillingFetchHorizon,
        cycle: CloudflareBillingCycle,
        window: CalendarMonthWindow,
        calendar: Calendar
    ) -> [CloudflareBillingCycle] {
        switch horizon {
        case .currentMonth:
            guard cycle.overlapsPriorCycle(in: window) else { return [] }
            return [cycle.preceding(calendar: calendar)]
        case .availableHistory:
            return cycle.previousCycles(
                count: max(Self.descriptor.historyLookbackMonths, 1),
                calendar: calendar
            )
        }
    }

    /// FOCUS 行 → 明细。`ServiceFamilyName` 是产品线（Containers / Durable Objects /
    /// Workers KV / D1 / Browser Rendering），`ServiceName` 是这条服务本身。
    ///
    /// Cloudflare 没有第二个归属维度（这条接口不按 zone / bucket 切），`scope` 留空，
    /// 界面因此不会出「按归属」那个选择器——那是数据说了算，不是这里判断的。
    static func line(from row: Row, amount: Money) -> SpendLine? {
        let family = row.ServiceFamilyName?.collapsedWhitespace
        let service = row.ServiceName?.collapsedWhitespace
        guard let category = family ?? service, let raw = service ?? family else { return nil }
        let split = Self.splitAllowanceNote(raw)
        return SpendLine(
            category: category,
            label: split.name,
            amountUSD: amount,
            listUSD: row.ListCost?.money,
            quantity: row.ConsumedQuantity?.value,
            unit: row.ConsumedUnit?.collapsedWhitespace,
            allowanceNote: split.note
        )
    }

    /// `Container vCPU (First 375 vCPU-minutes included)` → 名字 + 括号里那句。
    ///
    /// 只拆**结尾**那一对括号，而且要求里面提到 included/free——`per GB`、
    /// `Oceania, Taiwan, and Korea` 这些逗号和括号不能被当成额度说明切掉。
    /// 认不出来就整串当名字，宁可标题长一点也不要切错。
    static func splitAllowanceNote(_ raw: String) -> (name: String, note: String?) {
        guard raw.hasSuffix(")"), let open = raw.lastIndex(of: "(") else { return (raw, nil) }
        let inside = String(raw[raw.index(after: open)..<raw.index(before: raw.endIndex)])
            .collapsedWhitespace
        guard let inside else { return (raw, nil) }
        let lowered = inside.lowercased()
        guard lowered.contains("included") || lowered.contains("free") else { return (raw, nil) }
        guard let name = String(raw[raw.startIndex..<open]).collapsedWhitespace else {
            return (raw, nil)
        }
        return (name, inside)
    }

    /// 行落在哪一天。解析不出日期的不算"盖到"，否则它会占掉真数据的位置。
    static func day(of row: Row, calendar: Calendar) -> Date? {
        let raw = row.ChargePeriodStart ?? row.BillingPeriodStart
        return raw
            .flatMap { BillingDateParser.parse($0, calendar: calendar) }
            .map { calendar.startOfDay(for: $0) }
    }

    static func coveredDays(in rows: [Row], calendar: Calendar) -> Set<Date> {
        Set(rows.compactMap { day(of: $0, calendar: calendar) })
    }

    /// 整段每一天都已经有行才算盖住。用区间端点判会把中间的空洞一起吞掉，
    /// 厂商真漏一天就少一天钱；多打一次请求是便宜的，`merge` 那关照样挡重复。
    static func isCovered(
        _ period: CloudflareBillingCycle,
        by covered: Set<Date>,
        calendar: Calendar
    ) -> Bool {
        var day = calendar.startOfDay(for: period.start)
        let end = calendar.startOfDay(for: period.endInclusive(calendar: calendar))
        while day <= end {
            guard covered.contains(day) else { return false }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day), next > day else {
                return false
            }
            day = next
        }
        return true
    }

    /// 按天挡重复：这一天已经有行了就整天丢掉，不做逐行比对——同一天的行来自
    /// 同一次结算，要么都有要么都没有。`covered` 等整批过完再并，否则一天里
    /// 的第一行会把同一天剩下的挡在外面。
    static func merge(
        _ extra: [Row],
        into rows: inout [Row],
        covered: inout Set<Date>,
        calendar: Calendar
    ) {
        for row in extra {
            guard let day = day(of: row, calendar: calendar) else {
                rows.append(row)
                continue
            }
            guard !covered.contains(day) else { continue }
            rows.append(row)
        }
        covered.formUnion(coveredDays(in: extra, calendar: calendar))
    }

    private func resolveCycle(
        accountID: String,
        headers: [String: String],
        rows: [Row],
        now: Date,
        window: CalendarMonthWindow
    ) async throws -> CloudflareBillingCycle {
        if let fromInfo = try await loadCycleFromInfo(
            accountID: accountID,
            headers: headers,
            now: now
        ) {
            return fromInfo
        }
        let billedStarts = rows.compactMap { row -> Date? in
            row.BillingPeriodStart.flatMap { BillingDateParser.parse($0, calendar: calendar) }
        }
        if let latest = billedStarts.max() {
            return CloudflareBillingCycle.containing(now: now, anchor: latest, calendar: calendar)
        }
        return CloudflareBillingCycle(
            start: window.start,
            nextStart: window.nextStart,
            anchorDay: 1
        )
    }

    /// 404 / 未覆盖：没有 info 也能取当前周期。401 / 403 / 429 照样失败。
    private func loadCycleFromInfo(
        accountID: String,
        headers: [String: String],
        now: Date
    ) async throws -> CloudflareBillingCycle? {
        do {
            let data = try await ProviderHTTP.get(
                url: Self.billableUsageInfoURL(accountID: accountID),
                headers: headers,
                client: httpClient,
                providerID: .cloudflare
            )
            let payload = try ProviderHTTP.decode(InfoEnvelope.self, from: data, providerID: .cloudflare)
            guard payload.success != false else { return nil }
            let anchors = (payload.result?.subscriptions ?? []).compactMap { subscription -> Date? in
                if let endRaw = subscription.end_timestamp,
                   let end = BillingDateParser.parse(endRaw, calendar: calendar),
                   end <= now {
                    return nil
                }
                return subscription.billing_cycle_anchor_timestamp
                    .flatMap { BillingDateParser.parse($0, calendar: calendar) }
            }
            return CloudflareBillingCycle.current(anchors: anchors, now: now, calendar: calendar)
        } catch let error as ProviderError where error.code == .billingAPIUnavailable {
            return nil
        }
    }

    private func loadPeriod(
        _ cycle: CloudflareBillingCycle,
        accountID: String,
        headers: [String: String]
    ) async throws -> [Row] {
        // `to` 用周期最后一天（含）。用 nextStart 会把下一个锚点日写进区间。
        try await loadRows(
            accountID: accountID,
            headers: headers,
            from: cycle.start,
            to: cycle.endInclusive(calendar: calendar)
        )
    }

    private func loadRows(
        accountID: String,
        headers: [String: String],
        from: Date?,
        to: Date?
    ) async throws -> [Row] {
        let payload = try await load(
            accountID: accountID,
            headers: headers,
            from: from,
            to: to
        )
        if payload.success == false {
            throw ProviderError.malformedResponse(providerID: .cloudflare)
        }
        return payload.result ?? []
    }

    private static func spend(
        in daily: DailySpendAccumulator,
        from start: Date,
        before end: Date,
        calendar: Calendar
    ) -> Money {
        guard let days = daily.snapshotDaily else { return .zero }
        return days.reduce(into: .zero) { sum, entry in
            let day = calendar.startOfDay(for: entry.key)
            guard day >= start, day < end else { return }
            sum += entry.value
        }
    }

    private func load(
        accountID: String,
        headers: [String: String],
        from: Date?,
        to: Date?
    ) async throws -> Envelope {
        let url = Self.billableUsageURL(accountID: accountID, from: from, to: to, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .cloudflare
        )
        return try ProviderHTTP.decode(Envelope.self, from: data, providerID: .cloudflare)
    }

    static func billableUsageURL(accountID: String, from: Date?, to: Date?, calendar: Calendar) -> URL {
        var items: [URLQueryItem] = []
        if let from {
            items.append(URLQueryItem(name: "from", value: dayQuery(from, calendar: calendar)))
        }
        if let to {
            items.append(URLQueryItem(name: "to", value: dayQuery(to, calendar: calendar)))
        }
        return ProviderURL.https(
            host: "api.cloudflare.com",
            path: "/client/v4/accounts/\(accountID)/billable-usage",
            query: items
        )
    }

    static func billableUsageInfoURL(accountID: String) -> URL {
        ProviderURL.https(
            host: "api.cloudflare.com",
            path: "/client/v4/accounts/\(accountID)/billable-usage/info"
        )
    }

    private static func dayQuery(_ date: Date, calendar: Calendar) -> String {
        CalendarMonthWindow.current(now: date, calendar: calendar).dayString(date, calendar: calendar)
    }

    struct Envelope: Decodable, Sendable {
        var success: Bool?
        var result: [Row]?
    }

    struct Row: Decodable, Sendable {
        var BilledCost: FlexibleDecimal?
        var ContractedCost: FlexibleDecimal?
        var EffectiveCost: FlexibleDecimal?
        /// 没被免费额度抵扣前的价。真账号上 `BilledCost` 常年是 0，
        /// 这一栏才说得清"额度替你挡了多少"。
        var ListCost: FlexibleDecimal?
        var BillingCurrency: String?
        var BillingPeriodStart: String?
        var ChargePeriodStart: String?
        var ChargePeriodEnd: String?
        var ServiceFamilyName: String?
        var ServiceName: String?
        var ConsumedQuantity: FlexibleDecimal?
        var ConsumedUnit: String?
    }

    struct InfoEnvelope: Decodable, Sendable {
        var success: Bool?
        var result: InfoResult?
    }

    struct InfoResult: Decodable, Sendable {
        var covered: Bool?
        var subscriptions: [InfoSubscription]?
    }

    struct InfoSubscription: Decodable, Sendable {
        var id: String?
        var billing_cycle_anchor_timestamp: String?
        var start_timestamp: String?
        var end_timestamp: String?
    }
}

private extension String {
    /// 去掉首尾空白，空串当没有。厂商偶尔回 `""` 而不是省略字段。
    var collapsedWhitespace: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
