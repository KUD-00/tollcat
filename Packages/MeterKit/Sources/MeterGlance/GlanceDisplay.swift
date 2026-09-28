import Foundation

/// 某一刻表盘该说哪句话。`Glance` 是收到的数，这个是「现在还能不能这么说」的结论。
public enum GlanceDisplay: Equatable, Sendable {
    /// 手表上从来没收到过 iPhone 的数。
    case neverSynced
    case noBills
    /// 跨月了，手上是上个月的数；或者 iPhone 那边自己还没折出这个月。
    case waitingForMonth
    /// `staleSince` 非 nil：数据已经旧到该把刷新时间说出来。
    case month(GlanceMonth, staleSince: Date?)

    public static func resolve(_ glance: Glance?, now: Date) -> GlanceDisplay {
        guard let glance else { return .neverSynced }
        switch glance.content {
        case .noBills:
            return .noBills
        case .waitingForMonth:
            return .waitingForMonth
        case .month(let month):
            guard now < glance.monthEnd, now >= glance.monthStart else { return .waitingForMonth }
            if let staleAt = glance.staleAt, now >= staleAt {
                return .month(month, staleSince: glance.lastRefreshAt)
            }
            return .month(month, staleSince: nil)
        }
    }
}
