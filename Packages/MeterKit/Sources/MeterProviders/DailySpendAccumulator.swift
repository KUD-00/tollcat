import Foundation
import MeterCore

/// 按日历日累加各家拆开的费用行。
struct DailySpendAccumulator: Sendable {
    private(set) var daily: [Date: Money] = [:]

    mutating func add(day: Date, amount: Money) {
        daily[day, default: .zero] += amount
    }

    var total: Money {
        daily.values.reduce(.zero, +)
    }

    var snapshotDaily: [Date: Money]? {
        daily.isEmpty ? nil : daily
    }

    func total(in window: CalendarMonthWindow, calendar: Calendar) -> Money {
        daily.reduce(into: .zero) { sum, entry in
            let day = calendar.startOfDay(for: entry.key)
            if window.contains(day) {
                sum += entry.value
            }
        }
    }

    /// 只有月合计、没有日线的历史：记在那个月月初。当前月不写——否则 7/30 天图
    /// 会在 1 号立一根整月的柱，把「本月至今」挤成一天。
    mutating func addPastMonth(
        start: Date,
        amount: Money,
        current: CalendarMonthWindow,
        calendar: Calendar
    ) {
        guard amount != .zero else { return }
        let month = CalendarMonthWindow.current(now: start, calendar: calendar)
        guard !current.contains(month.start) else { return }
        add(day: month.start, amount: amount)
    }
}
