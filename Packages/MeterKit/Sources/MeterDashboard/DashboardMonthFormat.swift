import Foundation
import MeterFormat

/// 仪表导航标题和统计区间。跟当前 locale。
public enum DashboardMonthFormat {
    public static func title(now: Date, calendar: Calendar) -> String {
        MeterDateFormat.monthName(now: now, calendar: calendar)
    }

    /// 统计区间的起讫。`monthCount` > 1 时从窗口第一个月的 1 号起算——
    /// 顶上写着「近 3 个月」，下面那行却只写本月 1 号到今天，是页面在自我矛盾。
    public static func period(now: Date, calendar: Calendar, monthCount: Int = 1) -> String {
        MeterDateFormat.period(
            from: start(now: now, calendar: calendar, monthCount: monthCount),
            to: now,
            calendar: calendar
        )
    }

    public static func spokenPeriod(now: Date, calendar: Calendar, monthCount: Int = 1) -> String {
        MeterDateFormat.spokenPeriod(
            from: start(now: now, calendar: calendar, monthCount: monthCount),
            to: now,
            calendar: calendar
        )
    }

    private static func start(now: Date, calendar: Calendar, monthCount: Int) -> Date {
        guard
            let newestStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
            let start = calendar.date(byAdding: .month, value: -(max(monthCount, 1) - 1), to: newestStart)
        else {
            return now
        }
        return start
    }
}
