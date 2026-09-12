import Foundation
import Testing
@testable import MeterCore

struct ReminderSchedulerTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    /// 提交闸 `scripts/check-source-invariants.py` 也扫这一条。
    @Test("MeterCore 不引用 UserNotifications")
    func coreDoesNotImportUserNotifications() throws {
        let dir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/MeterCore")
        let files = try FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        )
        for file in files where file.pathExtension == "swift" {
            let text = try String(contentsOf: file, encoding: .utf8)
            #expect(
                !text.contains("import UserNotifications"),
                "\(file.lastPathComponent) 不该 import UserNotifications"
            )
        }
    }

    @Test("每天：时刻未过则今天，过了则明天")
    func dailyUsesTodayOrTomorrow() {
        let schedule = ReminderSchedule(frequency: .daily, hour: 21, minute: 0)
        let before = ReminderScheduler.nextDate(
            schedule: schedule,
            now: date(2026, 8, 16, 20, 30),
            calendar: calendar
        )
        let after = ReminderScheduler.nextDate(
            schedule: schedule,
            now: date(2026, 8, 16, 21, 1),
            calendar: calendar
        )

        #expect(before == date(2026, 8, 16, 21))
        #expect(after == date(2026, 8, 17, 21))
    }

    @Test("每天排出 repeating 的时分分量")
    func dailyTriggerIsRepeatingHourMinute() {
        let specs = ReminderScheduler.triggerSpecs(
            schedule: ReminderSchedule(frequency: .daily, hour: 21, minute: 30),
            now: date(2026, 8, 16, 12),
            calendar: calendar
        )

        #expect(specs.count == 1)
        #expect(specs[0].repeats)
        #expect(specs[0].dateComponents.hour == 21)
        #expect(specs[0].dateComponents.minute == 30)
        #expect(specs[0].dateComponents.year == nil)
        #expect(specs[0].dateComponents.day == nil)
        #expect(ReminderScheduler.expectedRequestCount(for: .daily) == 1)
    }

    @Test("每周：周日晚上看，下一次是下周一")
    func weeklyFindsNextWeekday() {
        // 2026-08-16 是星期日。
        let schedule = ReminderSchedule(frequency: .weekly, hour: 21, minute: 0, weekday: 2)
        let next = ReminderScheduler.nextDate(
            schedule: schedule,
            now: date(2026, 8, 16, 12),
            calendar: calendar
        )

        #expect(next == date(2026, 8, 17, 21))
        #expect(calendar.component(.weekday, from: next!) == 2)
    }

    @Test("每周排出 repeating 的星期+时分")
    func weeklyTriggerIsRepeatingWeekday() {
        let specs = ReminderScheduler.triggerSpecs(
            schedule: ReminderSchedule(frequency: .weekly, hour: 21, minute: 0, weekday: 2),
            now: date(2026, 8, 16, 12),
            calendar: calendar
        )

        #expect(specs.count == 1)
        #expect(specs[0].repeats)
        #expect(specs[0].dateComponents.weekday == 2)
        #expect(specs[0].dateComponents.hour == 21)
        #expect(specs[0].dateComponents.year == nil)
        #expect(ReminderScheduler.expectedRequestCount(for: .weekly) == 1)
    }

    @Test("每两周从下一次该星期起，之后隔 14 天")
    func biweeklyStridesFourteenDays() {
        let schedule = ReminderSchedule(frequency: .biweekly, hour: 21, minute: 0, weekday: 2)
        let dates = ReminderScheduler.nextDates(
            schedule: schedule,
            now: date(2026, 8, 16, 12),
            calendar: calendar,
            count: 3
        )

        #expect(dates == [
            date(2026, 8, 17, 21),
            date(2026, 8, 31, 21),
            date(2026, 9, 14, 21),
        ])
    }

    @Test("每两周当天时刻已过，下一次是 14 天后而不是 7 天后")
    func biweeklySkipsTheInBetweenWeek() {
        let schedule = ReminderSchedule(frequency: .biweekly, hour: 21, minute: 0, weekday: 1)
        let next = ReminderScheduler.nextDate(
            schedule: schedule,
            now: date(2026, 8, 16, 21, 30),
            calendar: calendar
        )

        #expect(next == date(2026, 8, 30, 21))
    }

    @Test("每两周排出若干次不重复的完整日期")
    func biweeklyTriggersAreOneShotDates() {
        let specs = ReminderScheduler.triggerSpecs(
            schedule: ReminderSchedule(frequency: .biweekly, hour: 21, minute: 0, weekday: 2),
            now: date(2026, 8, 16, 12),
            calendar: calendar
        )

        #expect(specs.count == ReminderScheduler.oneShotHorizon)
        #expect(specs.allSatisfy { !$0.repeats })
        #expect(specs[0].dateComponents.year == 2026)
        #expect(specs[0].dateComponents.month == 8)
        #expect(specs[0].dateComponents.day == 17)
        #expect(ReminderScheduler.expectedRequestCount(for: .biweekly) == ReminderScheduler.oneShotHorizon)
    }

    @Test("每月 31 号在 2 月钳到月末，和平年订阅扣款同一套规则")
    func monthlyDay31ClampsInFebruary() {
        let schedule = ReminderSchedule(frequency: .monthly, hour: 21, minute: 0, dayOfMonth: 31)
        let fromJanuary = ReminderScheduler.nextDates(
            schedule: schedule,
            now: date(2026, 1, 15, 12),
            calendar: calendar,
            count: 3
        )
        let fromLateFebruary = ReminderScheduler.nextDate(
            schedule: schedule,
            now: date(2026, 2, 28, 22),
            calendar: calendar
        )
        let stillInFebruary = ReminderScheduler.nextDate(
            schedule: schedule,
            now: date(2026, 2, 28, 20),
            calendar: calendar
        )
        let leap = ReminderScheduler.nextDate(
            schedule: schedule,
            now: date(2028, 2, 1, 12),
            calendar: calendar
        )

        #expect(fromJanuary == [
            date(2026, 1, 31, 21),
            date(2026, 2, 28, 21),
            date(2026, 3, 31, 21),
        ])
        #expect(fromLateFebruary == date(2026, 3, 31, 21))
        #expect(stillInFebruary == date(2026, 2, 28, 21))
        #expect(leap == date(2028, 2, 29, 21))
        #expect(MonthDay.clamped(31, in: date(2026, 2, 1), calendar: calendar) == 28)
        #expect(MonthDay.clamped(31, in: date(2028, 2, 1), calendar: calendar) == 29)
    }

    @Test("每月排出不重复的年/月/日，2 月是钳过的")
    func monthlyTriggersUseClampedDay() {
        let specs = ReminderScheduler.triggerSpecs(
            schedule: ReminderSchedule(frequency: .monthly, hour: 21, minute: 0, dayOfMonth: 31),
            now: date(2026, 1, 15, 12),
            calendar: calendar
        )

        #expect(specs.count == ReminderScheduler.oneShotHorizon)
        #expect(specs.allSatisfy { !$0.repeats })
        #expect(specs[0].dateComponents.day == 31)
        #expect(specs[1].dateComponents.month == 2)
        #expect(specs[1].dateComponents.day == 28)
        #expect(ReminderScheduler.expectedRequestCount(for: .monthly) == ReminderScheduler.oneShotHorizon)
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)!
    }
}
