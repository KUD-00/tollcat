import Foundation
import MeterCore

/// 演示数据的一套覆盖。覆盖文件和默认那份并排放在 `Fixtures/` 里，名字前面加
/// `<rawValue>-`；只有列到的那几个会被换掉，其余照旧读不带前缀的那份——所以一套
/// 覆盖只需要放「和默认不一样」的文件。
///
/// 为什么是前缀而不是子目录：`Package.swift` 里这个目录是 `.process("Fixtures")`，
/// SPM 会把它**压平**，`Fixtures/cn/openai.json` 和 `Fixtures/openai.json` 在包里
/// 会撞成「multiple resources named 'openai.json'」，连依赖都解不开。
///
/// 为什么要有这东西：**商店截图按语言上传，而中国大陆不许在元数据里出现
/// OpenAI / ChatGPT**（App Review Guideline 5，深度合成需持牌，见
/// `docs/appstore/review-reply-china-dst.md`）。zh-Hans 那一套图因此要一份不含
/// 这些名字的演示数据，en-US / ja 两套照旧。两套图共用一次构建，靠启动参数分流，
/// 不靠「跑之前先手改 fixture」——那种步骤迟早把合规改动静默冲掉。
public enum FixtureOverlay: String, Sendable, CaseIterable {
    /// 中国区那一套：OpenAI 退成未接入、预付范例给 DeepSeek（国内已备案）、
    /// 手动订阅不叫 ChatGPT / Midjourney。金额和曲线与默认那份逐一对齐，
    /// 所以合计、同比、续航天数都不变，版式不会因为换了数据而变形。
    case cn

    var filePrefix: String { "\(rawValue)-" }
}

/// 从 bundled JSON 读出 Snapshot。日期按传入的 `now` 落到「当前月」，不写死年份。
public enum FixtureLoader: Sendable {
    public static func isConnected(_ id: ProviderID, overlay: FixtureOverlay? = nil) throws -> Bool {
        try record(for: id, overlay: overlay).connected
    }

    /// 当前这一次刷新该看到的那条 Snapshot（预充值不含月初余额）。
    public static func snapshot(
        for id: ProviderID,
        now: Date,
        calendar: Calendar,
        overlay: FixtureOverlay? = nil
    ) throws -> Snapshot {
        let record = try record(for: id, overlay: overlay)
        return currentSnapshot(record: record, now: now, calendar: calendar)
    }

    /// 从传输层拿到的 JSON 解成 Snapshot。解析必须真的跑，不能再走另一套。
    public static func snapshot(
        from data: Data,
        providerID: ProviderID,
        now: Date,
        calendar: Calendar
    ) throws -> Snapshot {
        let record: FixtureRecord
        do {
            record = try JSONDecoder().decode(FixtureRecord.self, from: data)
        } catch {
            throw ProviderError.fixtureUnavailable(providerID: providerID)
        }
        return currentSnapshot(record: record, now: now, calendar: calendar)
    }

    /// 含预充值月初余额、上月同期在内的全部快照。仪表折算走这条。
    public static func snapshots(
        for id: ProviderID,
        now: Date,
        calendar: Calendar,
        overlay: FixtureOverlay? = nil
    ) throws -> [Snapshot] {
        let record = try record(for: id, overlay: overlay)
        guard record.connected else { return [] }
        var result: [Snapshot] = []
        appendMonthSlices(record: record, now: now, calendar: calendar, into: &result)
        result.append(contentsOf: historySnapshots(
            providerID: record.providerID,
            kind: record.kind,
            points: record.history ?? [],
            now: now,
            calendar: calendar,
            monthOffset: 0
        ))
        result.append(currentSnapshot(record: record, now: now, calendar: calendar))
        return result
    }

    /// 已接入各家的设计稿数字，给 Preview 和折算验收用。
    /// 没有演示 fixture 的家跳过——和 `DashboardFixtureSeeder.prepareConnections`
    /// 同一条策略：目录里的家远多于设计稿那几家，抛出去会让整个演示种子
    /// 一条都不写，而调用方是 `try?`，失败还是静默的。
    public static func designSnapshots(
        now: Date,
        calendar: Calendar,
        overlay: FixtureOverlay? = nil
    ) throws -> [Snapshot] {
        ProviderCatalog.offered.flatMap { descriptor in
            (try? snapshots(for: descriptor.id, now: now, calendar: calendar, overlay: overlay)) ?? []
        }
    }

    /// 设计稿里那笔「未来 7 天内扣款」的手动订阅。日期相对 `now`。
    public static func designSubscriptions(
        now: Date,
        calendar: Calendar,
        overlay: FixtureOverlay? = nil
    ) throws -> [MonthlySubscription] {
        guard let url = resourceURL(named: "manual-subscriptions", overlay: overlay) else { return [] }
        let data = try Data(contentsOf: url)
        let records = try JSONDecoder().decode([ManualSubscriptionFixture].self, from: data)
        return records.compactMap { $0.materialize(now: now, calendar: calendar) }
    }

    // MARK: - Bundle

    static func record(for id: ProviderID, overlay: FixtureOverlay? = nil) throws -> FixtureRecord {
        guard let url = resourceURL(named: id.rawValue, overlay: overlay) else {
            throw ProviderError.fixtureUnavailable(providerID: id)
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(FixtureRecord.self, from: data)
        } catch {
            throw ProviderError.fixtureUnavailable(providerID: id)
        }
    }

    /// 覆盖里有这个文件就用它，没有就落回默认那份——所以一套覆盖只放差异文件。
    /// `ProviderResourceLocator` 自己会在 Fixtures/ 子目录和根目录之间回退。
    private static func resourceURL(named name: String, overlay: FixtureOverlay?) -> URL? {
        if let overlay, let url = bundledURL(named: overlay.filePrefix + name) {
            return url
        }
        return bundledURL(named: name)
    }

    private static func bundledURL(named name: String) -> URL? {
        ProviderResourceLocator.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
    }

    // MARK: - Materialize

    private static func currentSnapshot(
        record: FixtureRecord,
        now: Date,
        calendar: Calendar
    ) -> Snapshot {
        let kind = ProviderCatalog.descriptor(id: record.providerID)?.kind ?? record.kind
        let period = billingPeriod(record: record, now: now, calendar: calendar)

        guard record.connected else {
            return Snapshot(
                providerID: record.providerID,
                kind: kind,
                fetchedAt: now,
                periodStart: period.start,
                periodEnd: period.end
            )
        }

        return Snapshot(
            providerID: record.providerID,
            kind: kind,
            fetchedAt: now,
            periodStart: period.start,
            periodEnd: period.end,
            currentSpendUSD: record.currentSpendUSD.map { Money(roundedUSD: $0) },
            balanceUSD: record.balanceUSD.map { Money(roundedUSD: $0) },
            committedMonthlyUSD: record.committedMonthlyUSD.map { Money(roundedUSD: $0) },
            chargeDayOfMonth: record.chargeDayOfMonth,
            freeQuotaUsedRatio: record.freeQuotaUsedRatio,
            dailyUSD: dailyUSD(record: record, now: now, calendar: calendar),
            lines: record.lines.map { $0.map(\.materialized) }
        )
    }

    private static func historySnapshots(
        providerID: ProviderID,
        kind: ProviderKind,
        points: [FixtureRecord.History],
        now: Date,
        calendar: Calendar,
        monthOffset: Int
    ) -> [Snapshot] {
        let resolvedKind = ProviderCatalog.descriptor(id: providerID)?.kind ?? kind
        let periodNow = shifted(now, byMonths: monthOffset, calendar: calendar)
        let period = (
            start: startOfMonth(now: periodNow, calendar: calendar),
            end: endOfMonth(now: periodNow, calendar: calendar)
        )
        return points.map { point in
            Snapshot(
                providerID: providerID,
                kind: resolvedKind,
                fetchedAt: resolveHistoryDate(
                    point,
                    now: now,
                    calendar: calendar,
                    monthOffset: monthOffset
                ),
                periodStart: period.start,
                periodEnd: period.end,
                balanceUSD: Money(roundedUSD: point.balanceUSD)
            )
        }
    }

    private static func appendMonthSlices(
        record: FixtureRecord,
        now: Date,
        calendar: Calendar,
        into result: inout [Snapshot]
    ) {
        var slices: [(offset: Int, month: FixtureRecord.PreviousMonth)] = []
        if let previous = record.previousMonth {
            slices.append((-(previous.monthsBack ?? 1), previous))
        }
        for older in record.olderMonths ?? [] {
            let back = older.monthsBack ?? 0
            guard back >= 2 else { continue }
            slices.append((-back, older))
        }
        for (offset, slice) in slices {
            result.append(contentsOf: historySnapshots(
                providerID: record.providerID,
                kind: record.kind,
                points: slice.history ?? [],
                now: now,
                calendar: calendar,
                monthOffset: offset
            ))
            if slice.hasPeriodMetrics {
                result.append(
                    monthSnapshot(
                        record: record,
                        previous: slice,
                        now: now,
                        calendar: calendar,
                        monthOffset: offset
                    )
                )
            }
        }
    }

    private static func monthSnapshot(
        record: FixtureRecord,
        previous: FixtureRecord.PreviousMonth,
        now: Date,
        calendar: Calendar,
        monthOffset: Int
    ) -> Snapshot {
        let kind = ProviderCatalog.descriptor(id: record.providerID)?.kind ?? record.kind
        let monthNow = shifted(now, byMonths: monthOffset, calendar: calendar)
        let startDay = previous.periodStartDayOfMonth ?? 1
        let start = resolveDay(
            startDay,
            now: now,
            calendar: calendar,
            allowMonthStart: true,
            monthOffset: monthOffset
        )
        // 默认周期停在那个月与 `now` 同日的那天，currentSpendUSD 才能直接当同期合计，不用再按整月摊。
        let endDay = previous.periodEndDayOfMonth
            ?? calendar.component(.day, from: monthNow)
        let end = resolveDay(
            endDay,
            now: now,
            calendar: calendar,
            allowMonthStart: true,
            monthOffset: monthOffset
        )
        return Snapshot(
            providerID: record.providerID,
            kind: kind,
            fetchedAt: monthNow,
            periodStart: start,
            periodEnd: end,
            currentSpendUSD: previous.currentSpendUSD.map { Money(roundedUSD: $0) },
            balanceUSD: previous.balanceUSD.map { Money(roundedUSD: $0) },
            committedMonthlyUSD: previous.committedMonthlyUSD.map { Money(roundedUSD: $0) },
            chargeDayOfMonth: previous.chargeDayOfMonth,
            freeQuotaUsedRatio: previous.freeQuotaUsedRatio,
            dailyUSD: dailyUSD(
                specs: previous.daily,
                now: now,
                calendar: calendar,
                monthOffset: monthOffset,
                before: monthNow
            )
        )
    }

    private static func resolveHistoryDate(
        _ point: FixtureRecord.History,
        now: Date,
        calendar: Calendar,
        monthOffset: Int
    ) -> Date {
        if let daysAgo = point.daysAgo {
            let origin = monthOffset == 0 ? now : shifted(now, byMonths: monthOffset, calendar: calendar)
            return calendar.date(byAdding: .day, value: -daysAgo, to: origin) ?? origin
        }
        let day: Int
        if point.sameDayAsNow == true {
            day = calendar.component(.day, from: now)
        } else {
            day = point.dayOfMonth ?? 1
        }
        return resolveDay(
            day,
            now: now,
            calendar: calendar,
            allowMonthStart: true,
            monthOffset: monthOffset
        )
    }

    private static func dailyUSD(
        record: FixtureRecord,
        now: Date,
        calendar: Calendar
    ) -> [Date: Money]? {
        dailyUSD(specs: record.daily, now: now, calendar: calendar, monthOffset: 0, before: now)
    }

    private static func dailyUSD(
        specs: [FixtureRecord.Daily]?,
        now: Date,
        calendar: Calendar,
        monthOffset: Int,
        before cutoff: Date
    ) -> [Date: Money]? {
        let amounts = FixtureRecord.expandedDailyAmounts(specs)
        guard !amounts.isEmpty else { return nil }

        var result: [Date: Money] = [:]
        var overflow = Money.zero
        for (dayOfMonth, usd) in amounts {
            let date = resolveDay(
                dayOfMonth,
                now: now,
                calendar: calendar,
                allowMonthStart: true,
                monthOffset: monthOffset
            )
            if date < cutoff {
                result[date, default: .zero] += Money(roundedUSD: usd)
            } else {
                overflow += Money(roundedUSD: usd)
            }
        }

        // 还没到的天数并进已经发生的第一天，避免月初跑起来总数对不上设计稿。
        if overflow > .zero {
            let monthStart = startOfMonth(
                now: shifted(now, byMonths: monthOffset, calendar: calendar),
                calendar: calendar
            )
            result[monthStart, default: .zero] += overflow
        }
        return result
    }

    private static func billingPeriod(
        record: FixtureRecord,
        now: Date,
        calendar: Calendar
    ) -> (start: Date, end: Date) {
        let startDay = record.periodStartDayOfMonth ?? 1
        let start = resolveDay(startDay, now: now, calendar: calendar, allowMonthStart: true)
        let end: Date
        if let endDay = record.periodEndDayOfMonth {
            end = resolveDay(endDay, now: now, calendar: calendar, allowMonthStart: true)
        } else {
            end = endOfMonth(now: now, calendar: calendar)
        }
        return (start, end)
    }

    private static func resolveDay(
        _ dayOfMonth: Int,
        now: Date,
        calendar: Calendar,
        allowMonthStart: Bool,
        monthOffset: Int = 0
    ) -> Date {
        let shiftedNow = shifted(now, byMonths: monthOffset, calendar: calendar)
        let monthStart = startOfMonth(now: shiftedNow, calendar: calendar)
        let daysInMonth = calendar.range(of: .day, in: .month, for: shiftedNow)?.count ?? 1
        let clampedDay = min(max(dayOfMonth, 1), daysInMonth)
        var components = calendar.dateComponents([.year, .month], from: shiftedNow)
        components.day = clampedDay
        let resolved = calendar.date(from: components) ?? monthStart
        if !allowMonthStart, resolved <= monthStart {
            return calendar.date(byAdding: .hour, value: 1, to: monthStart) ?? resolved
        }
        return resolved
    }

    private static func shifted(_ now: Date, byMonths offset: Int, calendar: Calendar) -> Date {
        guard offset != 0 else { return now }
        return calendar.date(byAdding: .month, value: offset, to: now) ?? now
    }

    private static func startOfMonth(now: Date, calendar: Calendar) -> Date {
        CalendarMonthWindow.current(now: now, calendar: calendar).start
    }

    private static func endOfMonth(now: Date, calendar: Calendar) -> Date {
        CalendarMonthWindow.current(now: now, calendar: calendar).endInclusive
    }
}
