import Foundation

/// 把「多久提醒一次」收成下一次（或若干次）应触发的日期分量。
///
/// 只做日历算术。不引入 Apple 的通知框架，Core 要保持可移植
///（ARCHITECTURE 第 4 条）。时间一律从参数进来。
///
/// 不做金额告警，也不知道金额——输入只有频率、时刻和 now。
/// 通知里放什么由展示层决定，这里不产出任何文案。
public enum ReminderScheduler: Sendable {
    /// 不能用 repeating calendar trigger 的档位，预先排出这么多次。
    public static let oneShotHorizon = 8

    public static func expectedRequestCount(for frequency: ReminderFrequency) -> Int {
        switch frequency {
        case .daily, .weekly:
            return 1
        case .biweekly, .monthly:
            return oneShotHorizon
        }
    }

    public static func triggerSpecs(
        schedule: ReminderSchedule,
        now: Date,
        calendar: Calendar
    ) -> [ReminderTriggerSpec] {
        switch schedule.frequency {
        case .daily:
            return [
                ReminderTriggerSpec(
                    dateComponents: stamped(
                        DateComponents(hour: schedule.hour, minute: schedule.minute),
                        calendar: calendar
                    ),
                    repeats: true
                )
            ]
        case .weekly:
            return [
                ReminderTriggerSpec(
                    dateComponents: stamped(
                        DateComponents(
                            hour: schedule.hour,
                            minute: schedule.minute,
                            weekday: schedule.weekday
                        ),
                        calendar: calendar
                    ),
                    repeats: true
                )
            ]
        case .biweekly, .monthly:
            return nextDates(
                schedule: schedule,
                now: now,
                calendar: calendar,
                count: oneShotHorizon
            ).map { date in
                ReminderTriggerSpec(
                    dateComponents: stamped(
                        calendar.dateComponents(
                            [.year, .month, .day, .hour, .minute],
                            from: date
                        ),
                        calendar: calendar
                    ),
                    repeats: false
                )
            }
        }
    }

    public static func nextDate(
        schedule: ReminderSchedule,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        switch schedule.frequency {
        case .daily:
            return nextDaily(schedule, now: now, calendar: calendar)
        case .weekly:
            return nextWeekday(schedule, now: now, calendar: calendar, intervalDays: 7)
        case .biweekly:
            return nextWeekday(schedule, now: now, calendar: calendar, intervalDays: 14)
        case .monthly:
            return nextMonthly(schedule, now: now, calendar: calendar)
        }
    }

    public static func nextDates(
        schedule: ReminderSchedule,
        now: Date,
        calendar: Calendar,
        count: Int
    ) -> [Date] {
        guard count > 0, let first = nextDate(schedule: schedule, now: now, calendar: calendar) else {
            return []
        }
        var dates = [first]
        switch schedule.frequency {
        case .daily:
            appendStride(from: first, count: count, component: .day, value: 1, calendar: calendar, into: &dates)
        case .weekly:
            appendStride(from: first, count: count, component: .day, value: 7, calendar: calendar, into: &dates)
        case .biweekly:
            appendStride(from: first, count: count, component: .day, value: 14, calendar: calendar, into: &dates)
        case .monthly:
            var cursor = first.addingTimeInterval(1)
            while dates.count < count {
                guard let date = nextMonthly(schedule, now: cursor, calendar: calendar) else { break }
                dates.append(date)
                cursor = date.addingTimeInterval(1)
            }
        }
        return dates
    }

    private static func nextDaily(
        _ schedule: ReminderSchedule,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = schedule.hour
        components.minute = schedule.minute
        components.second = 0
        guard let today = calendar.date(from: components) else { return nil }
        if today >= now {
            return today
        }
        return calendar.date(byAdding: .day, value: 1, to: today)
    }

    private static func nextWeekday(
        _ schedule: ReminderSchedule,
        now: Date,
        calendar: Calendar,
        intervalDays: Int
    ) -> Date? {
        let todayWeekday = calendar.component(.weekday, from: now)
        var daysAhead = schedule.weekday - todayWeekday
        if daysAhead < 0 {
            daysAhead += 7
        }
        guard
            let day = calendar.date(byAdding: .day, value: daysAhead, to: calendar.startOfDay(for: now))
        else {
            return nil
        }
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = schedule.hour
        components.minute = schedule.minute
        components.second = 0
        guard let candidate = calendar.date(from: components) else { return nil }
        if candidate >= now {
            return candidate
        }
        return calendar.date(byAdding: .day, value: intervalDays, to: candidate)
    }

    private static func nextMonthly(
        _ schedule: ReminderSchedule,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        guard
            let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        else {
            return nil
        }
        if let candidate = MonthDay.date(
            dayOfMonth: schedule.dayOfMonth,
            in: thisMonth,
            hour: schedule.hour,
            minute: schedule.minute,
            calendar: calendar
        ), candidate >= now {
            return candidate
        }
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: thisMonth) else {
            return nil
        }
        return MonthDay.date(
            dayOfMonth: schedule.dayOfMonth,
            in: nextMonth,
            hour: schedule.hour,
            minute: schedule.minute,
            calendar: calendar
        )
    }

    private static func appendStride(
        from first: Date,
        count: Int,
        component: Calendar.Component,
        value: Int,
        calendar: Calendar,
        into dates: inout [Date]
    ) {
        var offset = value
        while dates.count < count {
            guard let date = calendar.date(byAdding: component, value: offset, to: first) else {
                return
            }
            dates.append(date)
            offset += value
        }
    }

    private static func stamped(_ components: DateComponents, calendar: Calendar) -> DateComponents {
        var stamped = components
        stamped.calendar = calendar
        stamped.timeZone = calendar.timeZone
        stamped.second = 0
        stamped.nanosecond = 0
        return stamped
    }
}
