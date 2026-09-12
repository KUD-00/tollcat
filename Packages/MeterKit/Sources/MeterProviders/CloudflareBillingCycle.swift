import Foundation

/// Cloudflare 用量按订阅锚点日切月，不是日历月。
///
/// 锚点是账号第一次付费那天，`/billable-usage/info` 的
/// `billing_cycle_anchor_timestamp`。没有 31 号的月份钳到月末。
/// 内部是半开区间 `[start, nextStart)`；问 API 时 `to` 用最后一天（含）。
struct CloudflareBillingCycle: Sendable, Equatable {
    var start: Date
    var nextStart: Date
    var anchorDay: Int

    func endInclusive(calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: -1, to: nextStart) ?? start
    }

    /// 当前周期从月中开始时，本月 1 号到锚点前一天还在上一周期里。
    func overlapsPriorCycle(in window: CalendarMonthWindow) -> Bool {
        start > window.start
    }

    func preceding(calendar: Calendar) -> CloudflareBillingCycle {
        let probe = calendar.date(byAdding: .day, value: -1, to: start) ?? start
        return Self.containing(now: probe, anchorDay: anchorDay, calendar: calendar)
    }

    func previousCycles(count: Int, calendar: Calendar) -> [CloudflareBillingCycle] {
        guard count >= 1 else { return [] }
        var result: [CloudflareBillingCycle] = []
        result.reserveCapacity(count)
        var cursor = self
        for _ in 0..<count {
            cursor = cursor.preceding(calendar: calendar)
            result.append(cursor)
        }
        return result
    }

    static func containing(now: Date, anchor: Date, calendar: Calendar) -> CloudflareBillingCycle {
        let day = calendar.component(.day, from: calendar.startOfDay(for: anchor))
        return containing(now: now, anchorDay: day, calendar: calendar)
    }

    static func containing(now: Date, anchorDay: Int, calendar: Calendar) -> CloudflareBillingCycle {
        let day = min(max(anchorDay, 1), 31)
        let today = calendar.startOfDay(for: now)
        let startThisMonth = clamped(day: day, yearMonthOf: today, calendar: calendar)
        let start: Date
        if today >= startThisMonth {
            start = startThisMonth
        } else {
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: startThisMonth)
                ?? startThisMonth
            start = clamped(day: day, yearMonthOf: previousMonth, calendar: calendar)
        }
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        var nextStart = clamped(day: day, yearMonthOf: nextMonth, calendar: calendar)
        if nextStart <= start {
            nextStart = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        }
        return CloudflareBillingCycle(start: start, nextStart: nextStart, anchorDay: day)
    }

    static func current(anchors: [Date], now: Date, calendar: Calendar) -> CloudflareBillingCycle? {
        let cycles = anchors.map { containing(now: now, anchor: $0, calendar: calendar) }
        return cycles.max(by: { $0.start < $1.start })
    }

    private static func clamped(day: Int, yearMonthOf base: Date, calendar: Calendar) -> Date {
        let parts = calendar.dateComponents([.year, .month], from: base)
        let monthStart = calendar.date(
            from: DateComponents(year: parts.year, month: parts.month, day: 1)
        ) ?? calendar.startOfDay(for: base)
        let days = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 28
        return calendar.date(
            from: DateComponents(year: parts.year, month: parts.month, day: min(day, days))
        ) ?? monthStart
    }
}
