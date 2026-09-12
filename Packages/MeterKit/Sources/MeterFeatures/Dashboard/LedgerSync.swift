import Foundation
import SwiftData
import MeterCore
import MeterPersistence

/// 物化账本这份缓存的**编排**：什么时候折、折完那份还算不算数。
///
/// ## 为什么不在 `DashboardModel` 里
///
/// 折叠本身在 `LedgerCache` / `MonthlyLedgerStore`，那一层是纯的、输入封闭的。
/// 但「折完回来时库是不是又变过了」是一件有并发语义的事，它以前和取景框、
/// 目录、猫、迁移包挤在同一个 1200 行的模型里，一个测试都没有。第 7 条（重复行）
/// 和第 10 条（Widget 读到旧账本）都是这台状态机漏掉的分支。
///
/// 这里只有一个状态：`storeRevision`。库每写一次加一；后台折完回来时对不上号，
/// 说明期间库又变过了，那一份作废——**不是**换上去再等下一次修正，因为那一帧
/// 屏幕上会是一个已知错的数。
///
/// 读模型本身仍归 `DashboardModel` 持有（它要驱动 `@Observable`），这里只负责
/// 产出「可以换上去的那一份」或者 `nil`（意思是「不用换」）。
@MainActor
final class LedgerSync {
    private let cache: LedgerCache
    /// 库每写一次加一。见类型注释。
    private var storeRevision = 0
    /// 上一次跑压缩是哪一天。**一天最多一次**——压缩是给几万行的库准备的，
    /// 每次同步都跑一遍是白扫一张大表。进程内记着就够：重开一次多跑一遍无害
    /// （没有多余的行时它什么都不写），而为它单开一张表不值得。
    private var lastCompactionDay: DayKey?

    init(container: ModelContainer) {
        self.cache = LedgerCache(container: container)
    }

    /// 库里写过东西了。
    func noteStoreWrite() {
        storeRevision += 1
    }

    /// 这一帧要用的读模型。同步，见 `LedgerCache.load`。
    /// 读失败原样抛——调用方保留上一份 + 亮「读不出最新数据」，不换成空的。
    func load(_ inputs: LedgerCache.Inputs) throws -> LedgerView {
        try cache.load(inputs)
    }

    /// 账本和库里的读数对不对得上、对不上就补折——**全在后台**，
    /// 而且是 `load` 之后紧接着排的一趟。见 `LedgerCache.synced`。
    func syncAfterLoad(_ inputs: LedgerCache.Inputs) async throws -> LedgerView? {
        try await sync(inputs)
    }

    /// 窗口以外的快照压掉。**排在 `sync` 之后**：先折后删（SPEC 12.5）。
    /// 一天最多一次；这一趟失败不影响任何数字，只是这次没压。
    /// 回删了多少条。**调用方要拿它去扔内存里那份读数**——压缩是删除，
    /// 而 `ReadingCache` 只认得「多了一条」，删掉的那些它自己发现不了。
    @discardableResult
    func compactIfDue(_ inputs: LedgerCache.Inputs) async throws -> Int {
        let today = DayKey(inputs.now, calendar: inputs.calendar)
        guard lastCompactionDay != today else { return 0 }
        // **先记日子再跑**：这一趟失败了今天就不再试。压缩失败不影响任何数字
        // （多留几行而已），而失败重试一整天会把一张大表反复扫下去。
        lastCompactionDay = today
        return try await cache.compacted(inputs)
    }

    /// 账本和库里的读数对不上就整份重折，回落盘之后那一份。
    /// 已经对得上、或者期间库又变过了都回 `nil`。
    func sync(_ inputs: LedgerCache.Inputs) async throws -> LedgerView? {
        let revision = storeRevision
        let loaded = try await cache.synced(inputs)
        guard let loaded, storeRevision == revision else { return nil }
        return loaded
    }

    /// 落了一条新快照之后的增量维护：只重折**这个账号**，别的账号不碰。
    func apply(_ snapshot: Snapshot, _ inputs: LedgerCache.Inputs) async throws -> LedgerView? {
        let revision = storeRevision
        let loaded = try await cache.applied(snapshot, inputs)
        guard let loaded, storeRevision == revision else { return nil }
        return loaded
    }

    /// 整份重建，不看对不对得上。开发页那个按钮走它。回写了多少行。
    func rebuild(_ inputs: LedgerCache.Inputs) async throws -> Int {
        try await cache.rebuilt(inputs)
    }

    // MARK: - 原始读数

    /// **门上明确开的那个口**：几个账号最近一段的原始读数。范围由调用方说清。
    func readings(accountIDs: Set<AccountID>, since: Date?, calendar: Calendar) -> [Snapshot] {
        cache.readings(accountIDs: accountIDs, since: since, calendar: calendar)
    }

    /// 这个账号**有没有过读到数的读数**。刷新失败时决定标「陈旧」还是「失败」。
    /// 走的是列级 predicate 的计数，不解 blob——每次刷新每家都要问一次。
    func hasBillableReading(accountID: AccountID) -> Bool {
        cache.hasBillableReading(accountID: accountID)
    }

    // MARK: - 开发页

    #if DEBUG
    func allReadings(calendar: Calendar) -> [Snapshot] {
        cache.allReadings(calendar: calendar)
    }

    func snapshotCount() -> Int {
        cache.snapshotCount()
    }

    func stats(_ inputs: LedgerCache.Inputs) throws -> (rows: Int, inSync: Bool) {
        try cache.stats(inputs)
    }

    func selfCheck(_ inputs: LedgerCache.Inputs, excludedAccounts: Set<AccountID>) async -> [String] {
        await cache.selfCheck(inputs, excludedAccounts: excludedAccounts)
    }
    #endif
}
