import Foundation
import MeterCore

/// 原始读数在内存里的那一份。`DashboardModel.readings(for:since:)` 的背面。
///
/// ## 为什么要有它
///
/// 详情页那几张图要的是原始读数，而原始读数在库里是三个 blob（日曲线、明细行、
/// 钱包槽）。取一次的代价是：新开一个 `ModelContext`、一条带 predicate 的查询、
/// 把命中的每一条解一遍。实测一家一年 52 条读数 = **46ms**，而这 46ms 发生在
/// SwiftUI 的 body 求值里、在主线程上。
///
/// 那 46ms 里绝大部分是白花的：刷新落一条新读数，前面 51 条一个字节都没变，
/// 却要连着它一起重新解一遍。
///
/// ## 招数和账本是同一个
///
/// `LedgerSync.apply` 落一条新快照时只重折**那一个账号**，不整份重折。这里一样：
/// 刷新落盘之后把那一条**追加**进手上这份，不回库里重读。库和内存于是各自
/// 增量维护，谁都不用为对方付全量的钱。
///
/// ## 什么时候必须扔掉
///
/// 追加只覆盖「多了一条」。**改写和删除必须整份扔掉**：
///
/// - 用户写库（加接入、手填、改订阅、删除、结束一家）→ `DashboardModel.didWrite()`
/// - 压缩把窗口外的快照删了 → `syncLedger()` 里那一趟之后
/// - 迁移导入、清空数据
///
/// 漏掉任何一条的表现是屏幕上那条历史曲线还画着已经删掉的点——不崩、不报错。
/// 所以入口只有一个 `invalidate()`，跟着 `didWrite()` 走，别处不许各自判断。
@MainActor
final class ReadingCache {
    private struct Entry {
        /// 这一份是从哪一刻起取的。请求要的起点**不早于**它才能用这一份。
        var since: Date
        /// 按 `fetchedAt` 升序。
        var readings: [Snapshot]
    }

    private var entries: [Set<AccountID>: Entry] = [:]

    /// 这几个账号从 `since` 起的读数。手上那份够用就直接筛，不够才走 `load`。
    ///
    /// `since` 会随着墙钟往前爬（窗口起点是「现在往回数 13 个月」），所以判据是
    /// **不早于**，不是相等：缓存里那份起点更早，说明它是个超集，筛一下就是答案。
    /// 用相等判会让这份缓存每过一秒就失效一次，等于没有。
    func readings(
        accountIDs: Set<AccountID>,
        since: Date,
        load: () -> [Snapshot]
    ) -> [Snapshot] {
        if let entry = entries[accountIDs], entry.since <= since {
            return entry.readings.filter { $0.fetchedAt >= since }
        }
        let loaded = load().sorted { $0.fetchedAt < $1.fetchedAt }
        entries[accountIDs] = Entry(since: since, readings: loaded)
        return loaded
    }

    /// 刷新 / 回填落盘之后追加一条。**只有这一条路能不重读就更新。**
    ///
    /// 同一个 `fetchedAt` 上已经有这个账号的读数就替换掉，不叠第二条：
    /// 落盘那边按 (账号, 时刻) 去重，内存这份不能比库里多出一条。
    func append(_ snapshot: Snapshot) {
        guard let accountID = snapshot.accountID else { return }
        for (accounts, var entry) in entries where accounts.contains(accountID) {
            entry.readings.removeAll {
                $0.accountID == accountID && $0.fetchedAt == snapshot.fetchedAt
            }
            let index = entry.readings.firstIndex { $0.fetchedAt > snapshot.fetchedAt }
                ?? entry.readings.endIndex
            entry.readings.insert(snapshot, at: index)
            entries[accounts] = entry
        }
    }

    /// 整份扔掉。改写和删除只能走这里——见上面「什么时候必须扔掉」。
    func invalidate() {
        entries.removeAll()
    }
}
