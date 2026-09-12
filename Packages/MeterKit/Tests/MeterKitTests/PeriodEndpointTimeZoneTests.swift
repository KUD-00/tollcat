import Foundation
import Testing
@testable import MeterCore

/// 账期端点是**日历上的那一天**，不是某个时区的那一刻。
///
/// 这一组守的是第二轮审视第 1 条：东京落盘 `periodStart = 8 月 1 日 00:00 JST`，
/// 在纽约日历上那一刻是 7 月 31 日 11:00，于是八月那条快照被判成「和七月有重叠」，
/// `proratePeriodSpend` 把八月至今的钱整笔摊进 7 月 31 日那一天。
/// 两条读取路径（账本 / 重算）走的是同一段代码，`LedgerSelfCheck` 照样通过。
///
/// 落盘那一半在 `MeterPersistenceTests/SnapshotPeriodDayTests.swift`。
struct PeriodEndpointTimeZoneTests {
    private let tokyo: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return c
    }()
    private let newYork: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return c
    }()

    /// Aiven / Linode 那一族：只有「本账期至今累计」，没有日表。
    private func periodOnly(periodStart: Date, periodEnd: Date, fetchedAt: Date) -> Snapshot {
        Snapshot(
            providerID: .aiven,
            accountID: AccountID.fixture(1),
            kind: .usage,
            fetchedAt: fetchedAt,
            periodStart: periodStart,
            periodEnd: periodEnd,
            currentSpendUSD: Money(usd: 100)
        )
    }

    @Test("按日历分量算出来的账期端点：纽约日历回看七月是 0，不是把八月整笔摊过去")
    func periodOnlySnapshotDoesNotLeakIntoThePreviousMonth() {
        // 账期端点是**算出来的**：拿分量在读日历上还原。落盘只存 `2026-08-01`。
        let start = DayKey(year: 2026, month: 8, day: 1).date(in: newYork)!
        let end = DayKey(year: 2026, month: 8, day: 31).date(in: newYork)!
        let now = newYork.date(from: DateComponents(year: 2026, month: 8, day: 17, hour: 12))!
        let snapshot = periodOnly(periodStart: start, periodEnd: end, fetchedAt: now)

        let july = MonthToDateCalculator.compute(
            snapshots: [snapshot],
            subscriptions: [],
            now: now,
            calendar: newYork,
            filter: DashboardFilter(monthsBack: 1)
        )
        // 探针 `PROBE julyTokyo=0 julyNY=100` 修前是 100。
        #expect(july.totalUSD == .zero)

        let august = MonthToDateCalculator.compute(
            snapshots: [snapshot],
            subscriptions: [],
            now: now,
            calendar: newYork
        )
        // 8 月 1..17 共 17 天，账期 8 月 1..31 里已过 17 天 → 全额。
        #expect(august.totalUSD == Money(usd: 100))
    }

    @Test("同一份分量在东京和纽约各还原一次，回看上个月都是 0")
    func sameComponentsAgreeAcrossZones() {
        for calendar in [tokyo, newYork] {
            let start = DayKey(year: 2026, month: 8, day: 1).date(in: calendar)!
            let end = DayKey(year: 2026, month: 8, day: 31).date(in: calendar)!
            let now = calendar.date(from: DateComponents(year: 2026, month: 8, day: 17, hour: 12))!
            let july = MonthToDateCalculator.compute(
                snapshots: [periodOnly(periodStart: start, periodEnd: end, fetchedAt: now)],
                subscriptions: [],
                now: now,
                calendar: calendar,
                filter: DashboardFilter(monthsBack: 1)
            )
            #expect(july.totalUSD == .zero, "\(calendar.timeZone.identifier)")
        }
    }

    @Test("存瞬间才会出的那个错：8 月 1 日 00:00 JST 在纽约日历上落进七月")
    func storingTheInstantIsWhatUsedToBreak() {
        // 这一条不是回归测试，是把「为什么要存分量」钉住：同一个**瞬间**在两本
        // 日历上是不同的日子。分量没有这个性质，所以上面两条才成立。
        let instant = tokyo.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        #expect(tokyo.component(.month, from: instant) == 8)
        #expect(newYork.component(.month, from: instant) == 7)
    }
}
