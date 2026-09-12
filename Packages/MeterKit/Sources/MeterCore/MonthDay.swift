import Foundation

/// 日超出当月天数时钳到月末。
///
/// 订阅扣款和每月提醒共用这一处（SPEC 12.5：宁可日期差一天，不可漏一次）。
public enum MonthDay: Sendable {
    public static func clamped(_ dayOfMonth: Int, daysInMonth: Int) -> Int {
        min(max(dayOfMonth, 1), max(daysInMonth, 1))
    }

    public static func clamped(_ dayOfMonth: Int, in monthDate: Date, calendar: Calendar) -> Int? {
        guard let days = calendar.range(of: .day, in: .month, for: monthDate)?.count, days > 0 else {
            return nil
        }
        return clamped(dayOfMonth, daysInMonth: days)
    }

    public static func date(
        dayOfMonth: Int,
        in monthDate: Date,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> Date? {
        guard let day = clamped(dayOfMonth, in: monthDate, calendar: calendar) else {
            return nil
        }
        var components = calendar.dateComponents([.year, .month], from: monthDate)
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)
    }
}
