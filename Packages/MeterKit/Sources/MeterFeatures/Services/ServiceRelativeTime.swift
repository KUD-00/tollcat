import Foundation

enum ServiceRelativeTime {
    static func caption(from date: Date, now: Date, calendar: Calendar) -> String {
        let elapsed = now.timeIntervalSince(date)
        // 刷新时刻不可能在「现在」之后。时钟落后时系统会写成「一小时后」。
        if elapsed < 60 {
            return String(localized: L("刚刚"))
        }
        if elapsed < 86_400 {
            return MeterDateFormat.relative(from: date, now: now, calendar: calendar)
        }
        return MeterDateFormat.monthAndDay(date, calendar: calendar)
    }
}
