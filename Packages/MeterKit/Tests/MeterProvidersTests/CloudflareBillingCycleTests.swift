import Foundation
import Testing
@testable import MeterProviders

struct CloudflareBillingCycleTests {
    private let calendar = LiveProviderHarness.calendar

    /// 洛杉矶（UTC−7）。各家的日桶几乎都是 `...T00:00:00Z`，
    /// 按本机时区落日会让**每一个桶**退到前一天，1 号那个还会退到上个月。
    private var losAngeles: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    /// 「这一天存不存在」由 `DayKey.date(in:)` 判——它验分量能原样翻回来。
    /// 以前这里直接 `calendar.date(from:)`，`2026-02-30` 溢出成 3 月 2 日：
    /// 厂商真回过这种日期，那笔钱会落进错的月。落盘和解析现在是同一条判据。
    @Test("不存在的日子解不出来，不许溢出到下个月")
    func impossibleDatesAreRejected() {
        #expect(BillingDateParser.parse("2026-02-30", calendar: losAngeles) == nil)
        #expect(BillingDateParser.parse("2026-13-01", calendar: losAngeles) == nil)
        #expect(BillingDateParser.parse("2026-04-31", calendar: losAngeles) == nil)
        // 闰年那一天是存在的。
        #expect(BillingDateParser.parse("2024-02-29", calendar: losAngeles) != nil)
        #expect(BillingDateParser.parse("2026-02-28", calendar: losAngeles) != nil)
    }

    @Test("UTC 零点的日桶在 UTC 以西也落在厂商说的那一天")
    func utcMidnightBucketKeepsTheVendorDay() {
        let expected = losAngeles.date(from: DateComponents(year: 2026, month: 8, day: 1))
        #expect(BillingDateParser.parse("2026-08-01T00:00:00Z", calendar: losAngeles) == expected)
        #expect(
            BillingDateParser.parse("2026-08-01T00:00:00.000Z", calendar: losAngeles) == expected
        )
        // 带偏移的写法同样按它自己那个偏移里的日期算。
        #expect(
            BillingDateParser.parse("2026-08-01T23:30:00-07:00", calendar: losAngeles) == expected
        )
    }

    @Test("Unix 秒的日桶也按 UTC 落日")
    func unixSecondsBucketUsesUTCDay() {
        // 2026-08-01T00:00:00Z
        let seconds = 1_785_542_400
        #expect(
            BillingDateParser.parseUnixSeconds(seconds, calendar: losAngeles)
                == losAngeles.date(from: DateComponents(year: 2026, month: 8, day: 1))
        )
    }

    @Test("1 号锚点就是日历月")
    func firstOfMonthMatchesCalendar() {
        let now = LiveProviderHarness.date(2026, 8, 16, 12)
        let cycle = CloudflareBillingCycle.containing(
            now: now,
            anchor: LiveProviderHarness.date(2023, 1, 1),
            calendar: calendar
        )
        #expect(cycle.start == LiveProviderHarness.date(2026, 8, 1))
        #expect(cycle.nextStart == LiveProviderHarness.date(2026, 9, 1))
        #expect(cycle.endInclusive(calendar: calendar) == LiveProviderHarness.date(2026, 8, 31))
        #expect(cycle.anchorDay == 1)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        #expect(!cycle.overlapsPriorCycle(in: window))
    }

    @Test("月中锚点：锚点日之后是新周期，之前还在上一周期")
    func midMonthAnchorSplitsTheMonth() {
        let after = CloudflareBillingCycle.containing(
            now: LiveProviderHarness.date(2026, 8, 26, 12),
            anchorDay: 16,
            calendar: calendar
        )
        #expect(after.start == LiveProviderHarness.date(2026, 8, 16))
        #expect(after.nextStart == LiveProviderHarness.date(2026, 9, 16))
        #expect(after.endInclusive(calendar: calendar) == LiveProviderHarness.date(2026, 9, 15))
        #expect(after.overlapsPriorCycle(in: CalendarMonthWindow.current(
            now: LiveProviderHarness.date(2026, 8, 26, 12),
            calendar: calendar
        )))

        let before = CloudflareBillingCycle.containing(
            now: LiveProviderHarness.date(2026, 8, 10),
            anchorDay: 16,
            calendar: calendar
        )
        #expect(before.start == LiveProviderHarness.date(2026, 7, 16))
        #expect(before.nextStart == LiveProviderHarness.date(2026, 8, 16))
        #expect(!before.overlapsPriorCycle(in: CalendarMonthWindow.current(
            now: LiveProviderHarness.date(2026, 8, 10),
            calendar: calendar
        )))
    }

    @Test("上一周期的 nextStart 等于当前 start")
    func precedingAbutsCurrent() {
        let cycle = CloudflareBillingCycle.containing(
            now: LiveProviderHarness.date(2026, 8, 26),
            anchorDay: 16,
            calendar: calendar
        )
        let previous = cycle.preceding(calendar: calendar)
        #expect(previous.nextStart == cycle.start)
        #expect(previous.start == LiveProviderHarness.date(2026, 7, 16))
        #expect(previous.endInclusive(calendar: calendar) == LiveProviderHarness.date(2026, 8, 15))
    }

    @Test("没有 31 号的月份钳到月末，两段周期在边界相接")
    func missingThirtyFirstClampsAndAbuts() {
        let march = CloudflareBillingCycle.containing(
            now: LiveProviderHarness.date(2026, 3, 5),
            anchorDay: 31,
            calendar: calendar
        )
        #expect(march.start == LiveProviderHarness.date(2026, 2, 28))
        #expect(march.nextStart == LiveProviderHarness.date(2026, 3, 31))
        let january = march.preceding(calendar: calendar)
        #expect(january.start == LiveProviderHarness.date(2026, 1, 31))
        #expect(january.nextStart == march.start)
    }

    @Test("多个锚点取最近开始的当前周期")
    func latestAnchorWins() {
        let cycle = CloudflareBillingCycle.current(
            anchors: [
                LiveProviderHarness.date(2023, 1, 1),
                LiveProviderHarness.date(2024, 8, 16),
            ],
            now: LiveProviderHarness.date(2026, 8, 26),
            calendar: calendar
        )
        #expect(cycle?.start == LiveProviderHarness.date(2026, 8, 16))
    }
}
