import Foundation
import SwiftData
import Testing
import MeterCore
import MeterPersistence
@testable import MeterFeatures

/// 账本编排：折完那一份还算不算数、读失败怎么办、换了账本谁去喊 Widget。
///
/// 第二轮审视第 15 条：这台状态机在 1339 个用例里一条覆盖都没有，而第 5、7、10 条
/// 都是它漏掉的分支。
///
/// 「折的期间库又变过了那一份就作废」这条是直线不变量（`sync` 进门记下
/// `storeRevision`、出门比一次），这里不给它写测试：想造出那个时序只能靠
/// `Task.yield()` 赌调度顺序，而一条会偶尔变红的测试比没有测试更糟。
@MainActor
struct LedgerSyncTests {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()

    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 8, day: 17, hour: 12))! }

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    private var snapshot: Snapshot {
        Snapshot(
            providerID: .aws,
            accountID: AccountID.fixture(1),
            kind: .usage,
            fetchedAt: now,
            periodStart: day(2026, 8, 1),
            periodEnd: day(2026, 8, 31),
            currentSpendUSD: Money(usd: 90)
        )
    }

    private func inputs(_ accountIDs: Set<AccountID> = [AccountID.fixture(1)]) -> LedgerCache.Inputs {
        LedgerCache.Inputs(
            accountIDs: accountIDs,
            subscriptions: [],
            endedAccounts: [:],
            now: now,
            calendar: calendar
        )
    }

    private func seeded() throws -> ModelContainer {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        _ = try SnapshotWriter.apply(snapshot, to: context, calendar: calendar)
        try context.save()
        return container
    }

    @Test("load 只读账本那两张表：空库读出来是空的，折叠交给随后那一趟 sync")
    func loadDoesNotFold() throws {
        let sync = LedgerSync(container: try seeded())
        // 还没折过：库里一行都没有，`load` 也**不去折**——它不判「作不作数」。
        #expect(try sync.load(inputs()).rollups.isEmpty)
    }

    @Test("sync 折完之后 load 就有行了，而且合计和重算一致")
    func syncFoldsAndLoadSeesIt() async throws {
        let container = try seeded()
        let sync = LedgerSync(container: container)
        let synced = try #require(try await sync.sync(inputs()))
        #expect(!synced.rollups.isEmpty)

        let loaded = try sync.load(inputs())
        #expect(Set(loaded.rollups) == Set(synced.rollups))

        let viaLedger = LedgerProjection.compute(
            rollups: loaded.rollups,
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        let viaRecompute = PeriodTotalCalculator.compute(
            snapshots: [snapshot],
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        #expect(LedgerSelfCheck.compare(ledger: viaLedger, recompute: viaRecompute).isEmpty)
    }

    @Test("已经对得上就回 nil：不用换")
    func syncReturnsNilWhenAlreadyInSync() async throws {
        let sync = LedgerSync(container: try seeded())
        _ = try await sync.sync(inputs())
        #expect(try await sync.sync(inputs()) == nil)
    }

    @Test("读不出来就抛，不吐一份空账本——屏幕会当场报「还没有账单」")
    func readFailuresThrowInsteadOfReturningAnEmptyView() async throws {
        let container = try seeded()
        let sync = LedgerSync(container: container)
        _ = try await sync.sync(inputs())
        #expect(!(try sync.load(inputs()).rollups.isEmpty))

        // 把一行折坏（`confidenceRaw` 解不出来）。这一条以前被「当不存在」读过去：
        // 那个账号那个月从合计里消失，指纹照样相等，没有任何人会去重折。
        let context = ModelContext(container)
        let row = try #require(try context.fetch(FetchDescriptor<MonthlyRollupRecord>()).first)
        row.confidenceRaw = "垃圾"
        try context.save()

        #expect(throws: (any Error).self) {
            _ = try sync.load(self.inputs())
        }
        // 戳跟着作废：下一次同步会把账本重折干净。
        let repaired = try #require(try await sync.sync(inputs()))
        #expect(!repaired.rollups.isEmpty)
        #expect(throws: Never.self) {
            _ = try sync.load(self.inputs())
        }
    }

    @Test("增量：落一条新快照之后只重折这个账号，合计跟着变")
    func applyRefoldsOneAccount() async throws {
        let container = try seeded()
        let sync = LedgerSync(container: container)
        _ = try await sync.sync(inputs())

        var newer = snapshot
        newer.fetchedAt = calendar.date(byAdding: .hour, value: 1, to: now)!
        newer.currentSpendUSD = Money(usd: 120)
        let context = ModelContext(container)
        _ = try SnapshotWriter.apply(newer, to: context, calendar: calendar)
        try context.save()
        sync.noteStoreWrite()

        let applied = try #require(try await sync.apply(newer, inputs()))
        let total = LedgerProjection.compute(
            rollups: applied.rollups,
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        #expect(total.totalUSD == Money(usd: 120))
        // 增量之后立刻就该「对得上」，否则每次刷新完都白重折一次。
        #expect(try await sync.sync(inputs()) == nil)
    }

    @Test("并发：50 轮 apply 和 rebuild 抢同一个账号，每（账号, 月）仍然只有一行")
    func concurrentWritesNeverDuplicateRows() async throws {
        let container = try seeded()
        let sync = LedgerSync(container: container)
        _ = try await sync.sync(inputs())

        for round in 0..<50 {
            var newer = snapshot
            newer.fetchedAt = calendar.date(byAdding: .minute, value: round + 1, to: now)!
            newer.currentSpendUSD = Money(usd: 90 + round)
            let context = ModelContext(container)
            _ = try SnapshotWriter.apply(newer, to: context, calendar: calendar)
            try context.save()

            async let applied: Void = { _ = try? await sync.apply(newer, inputs()) }()
            async let rebuilt: Void = { _ = try? await sync.rebuild(inputs()) }()
            _ = await (applied, rebuilt)
        }

        let context = ModelContext(container)
        let rows = try context.fetch(FetchDescriptor<MonthlyRollupRecord>())
        var seen: Set<String> = []
        for row in rows {
            let key = "\(row.accountIDRaw)/\(row.monthKey.year)-\(row.monthKey.month)"
            #expect(seen.insert(key).inserted, "重复行: \(key)")
        }
        let stamps = try context.fetch(FetchDescriptor<LedgerStampRecord>())
        #expect(stamps.count == 1)
    }

    @Test("压缩跑过之后窗口内一条都不少")
    func compactionKeepsEverythingInsideTheWindow() async throws {
        let container = try seeded()
        let sync = LedgerSync(container: container)
        let context = ModelContext(container)
        let before = try SnapshotLog.count(in: context)
        try await sync.compactIfDue(inputs())
        // 种子只有当月一条，全在窗口内：一条都不该少。
        #expect(try SnapshotLog.count(in: ModelContext(container)) == before)
        // 再跑一次也不炸（一天最多一次，第二次直接返回）。
        try await sync.compactIfDue(inputs())
        #expect(try SnapshotLog.count(in: ModelContext(container)) == before)
    }
}
