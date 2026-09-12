import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

/// 物化账本的**读写口**：折、增量重折、删、以及「账本还作不作数」那一判。
///
/// 领域层的对账在 `MeterKitTests/LedgerSelfCheckTests.swift`（折叠 → 投影 → 和
/// 全量重算逐项比）。这里补的是**它管不到的一截**：写进 SwiftData 再读回来。
/// 少一个字段没搬、戳没跟着行落，领域层那组测试是看不见的。
///
/// 种子在 `LedgerFixture`，和 `LedgerCodecTests` 共用一份。
@MainActor
struct MonthlyLedgerStoreTests {
    private var calendar: Calendar { LedgerFixture.calendar }
    private var now: Date { LedgerFixture.now }
    private var snapshots: [Snapshot] { LedgerFixture.snapshots }
    private var subscriptions: [MonthlySubscription] { LedgerFixture.subscriptions }

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date { LedgerFixture.day(y, m, d) }

    private func store(_ snapshots: [Snapshot], into context: ModelContext, calendar: Calendar? = nil) throws {
        try LedgerFixture.store(snapshots, into: context, calendar: calendar)
    }

    private func scope(
        accountIDs: Set<AccountID>? = nil,
        ended: [AccountID: Date] = [:],
        now: Date? = nil,
        calendar: Calendar? = nil
    ) -> MonthlyLedgerStore.Scope {
        LedgerFixture.scope(accountIDs: accountIDs, ended: ended, now: now, calendar: calendar)
    }

    @Test("写进库再读回来，投影出的数和全量重算逐项相同")
    func roundTripAgreesWithRecompute() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        let written = try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        // 两个账号 × 能回看的 12 个月。
        #expect(written == 24)
        let rollups = try MonthlyLedgerStore.all(calendar: calendar, in: context)
        #expect(rollups.count == written)

        for period in [
            DashboardPeriod.currentMonth,
            .months(back: 1, count: 1),
            .months(back: 0, count: 3),
            .yearToDate,
            .allTime,
        ] {
            let filter = DashboardFilter(period: period)
            let viaLedger = LedgerProjection.compute(
                rollups: rollups, subscriptions: subscriptions,
                now: now, calendar: calendar, filter: filter
            )
            let viaRecompute = PeriodTotalCalculator.compute(
                snapshots: snapshots, subscriptions: subscriptions,
                now: now, calendar: calendar, filter: filter
            )
            let issues = LedgerSelfCheck.compare(ledger: viaLedger, recompute: viaRecompute)
            #expect(issues.isEmpty, "\(period): \(issues.map(\.description).joined(separator: " | "))")
        }
    }

    @Test("重折一个账号不碰别的账号的行")
    func rebuildIsScopedToOneAccount() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        let before = try MonthlyLedgerStore.all(calendar: calendar, in: context)
            .filter { $0.accountID == AccountID.fixture(2) }

        try MonthlyLedgerStore.rebuild(accountID: AccountID.fixture(1), scope: scope(), in: context)
        let after = try MonthlyLedgerStore.all(calendar: calendar, in: context)
            .filter { $0.accountID == AccountID.fixture(2) }
        #expect(Set(before) == Set(after))
        // 重折不该把行数变多——同一个 (账号, 月) 只能有一行，
        // 多出来的行会让读出来的钱凭空翻倍，而那看起来完全正常。
        #expect(try MonthlyLedgerStore.all(calendar: calendar, in: context).count == 24)
    }

    @Test("账号没了，它的账也跟着没")
    func deletingAnAccountClearsItsRows() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        try MonthlyLedgerStore.delete(accountID: AccountID.fixture(1), in: context)
        let rest = try MonthlyLedgerStore.all(calendar: calendar, in: context)
        #expect(rest.allSatisfy { $0.accountID == AccountID.fixture(2) })
        #expect(rest.count == 12)
    }

    @Test("同步判据：新读数和账号范围变了都要判成「对不上」")
    func syncVerdictCatchesBothKindsOfDrift() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        #expect(MonthlyLedgerStore.isInSync(scope(), in: context))

        // 账号少了一个——只看时间戳的话这一条会漏掉，那笔钱就查无此人。
        #expect(!MonthlyLedgerStore.isInSync(scope(accountIDs: [AccountID.fixture(1)]), in: context))

        // 来了更新的读数。
        var newer = snapshots[0]
        newer.fetchedAt = calendar.date(byAdding: .hour, value: 1, to: now)!
        try store([newer], into: context)
        #expect(!MonthlyLedgerStore.isInSync(scope(), in: context))

        // 空库对空账本。
        let empty = try PersistenceContainer.makeContainer(inMemory: true)
        #expect(MonthlyLedgerStore.isInSync(scope(), in: ModelContext(empty)))
    }

    @Test("折完真的落了盘：换一个 context 读，行和戳都还在")
    func rebuildActuallyPersists() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let writer = ModelContext(container)
        try store(snapshots, into: writer)
        try MonthlyLedgerStore.rebuildAll(scope(), in: writer)
        // 展示路径每次都开一个新的 context 读。写入要是只留在写那个 context 里，
        // 这里就会是 0 行 + 判成对不上——数字仍然对（当场折一遍），
        // 只是每次打开都白折一次，而且永远发现不了。
        let reader = ModelContext(container)
        #expect(try MonthlyLedgerStore.all(calendar: calendar, in: reader).count == 24)
        #expect(MonthlyLedgerStore.isInSync(scope(), in: reader))
    }

    @Test("补一条更老的读数也要判成「对不上」")
    func backfilledOlderReadingIsOutOfSync() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)

        // 回填历史、信箱送来一条过去时刻的读数：最新那个时间戳纹丝不动，
        // 账号集合也没变——只比时间戳和账号的话，这一条会被判成"还作数"，
        // 而它带来的钱一分都不会出现在账本里。
        var older = snapshots[0]
        older.fetchedAt = calendar.date(byAdding: .day, value: -3, to: now)!
        older.currentSpendUSD = Money(usd: 5)
        try store([older], into: context)
        #expect(!MonthlyLedgerStore.isInSync(scope(), in: context))
    }

    @Test("跨一天就过期，哪怕当月一行都还没有")
    func dayRolloverIsOutOfSync() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        #expect(!MonthlyLedgerStore.isInSync(scope(now: tomorrow), in: context))

        // 空账本 + 跨月：以前那条「当月每一行都得是今天折的」在没有当月行时
        // 恒真，于是月初第一次打开会拿着上个月的账本当数。
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: now)!
        #expect(!MonthlyLedgerStore.isInSync(scope(now: nextMonth), in: context))
    }

    @Test("换了时区：判成过期，重折之后月份行落在新时区的月首上")
    func timeZoneChangeRefoldsOntoTheNewMonthStarts() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        var newYork = calendar
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        #expect(!MonthlyLedgerStore.isInSync(scope(calendar: newYork), in: context))

        // 月份存的是分量，不是「1 号零点」那一刻：换本日历读，行照样对得上月首。
        let rows = try MonthlyLedgerStore.all(calendar: newYork, in: context)
        let august = newYork.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        #expect(rows.contains { $0.monthStart == august })

        try MonthlyLedgerStore.rebuildAll(scope(calendar: newYork), in: context)
        #expect(MonthlyLedgerStore.isInSync(scope(calendar: newYork), in: context))
        let viaLedger = LedgerProjection.compute(
            rollups: try MonthlyLedgerStore.all(calendar: newYork, in: context),
            subscriptions: [], now: now, calendar: newYork
        )
        let viaRecompute = PeriodTotalCalculator.compute(
            snapshots: try SnapshotLog.snapshots(accountIDs: nil, calendar: newYork, in: context),
            subscriptions: [], now: now, calendar: newYork
        )
        #expect(LedgerSelfCheck.compare(ledger: viaLedger, recompute: viaRecompute).isEmpty)
    }

    @Test("结束掉一个账号也要判成「对不上」——那会改写它最后那个月的钱")
    func endedAccountsAreInTheVerdict() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        #expect(
            !MonthlyLedgerStore.isInSync(
                scope(ended: [AccountID.fixture(2): day(2026, 7, 15)]),
                in: context
            )
        )
    }

    @Test("增量重折之后立刻就是「对得上」，而且内容和整份重折逐行相同")
    func incrementalRebuildMatchesFullRebuild() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        var newer = snapshots[0]
        newer.fetchedAt = calendar.date(byAdding: .hour, value: 1, to: now)!
        newer.currentSpendUSD = Money(usd: 120)
        try store([newer], into: context)
        #expect(!MonthlyLedgerStore.isInSync(scope(), in: context))

        try MonthlyLedgerStore.apply(newer, scope: scope(), in: context)
        #expect(MonthlyLedgerStore.isInSync(scope(), in: context))
        // 生产上每次刷新走的是这条增量路；它折出来的必须和整份重折一个字不差，
        // 否则「从哪条路读的」会改变屏幕上的数。
        let afterApply = Set(try MonthlyLedgerStore.all(calendar: calendar, in: context))
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        let afterRebuild = Set(try MonthlyLedgerStore.all(calendar: calendar, in: context))
        #expect(afterApply == afterRebuild)
    }

    @Test("清空之后是空库对空读数，不是「有行没戳」")
    func deleteAllClearsTheStamp() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        try MonthlyLedgerStore.deleteAll(in: context)
        #expect(try MonthlyLedgerStore.all(calendar: calendar, in: context).isEmpty)
        // 范围里一个账号都没有 = 没有东西要折，空账本是对的。
        #expect(MonthlyLedgerStore.isInSync(scope(accountIDs: []), in: context))
        // 库里还有读数而账本是空的 = 对不上。
        #expect(!MonthlyLedgerStore.isInSync(scope(), in: context))
    }

    // ─────────────────────────────────────────────────────────
    // 第二轮审视补的那几组。
    // ─────────────────────────────────────────────────────────

    @Test("三态：跨天只是 staleToday，换时区 / 来新读数才是 staleInputs")
    func verdictTellsTheTwoKindsOfStaleApart() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        #expect(MonthlyLedgerStore.verdict(scope(), in: context) == .inSync)

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        #expect(MonthlyLedgerStore.verdict(scope(now: tomorrow), in: context) == .staleToday)

        // 换时区会挪动月份边界和日桶——过去几个月的行全都要重折。
        var newYork = calendar
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        #expect(MonthlyLedgerStore.verdict(scope(calendar: newYork), in: context) == .staleInputs)

        var newer = snapshots[0]
        newer.fetchedAt = calendar.date(byAdding: .hour, value: 1, to: now)!
        try store([newer], into: context)
        #expect(MonthlyLedgerStore.verdict(scope(), in: context) == .staleInputs)
    }

    @Test("跨天只重折当月那一行：过去月份的行一个字节都没动")
    func refoldingForANewDayLeavesPastMonthsAlone() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        let before = try MonthlyLedgerStore.all(calendar: calendar, in: context)

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        try MonthlyLedgerStore.refoldCurrentMonth(scope(now: tomorrow), in: context)
        #expect(MonthlyLedgerStore.verdict(scope(now: tomorrow), in: context) == .inSync)

        let after = try MonthlyLedgerStore.all(calendar: calendar, in: context)
        let thisMonth = MonthKey(now, calendar: calendar)
        let pastBefore = before.filter { MonthKey($0.monthStart, calendar: calendar) != thisMonth }
        let pastAfter = after.filter { MonthKey($0.monthStart, calendar: calendar) != thisMonth }
        #expect(Set(pastBefore) == Set(pastAfter))
        #expect(before.count == after.count)
    }

    @Test("带下界折 == 全史折：随机账本逐行相同")
    func boundedFoldMatchesFullHistoryFold() throws {
        var generator = SystemRandomNumberGenerator()
        for round in 0..<40 {
            let container = try PersistenceContainer.makeContainer(inMemory: true)
            let context = ModelContext(container)
            let account = AccountID.fixture(7)
            var readings: [Snapshot] = []
            // 铺到 30 个月前：下界（13 个月）之外一定有东西。
            for offset in 0..<30 {
                guard Bool.random(using: &generator) || offset % 3 == 0 else { continue }
                let when = calendar.date(byAdding: .month, value: -offset, to: now)!
                readings.append(
                    Snapshot(
                        providerID: .aws,
                        accountID: account,
                        kind: .prepaid,
                        fetchedAt: when,
                        periodStart: when,
                        periodEnd: when,
                        balanceUSD: Money(usd: Decimal(Int.random(in: 1...500, using: &generator)))
                    )
                )
            }
            guard !readings.isEmpty else { continue }
            try store(readings, into: context)

            // 全史折：直接喂给折叠器。
            let full = LedgerFolder.fold(
                accountID: account,
                snapshots: try SnapshotLog.snapshots(
                    accountIDs: [account], calendar: calendar, in: context
                ),
                now: now,
                calendar: calendar
            )
            // 带下界折：走生产那条路。
            try MonthlyLedgerStore.rebuild(accountID: account, scope: scope(), in: context)
            let bounded = try MonthlyLedgerStore.all(calendar: calendar, in: context)
            #expect(Set(full) == Set(bounded), "第 \(round) 轮：带下界折和全史折不一样")
        }
    }

    @Test("坏行不当不存在：读到就作废戳并抛，重折一次真的能好")
    func corruptRowsInvalidateTheStampAndThrow() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        let healthy = try MonthlyLedgerStore.all(calendar: calendar, in: context)

        let row = try #require(try context.fetch(FetchDescriptor<MonthlyRollupRecord>()).first)
        let key = row.monthKey
        let account = row.accountIDRaw
        row.confidenceRaw = "垃圾"
        try context.save()

        #expect(throws: (any Error).self) {
            _ = try MonthlyLedgerStore.all(calendar: calendar, in: context)
        }
        // 戳没了 → 下一次必定判失效。以前这里是「指纹照样相等」，
        // 那个账号那个月于是从合计里**永久**消失。
        #expect(!MonthlyLedgerStore.isInSync(scope(), in: context))

        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        let repaired = try MonthlyLedgerStore.all(calendar: calendar, in: context)
        #expect(Set(repaired) == Set(healthy))
        #expect(
            repaired.contains {
                $0.accountID.rawValue.uuidString == account
                    && MonthKey($0.monthStart, calendar: calendar) == key
            }
        )
    }

    @Test("编码失败不落半对的一行：写侧抛，不静默丢掉日表")
    func encodingFailuresThrowInsteadOfDroppingBlobs() throws {
        // 这一条守的是形状：`init` / `apply` 现在是 `throws`，编不出来的行
        // 不会带着空日表落进库。真造一个编不出来的 `Decimal` 做不到，
        // 所以这里钉的是「这条路是 throws 的」——`try` 去掉就编不过。
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        let rollups = LedgerSelfCheck.foldAll(snapshots: snapshots, now: now, calendar: calendar)
        for rollup in rollups.prefix(1) {
            let record = try MonthlyRollupRecord(domain: rollup, calendar: calendar)
            try record.apply(rollup, calendar: calendar)
            #expect(record.toDomain(calendar: calendar) == rollup)
        }
        _ = context
    }

    @Test("跨月**不是** staleToday：上个月的行要从「本月至今」变成整月，每个账号都得重折")
    func crossingIntoANewMonthNeedsAFullRebuild() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)

        // 同一个月里翻一天：只有当月那一行依赖「今天」，走便宜的那条。
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        #expect(MonthlyLedgerStore.verdict(scope(now: tomorrow), in: context) == .staleToday)

        // 跨到下个月：8 月那一行昨天折的是「到 17 号为止」，今天该是整个 8 月。
        // 只重折当月的话，别的账号的 8 月行会永远停在半个月。
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: now)!
        #expect(MonthlyLedgerStore.verdict(scope(now: nextMonth), in: context) == .staleInputs)
    }

    @Test("同月翻一天：只重折当月，结果和「先清空再重铺」逐行相同")
    func refoldingWithinTheSameMonthMatchesAFullRebuild() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        try MonthlyLedgerStore.refoldCurrentMonth(scope(now: tomorrow), in: context)
        #expect(MonthlyLedgerStore.verdict(scope(now: tomorrow), in: context) == .inSync)
        let viaRefold = try MonthlyLedgerStore.all(calendar: calendar, in: context)

        try MonthlyLedgerStore.rebuildAll(scope(now: tomorrow), in: context)
        let viaRebuildAll = try MonthlyLedgerStore.all(calendar: calendar, in: context)
        // 省下来的时间不能是用错数字换的。
        #expect(Set(viaRefold) == Set(viaRebuildAll))
    }

    @Test("跨月之后掉出 12 个月窗口的行会被清掉，不留给热力图和「全期间」")
    func rowsThatFellOutOfTheWindowAreDropped() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        let oldestBefore = try #require(
            try MonthlyLedgerStore.all(calendar: calendar, in: context).map(\.monthStart).min()
        )

        // 刷新那条路（`rebuild`）跨月时也必须清，而且**不许盖章**：盖了章
        // `isInSync` 就说是，随后那趟整份重折不会来，孤儿行和别人的上月行都留下了。
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: now)!
        try MonthlyLedgerStore.rebuild(
            accountID: AccountID.fixture(1),
            scope: scope(now: nextMonth),
            in: context
        )
        let afterRefresh = try MonthlyLedgerStore.all(calendar: calendar, in: context)
        #expect(!afterRefresh.contains { $0.monthStart == oldestBefore }, "掉出窗口的行还在")
        #expect(!MonthlyLedgerStore.isInSync(scope(now: nextMonth), in: context), "跨月不该盖章")

        // 整份重折之后同样没有它。
        try MonthlyLedgerStore.rebuildAll(scope(now: nextMonth), in: context)
        let afterRebuild = try MonthlyLedgerStore.all(calendar: calendar, in: context)
        #expect(!afterRebuild.contains { $0.monthStart == oldestBefore })
    }
}
