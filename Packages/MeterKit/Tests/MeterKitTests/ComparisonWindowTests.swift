import Foundation
import Testing
@testable import MeterCore

/// 终点**按日截断**：上月同日的下一天零点，同一天整天都在窗口里。
///
/// 以前它拷 `now` 的时分秒，于是同一天里早上折的账本和下午重算的结果不一样
/// （指纹的粒度是天，说「还作数」）。理由写在 `ComparisonWindow` 的注释里。
struct ComparisonWindowTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("8 月 16 日对比 7 月 1 日到 7 月 16 日整天结束")
    func augustComparesToSameDayInJuly() throws {
        let now = date(2026, 8, 16, 12)
        let window = try #require(ComparisonWindow.samePeriodLastMonth(now: now, calendar: calendar))

        #expect(window.start == date(2026, 7, 1))
        // 终点不含：7 月 17 日零点 = 「16 号整天都算进来」。
        #expect(window.end == date(2026, 7, 17))
        #expect(window.dayOfMonth == 16)
        #expect(window.month(calendar: calendar) == 7)
    }

    @Test("3 月 31 日钳到 2 月最后一天（平年 28）")
    func march31ClampsToFebruary28InCommonYear() throws {
        let now = date(2026, 3, 31, 12)
        let window = try #require(ComparisonWindow.samePeriodLastMonth(now: now, calendar: calendar))

        #expect(window.start == date(2026, 2, 1))
        #expect(window.end == date(2026, 3, 1))
        #expect(window.dayOfMonth == 28)
        #expect(window.month(calendar: calendar) == 2)
    }

    @Test("3 月 31 日钳到 2 月最后一天（闰年 29）")
    func march31ClampsToFebruary29InLeapYear() throws {
        let now = date(2024, 3, 31, 15, 30)
        let window = try #require(ComparisonWindow.samePeriodLastMonth(now: now, calendar: calendar))

        #expect(window.start == date(2024, 2, 1))
        // `now` 的 15:30 不再进终点：同一天里读两次得到同一个窗口。
        #expect(window.end == date(2024, 3, 1))
        #expect(window.dayOfMonth == 29)
    }

    @Test("5 月 31 日钳到 4 月 30 日")
    func may31ClampsToApril30() throws {
        let now = date(2026, 5, 31, 8)
        let window = try #require(ComparisonWindow.samePeriodLastMonth(now: now, calendar: calendar))

        #expect(window.start == date(2026, 4, 1))
        #expect(window.end == date(2026, 5, 1))
        #expect(window.dayOfMonth == 30)
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0,
        _ second: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return calendar.date(from: components)!
    }
}
