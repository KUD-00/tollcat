import Foundation

/// 当前日历月的闭开区间。时间从调用方传入，这里不碰 `Date()`。
struct CalendarMonthWindow: Sendable, Equatable {
    var start: Date
    var endInclusive: Date
    var nextStart: Date

    static func current(now: Date, calendar: Calendar) -> CalendarMonthWindow {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let next = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        let end = calendar.date(byAdding: .day, value: -1, to: next) ?? now
        return CalendarMonthWindow(start: start, endInclusive: end, nextStart: next)
    }

    /// 当前月再往回 `lookback` 个整月，最老的在前。`lookback` 0 就是只要当前月。
    static func months(lookback: Int, now: Date, calendar: Calendar) -> [CalendarMonthWindow] {
        let current = Self.current(now: now, calendar: calendar)
        return (0...max(lookback, 0)).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: current.start) else {
                return nil
            }
            return Self.current(now: date, calendar: calendar)
        }
    }

    static func months(
        for horizon: BillingFetchHorizon,
        lookbackMonths: Int,
        now: Date,
        calendar: Calendar
    ) -> [CalendarMonthWindow] {
        switch horizon {
        case .currentMonth:
            return [current(now: now, calendar: calendar)]
        case .availableHistory:
            return months(lookback: max(lookbackMonths, 1), now: now, calendar: calendar)
        }
    }

    /// 从最早那个月月初到当前月的 `nextStart`。单次区间接口用这一段。
    static func spanning(
        for horizon: BillingFetchHorizon,
        lookbackMonths: Int,
        now: Date,
        calendar: Calendar
    ) -> CalendarMonthWindow {
        let months = Self.months(for: horizon, lookbackMonths: lookbackMonths, now: now, calendar: calendar)
        guard let first = months.first, let last = months.last else {
            return current(now: now, calendar: calendar)
        }
        return CalendarMonthWindow(
            start: first.start,
            endInclusive: last.endInclusive,
            nextStart: last.nextStart
        )
    }

    /// 落在本月（含首日，不含下月首日）。
    func contains(_ date: Date) -> Bool {
        date >= start && date < nextStart
    }

    /// 越界的日期钳回本月边界。
    func clamp(_ date: Date) -> Date {
        if date < start { return start }
        if date >= nextStart { return endInclusive }
        return date
    }

    func dayString(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    func rfc3339(_ date: Date) -> String {
        BillingDateParser.rfc3339(date)
    }
}
