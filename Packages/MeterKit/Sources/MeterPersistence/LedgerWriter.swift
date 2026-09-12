import Foundation
import SwiftData
import MeterCore

/// 账本三张表的**唯一写者**。所有折叠都排在这一条队上。
///
/// ## 为什么必须串行
///
/// 账本行的「一个（账号, 月）只有一行」以前靠 `MonthlyLedgerStore.rebuild` 里的
/// 「先查再写」保证，而那是在**调用方自己的 `ModelContext`** 里做的。同时可能在跑的
/// 写路有三条：刷新每家回来一条走 `applied`、写库之后排的 `synced`、开发页的
/// `rebuilt`。两条各开一个 context、各自「没查到就 insert」，同一（账号, 月）就落两行。
///
/// 两行的表现是**这家这个月翻倍**——`MonthlyLedgerStore.all` 不去重，投影把两行都加
/// 进合计，界面上完全正常。而下一次 `isInSync` 也发现不了：指纹比的是输入，输入没变。
///
/// 串成一条队之后，「先查再写」中间不可能插进另一次写，重复行在构造上就不会出现。
///
/// ## 为什么每次开一个新 context 而不是长期持有一个
///
/// 长期持有那份会缓存已注册的对象。而账本行**不只这里在动**：清空一家
/// （`purgeMembershipRecords`）、导入迁移包都会在它们自己的事务里删账本行，
/// 和删快照落在同一个 save 里（那是对的，不能拆）。长期 context 手里那份缓存
/// 于是会指向已经被删掉的行，下一次折叠再把它们写回去——凭空复活一家的账。
///
/// 要的性质是**互斥**，不是「同一个 context」。actor 已经给了互斥。
public actor LedgerWriter {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    /// 对不上就重折。回 `nil` 表示本来就对得上，什么都没写。
    ///
    /// **分两档**：只有「今天」翻了页就只重折当月那一行，别的月份一行不碰；
    /// 输入真的变了（新读数、结束账号、换时区）才整份重折。理由见
    /// `MonthlyLedgerStore.SyncVerdict`。
    func syncIfNeeded(_ scope: MonthlyLedgerStore.Scope) throws -> Int? {
        let context = ModelContext(container)
        switch MonthlyLedgerStore.verdict(scope, in: context) {
        case .inSync:
            return nil
        case .staleToday:
            return try MonthlyLedgerStore.refoldCurrentMonth(scope, in: context)
        case .staleInputs:
            return try MonthlyLedgerStore.rebuildAll(scope, in: context)
        }
    }

    /// 一条新快照落库之后的增量：只重折它那个账号。
    func apply(_ snapshot: Snapshot, scope: MonthlyLedgerStore.Scope) throws {
        try MonthlyLedgerStore.apply(snapshot, scope: scope, in: ModelContext(container))
    }

    /// 整份重建，不看对不对得上。
    @discardableResult
    func rebuildAll(_ scope: MonthlyLedgerStore.Scope) throws -> Int {
        try MonthlyLedgerStore.rebuildAll(scope, in: ModelContext(container))
    }

    /// 窗口以外的快照压掉。**排在同步之后**，所以账本那时候是从完整历史折出来的
    /// （SPEC 12.5 的「先折后删」）。删除和作废戳在同一个事务里，见 `SnapshotCompactor`。
    @discardableResult
    func compact(now: Date, calendar: Calendar) throws -> Int {
        try SnapshotCompactor.compact(now: now, calendar: calendar, in: ModelContext(container))
    }
}
