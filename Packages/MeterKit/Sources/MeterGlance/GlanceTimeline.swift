import Foundation

/// 小组件时间线里该排哪几个时刻。iPhone 锁屏和手表表盘用同一份。
///
/// 数字本身只在 iPhone 推来新数时变，那一下由壳主动重载；
/// 这里只管**没有人通知、但话该变了**的那几刻：
/// 变旧的那一刻、变旧之后「几小时前」每小时跳一次、以及跨月。
public enum GlanceTimeline {
    /// 变旧之后最多再排几个整点。再往后就停在最后一句，等下一次推送。
    static let hourlyAfterStale = 12

    public static func entryDates(for glance: Glance?, now: Date) -> [Date] {
        var dates = [now]
        guard let glance else { return dates }
        if let staleAt = glance.staleAt {
            for hour in 0...hourlyAfterStale {
                dates.append(staleAt.addingTimeInterval(TimeInterval(hour) * 3600))
            }
        }
        dates.append(glance.monthEnd)
        return Array(Set(dates.filter { $0 >= now })).sorted()
    }
}
