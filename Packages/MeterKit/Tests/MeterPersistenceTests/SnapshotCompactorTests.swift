import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

/// 快照压缩（SPEC 12.5）：窗口内一条不少，窗口外每（账号, 月）只留最后一条。
///
/// **压缩不改语义**——压缩前后重折账本，那些月份的数字必须逐项相同。
/// 这一组就是 SPEC 里说的「实现落地时要拿 `LedgerSelfCheck` 对一遍」。
@MainActor
struct SnapshotCompactorTests {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()

    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 8, day: 17, hour: 12))! }

    private func at(_ y: Int, _ m: Int, _ d: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    /// 每个月两条：窗口外的那些月份应该只剩后面那条。
    private func seed() -> [Snapshot] {
        var out: [Snapshot] = []
        // 2024-08 到 2026-08，每月两条。
        for (year, month) in monthsBack(25) {
            for (index, day) in [3, 27].enumerated() {
                out.append(
                    Snapshot(
                        providerID: .aws,
                        accountID: AccountID.fixture(1),
                        kind: .usage,
                        fetchedAt: at(year, month, day),
                        periodStart: at(year, month, 1),
                        periodEnd: at(year, month, 28),
                        currentSpendUSD: Money(usd: month * 10 + index)
                    )
                )
            }
        }
        return out
    }

    private func monthsBack(_ count: Int) -> [(Int, Int)] {
        var out: [(Int, Int)] = []
        var cursor = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        for _ in 0..<count {
            let parts = calendar.dateComponents([.year, .month], from: cursor)
            out.append((parts.year!, parts.month!))
            cursor = calendar.date(byAdding: .month, value: -1, to: cursor)!
        }
        return out.reversed()
    }

    private func store(_ snapshots: [Snapshot], into context: ModelContext) throws {
        for snapshot in snapshots {
            _ = try SnapshotWriter.apply(snapshot, to: context, calendar: calendar)
        }
        try context.save()
    }

    @Test("窗口是能回看的月份 + 1 个月，数字只有一个出处")
    func windowComesFromDashboardPeriod() {
        #expect(SnapshotCompactor.windowMonths == DashboardPeriod.maxMonthsBack + 2)
        let start = SnapshotCompactor.windowStart(now: now, calendar: calendar)
        // 2026-08 往前 12 个月 = 2025-08 的月首。
        #expect(start == at(2025, 8, 1, 0))
    }

    @Test("窗口内一条都不删；窗口外每（账号, 月）恰好剩一条，而且是最新那条")
    func keepsTheWindowIntactAndOneRowPerOlderMonth() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(seed(), into: context)
        let start = try #require(SnapshotCompactor.windowStart(now: now, calendar: calendar))

        let insideBefore = try context.fetch(FetchDescriptor<SnapshotRecord>())
            .filter { $0.fetchedAt >= start }
            .count
        let deleted = try SnapshotCompactor.compact(now: now, calendar: calendar, in: context)
        #expect(deleted > 0)

        let rows = try context.fetch(FetchDescriptor<SnapshotRecord>())
        #expect(rows.filter { $0.fetchedAt >= start }.count == insideBefore)

        var byMonth: [MonthKey: [SnapshotRecord]] = [:]
        for row in rows where row.fetchedAt < start {
            byMonth[MonthKey(row.fetchedAt, calendar: calendar), default: []].append(row)
        }
        #expect(!byMonth.isEmpty)
        for (month, group) in byMonth {
            #expect(group.count == 1, "\(month) 剩了 \(group.count) 条")
            // 留最后一条：账期累计型的家最后一条才是那个月的终值。
            #expect(calendar.component(.day, from: group[0].fetchedAt) == 27)
        }
    }

    @Test("压缩之后戳作废，下一次同步会整份重折")
    func compactionInvalidatesTheStamp() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(seed(), into: context)
        let scope = MonthlyLedgerStore.Scope(now: now, calendar: calendar)
        try MonthlyLedgerStore.rebuildAll(scope, in: context)
        #expect(MonthlyLedgerStore.isInSync(scope, in: context))

        _ = try SnapshotCompactor.compact(now: now, calendar: calendar, in: context)
        #expect(!MonthlyLedgerStore.isInSync(scope, in: context))
    }

    @Test("先折后删：能回看的那几个月，压缩前后账本和重算都对得上")
    func compactionDoesNotChangeAnyVisibleNumber() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let snapshots = seed()
        try store(snapshots, into: context)
        let scope = MonthlyLedgerStore.Scope(now: now, calendar: calendar)
        try MonthlyLedgerStore.rebuildAll(scope, in: context)
        let before = try MonthlyLedgerStore.view(subscriptions: [], calendar: calendar, in: context)

        _ = try SnapshotCompactor.compact(now: now, calendar: calendar, in: context)
        try MonthlyLedgerStore.rebuildAll(scope, in: context)
        let after = try MonthlyLedgerStore.view(subscriptions: [], calendar: calendar, in: context)

        for period in [
            DashboardPeriod.currentMonth,
            .months(back: 1, count: 1),
            .months(back: 0, count: 3),
            .yearToDate,
            .allTime,
        ] {
            let filter = DashboardFilter(period: period)
            let lhs = LedgerProjection.compute(
                rollups: before.rollups, subscriptions: [], now: now, calendar: calendar, filter: filter
            )
            let rhs = LedgerProjection.compute(
                rollups: after.rollups, subscriptions: [], now: now, calendar: calendar, filter: filter
            )
            #expect(
                LedgerSelfCheck.compare(ledger: lhs, recompute: rhs).isEmpty,
                "\(period) 压缩改了数字"
            )
        }

        // 压缩之后库里剩下的读数，再全量重算一遍也和账本一致。
        let remaining = try SnapshotLog.snapshots(accountIDs: nil, calendar: calendar, in: context)
        let viaLedger = LedgerProjection.compute(
            rollups: after.rollups,
            subscriptions: [],
            now: now,
            calendar: calendar,
            filter: DashboardFilter(period: .allTime)
        )
        let viaRecompute = PeriodTotalCalculator.compute(
            snapshots: remaining,
            subscriptions: [],
            now: now,
            calendar: calendar,
            filter: DashboardFilter(period: .allTime)
        )
        #expect(LedgerSelfCheck.compare(ledger: viaLedger, recompute: viaRecompute).isEmpty)
    }

    /// 「月」= 取数月这条口径写在 SPEC 12.5 和 `SnapshotCompactor` 的注释里。
    /// 钉一条测试，免得下次有人按账期月改了而没人发现口径变了。
    @Test("分组按取数月，不按账期月：补录的那一条归在它被填进来的那个月")
    func groupingFollowsTheFetchMonthNotThePeriodMonth() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let account = AccountID.fixture(1)
        // 两条都在窗口之外。补录：取数在 2024-03，账期在 2024-02。
        let backfill = Snapshot(
            providerID: .fly, accountID: account, kind: .usage,
            fetchedAt: at(2024, 3, 2, 9),
            periodStart: at(2024, 2, 1), periodEnd: at(2024, 2, 29),
            currentSpendUSD: Money(usd: 42)
        )
        // 同一个取数月里、更晚取到的一条当月读数。
        let sameFetchMonth = Snapshot(
            providerID: .fly, accountID: account, kind: .usage,
            fetchedAt: at(2024, 3, 20, 9),
            periodStart: at(2024, 3, 1), periodEnd: at(2024, 3, 31),
            currentSpendUSD: Money(usd: 7)
        )
        try store([backfill, sameFetchMonth], into: context)
        _ = try SnapshotCompactor.compact(now: now, calendar: calendar, in: context)

        let left = try SnapshotLog.snapshots(accountIDs: [account], calendar: calendar, in: context)
        // 按**取数月**分组 → 两条同属 2024-03，只留 fetchedAt 最大的那条。
        #expect(left.count == 1)
        #expect(left.first?.currentSpendUSD == Money(usd: 7))
        // 按账期月分组的话这里会是 2 条。改口径的人会在这一行看见自己改了什么。
    }

    @Test("没有多余的行时什么都不写——戳也不动，免得每天白重折一次")
    func aFreshStoreIsLeftAlone() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(
            [
                Snapshot(
                    providerID: .aws,
                    accountID: AccountID.fixture(1),
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: at(2026, 8, 1),
                    periodEnd: at(2026, 8, 31),
                    currentSpendUSD: Money(usd: 12)
                )
            ],
            into: context
        )
        let scope = MonthlyLedgerStore.Scope(now: now, calendar: calendar)
        try MonthlyLedgerStore.rebuildAll(scope, in: context)
        #expect(try SnapshotCompactor.compact(now: now, calendar: calendar, in: context) == 0)
        #expect(MonthlyLedgerStore.isInSync(scope, in: context))
    }
}
