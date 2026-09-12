import Foundation

/// 这家账单接口对刷新的约束。和 `costsMoneyToRefresh` 正交。
///
/// - `costsMoneyToRefresh`：打一次要花钱，默认不进全局刷新。
/// - 这里：对方按天限流、或数据按天才更新。再打也拿不到更新的数，
///   只会把当天额度刷光。自动刷新和手动下拉都尊重 `minimumInterval`。
///
/// 不在客户端倒数「还剩几次」。间隔挡住常态滥用；真撞上限走 429。
/// 接入测试和「拉取更多历史」不走这里，那两下是用户明确要现在打。
public enum RefreshCadence: Sendable {
    /// 自动刷新：全局保鲜期和这家自己的最短间隔取更严的那个。
    public static func autoInterval(
        minimumRefreshInterval: TimeInterval,
        defaultFreshness: TimeInterval
    ) -> TimeInterval {
        max(max(0, minimumRefreshInterval), max(0, defaultFreshness))
    }

    /// 该不该再打一次。`minimumInterval == 0` 表示这条路径不另限。
    ///
    /// 从没成功过（`nil`）和盖在未来的章（时钟往回跳）一律要打，
    /// 否则这家会被冻住。
    public static func shouldFetch(
        lastSuccessfulRefreshAt: Date?,
        now: Date,
        minimumInterval: TimeInterval
    ) -> Bool {
        guard minimumInterval > 0 else { return true }
        guard let last = lastSuccessfulRefreshAt else { return true }
        guard last <= now else { return true }
        return now.timeIntervalSince(last) >= minimumInterval
    }
}
