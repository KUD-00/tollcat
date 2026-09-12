import Foundation
import SwiftData
import MeterCore

/// 物化账本这份缓存的维护，以及快照日志唯一的读口。**只管缓存，不持有状态。**
///
/// ## 为什么日志不在 `DashboardModel` 手里
///
/// 展示层拿到的是 `LedgerView`（读模型）。日志留在库里；要折就按账号从库里取，
/// 要原始读数就按范围查（`readings`），要判「账本还作不作数」就从库里取几列标量
/// 算指纹。没有任何一步需要整份 `[Snapshot]` 在内存里——那正是账本这一层要
/// 让人不必持有的东西：内存、每次写库的重读、指纹的代价，都不再跟着刷新次数涨。
///
/// 输入是封闭的（`Inputs`），一个都不从环境里捡，于是"账本折得对不对"能单独测。
///
/// 每个方法要么回一份新的读模型，要么回 `nil`（意思是"不用换"）。
/// **换不换由调用方定**：期间库可能又变过了，只有 `DashboardModel` 知道
/// 手里那份还是不是当初喂进来的那份。
public struct LedgerCache: Sendable {
    /// 折一次账本要的全部东西。少一样，账本就会和重算对不上，
    /// 而对不上的表现是某个数字莫名不动——不是崩溃。
    public struct Inputs: Sendable {
        /// 哪些账号算数（还在用的，含结束的；真删的不在）。
        public var accountIDs: Set<AccountID>
        public var subscriptions: [MonthlySubscription]
        public var endedAccounts: [AccountID: Date]
        public var now: Date
        public var calendar: Calendar

        public init(
            accountIDs: Set<AccountID>,
            subscriptions: [MonthlySubscription],
            endedAccounts: [AccountID: Date],
            now: Date,
            calendar: Calendar
        ) {
            self.accountIDs = accountIDs
            self.subscriptions = subscriptions
            self.endedAccounts = endedAccounts
            self.now = now
            self.calendar = calendar
        }

        var scope: MonthlyLedgerStore.Scope {
            MonthlyLedgerStore.Scope(
                accountIDs: accountIDs,
                endedAccounts: endedAccounts,
                now: now,
                calendar: calendar
            )
        }
    }

    public let container: ModelContainer
    /// 账本的唯一写者。**折叠全排在它那一条队上**，见 `LedgerWriter`。
    private let writer: LedgerWriter

    public init(container: ModelContainer) {
        self.container = container
        self.writer = LedgerWriter(container: container)
    }

    // MARK: - 读模型

    /// 这一帧要用的读模型。**同步，只读账本那两张表**。
    ///
    /// 120 来行，几毫秒。**不判「还作不作数」、不补折**——那两件事要么全表扫快照
    /// 算指纹，要么在主线程上解几千个 blob，而它们的代价正比于刷新总次数。
    /// 都交给 `synced(_:)` 在后台做：首屏先给库里那份（最坏是旧一天），
    /// 折完再换。
    ///
    /// **读失败原样抛。**吞成空的 `LedgerView` 会让仪表当场进空态、写着
    /// 「还没有账单」，而磁盘上的数据一条不少——那是 ARCHITECTURE 明令禁止的
    /// 那一类静默失败。上层保留上一份 + 亮 `didFailToRead`。
    public func load(_ inputs: Inputs) throws -> LedgerView {
        try Self.view(inputs, in: ModelContext(container))
    }

    /// 对不上就整份重折并落盘，回落盘之后那一份。已经对得上回 `nil`。
    ///
    /// 这是**缓存**的维护，不是数据。整份重折随时可以做、做错了也只要再折一次。
    /// 但**失败要说出来**：折不出来时上层保留上一份，而不是换一份空的上去。
    public func synced(_ inputs: Inputs) async throws -> LedgerView? {
        guard try await writer.syncIfNeeded(inputs.scope) != nil else { return nil }
        return try Self.view(inputs, in: ModelContext(container))
    }

    /// 落了一条新快照之后的增量维护：只重折**这个账号**（全部月份），别的账号不碰。
    /// 快照必须**已经在库里**——戳记的是库里整份输入的指纹。
    public func applied(_ snapshot: Snapshot, _ inputs: Inputs) async throws -> LedgerView? {
        try await writer.apply(snapshot, scope: inputs.scope)
        return try Self.view(inputs, in: ModelContext(container))
    }

    /// 整份重建，不看对不对得上。开发页那个按钮走它。回写了多少行。
    public func rebuilt(_ inputs: Inputs) async throws -> Int {
        try await writer.rebuildAll(inputs.scope)
    }

    /// 窗口以外的快照压掉，走同一条写队列。回删了多少条。
    /// **必须排在 `synced` 之后**：先折后删，见 `SnapshotCompactor`。
    @discardableResult
    public func compacted(_ inputs: Inputs) async throws -> Int {
        try await writer.compact(now: inputs.now, calendar: inputs.calendar)
    }

    /// **这里没有 `?? LedgerView(...)`。**一份空的读模型在屏幕上和「这个月花了 $0」
    /// 长得一模一样，而且紧接着那次同步会拿这份空的去重折，把磁盘上的账本一并抹掉——
    /// 一次临时的读失败于是变成一次不可逆的数据损失。闸盯着这一行
    /// （`check_ledger_read_not_swallowed`）。
    private static func view(_ inputs: Inputs, in context: ModelContext) throws -> LedgerView {
        try MonthlyLedgerStore.view(
            subscriptions: inputs.subscriptions,
            calendar: inputs.calendar,
            in: context
        )
    }

    // MARK: - 原始读数

    /// **门上明确开的那个口**：几个账号最近一段的原始读数，按 `fetchedAt` 升序。
    /// 范围由调用方说清，不是拿到全部自己挑——「哪条读数算数」于是只有一个出处。
    public func readings(
        accountIDs: Set<AccountID>,
        since: Date?,
        calendar: Calendar
    ) -> [Snapshot] {
        let context = ModelContext(container)
        return (try? SnapshotLog.snapshots(
            accountIDs: accountIDs,
            since: since,
            calendar: calendar,
            in: context
        )) ?? []
    }

    /// 这个账号有没有过读到数的读数。刷新失败时决定标「陈旧」还是「失败」。
    /// 不要日历——它是一次列级计数，不解任何 blob（见 `SnapshotLog.hasBillableReading`）。
    public func hasBillableReading(accountID: AccountID) -> Bool {
        let context = ModelContext(container)
        return (try? SnapshotLog.hasBillableReading(
            accountID: accountID,
            in: context
        )) ?? false
    }

    public func snapshotCount() -> Int {
        (try? SnapshotLog.count(in: ModelContext(container))) ?? 0
    }

    // MARK: - 开发页

    #if DEBUG
    /// 整份日志。只给开发页的 dump 和试验台——它们就是要看原始记录。
    public func allReadings(calendar: Calendar) -> [Snapshot] {
        (try? SnapshotLog.snapshots(accountIDs: nil, calendar: calendar, in: ModelContext(container))) ?? []
    }

    /// 开发页那一节要的两个数。不进正式包。
    /// 读不出来回 `-1`（不是 0）：0 是「真的一行都没有」，这里要能分辨。
    public func stats(_ inputs: Inputs) throws -> (rows: Int, inSync: Bool) {
        let context = ModelContext(container)
        let rows = try MonthlyLedgerStore.all(calendar: inputs.calendar, in: context).count
        return (rows, MonthlyLedgerStore.isInSync(inputs.scope, in: context))
    }

    /// 拿库里那份账本和全量重算逐项对一遍，几种取景框各来一次。
    ///
    /// **这是整个物化账本方案能不能信的凭据。**返回空数组才叫一致；
    /// 任何一行都意味着屏幕上某个数字会因为"从哪条路读的"而不同。
    public func selfCheck(_ inputs: Inputs, excludedAccounts: Set<AccountID>) async -> [String] {
        let container = self.container
        return await Task.detached(priority: .userInitiated) { () -> [String] in
            let context = ModelContext(container)
            guard let view = try? Self.view(inputs, in: context) else {
                return ["账本读不出来（对账没跑）"]
            }
            let snapshots = (try? SnapshotLog.snapshots(
                accountIDs: inputs.accountIDs,
                calendar: inputs.calendar,
                in: context
            )) ?? []
            let cases: [(String, DashboardFilter)] = [
                ("本月", DashboardFilter()),
                ("上月", DashboardFilter(monthsBack: 1)),
                ("近 3 个月", DashboardFilter(period: .months(back: 0, count: 3))),
                ("今年至今", DashboardFilter(period: .yearToDate)),
                ("有数据以来", DashboardFilter(period: .allTime)),
                ("仅按量", DashboardFilter(includesSubscriptions: false)),
                ("排一家", DashboardFilter(excludedAccounts: excludedAccounts)),
            ]
            var out: [String] = []
            for (name, filter) in cases {
                let viaLedger = LedgerProjection.compute(
                    rollups: view.rollups,
                    subscriptions: view.subscriptions,
                    now: inputs.now,
                    calendar: inputs.calendar,
                    filter: filter
                )
                let viaRecompute = PeriodTotalCalculator.compute(
                    snapshots: snapshots,
                    subscriptions: inputs.subscriptions,
                    now: inputs.now,
                    calendar: inputs.calendar,
                    filter: filter,
                    endedAccounts: inputs.endedAccounts
                )
                for issue in LedgerSelfCheck.compare(ledger: viaLedger, recompute: viaRecompute) {
                    out.append("\(name) · \(issue.description)")
                }
            }
            return out
        }.value
    }
    #endif
}
