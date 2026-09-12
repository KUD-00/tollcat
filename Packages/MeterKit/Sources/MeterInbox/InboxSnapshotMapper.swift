import Foundation
import MeterCore

/// 把一条投递读数折成 `Snapshot`。
///
/// `kind` 由调用方从 `ProviderCatalog` 取来传进来：本模块不认识 provider 目录，
/// 也不该认识。让投递方自己声明 kind 更不行——同一家的历史会串种（SPEC 第 07 节）。
public enum InboxSnapshotMapper: Sendable {
    /// 周期起点和投递方给的月份对齐；周期终点取那个月的最后一天，
    /// 不用 `now` 所在的月——投递方可能在 9 月 1 日补投 8 月的数。
    public static func snapshot(
        from reading: InboxReading,
        kind: ProviderKind,
        calendar: Calendar
    ) -> Snapshot {
        let start = calendar.date(
            from: calendar.dateComponents([.year, .month], from: reading.periodStart)
        ) ?? reading.periodStart
        let next = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        let end = calendar.date(byAdding: .day, value: -1, to: next) ?? start

        return Snapshot(
            providerID: reading.providerID,
            kind: kind,
            source: .inbox,
            fetchedAt: reading.reportedAt,
            periodStart: start,
            periodEnd: end,
            currentSpendUSD: reading.currentSpendUSD
        )
    }

    /// 投递的是「本月至今累计」，所以只往 `currentSpendUSD` 上落。
    /// 预充值、订阅、免费额度这三种 kind 读不出对应字段，会得到一条没有读数的快照 ——
    /// 这是对的：与其把一个月累计硬塞进 `balanceUSD`，不如显示「这次没读到」。
    ///
    /// 判据本身在 `ProviderKind.manualEntryKind`：手填走的是同一条约束，
    /// 两处各写一遍迟早有一处漏掉（手填那条就漏过）。
    public static func canRepresent(_ kind: ProviderKind) -> Bool {
        kind.manualEntryKind == kind
    }
}
