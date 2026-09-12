import Foundation
import Testing
import MeterCore
@testable import MeterFeatures

@MainActor
struct DashboardClockOverrideTests {
    @Test("覆盖 now 会重算预计月底，月份标题跟着变")
    func overridingClockChangesProjectionAndMonth() async {
        let model = DashboardModel.preview
        // 演示种子折叠在后台排：`load` 只读账本表，不当场折。
        await model.syncLedger()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let mid = calendar.date(from: DateComponents(year: 2026, month: 8, day: 16, hour: 12))!
        model.setClock(MeterClock(now: mid, calendar: calendar))
        let midProjected = model.monthToDate?.projectedMonthEndUSD

        let start = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1, hour: 0))!
        model.setClock(MeterClock(now: start, calendar: calendar))
        let startProjected = model.monthToDate?.projectedMonthEndUSD

        #expect(midProjected != startProjected)
        #expect(monthName(model.clock.now, calendar: calendar) == "八月")

        let feb = calendar.date(from: DateComponents(year: 2028, month: 2, day: 29, hour: 12))!
        model.setClock(MeterClock(now: feb, calendar: calendar))
        #expect(monthName(model.clock.now, calendar: calendar) == "二月")
        #expect(calendar.component(.day, from: model.clock.now) == 29)
    }

    private func monthName(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
}
