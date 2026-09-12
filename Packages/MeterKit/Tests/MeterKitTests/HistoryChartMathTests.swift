import Foundation
import Testing
@testable import MeterCore

struct HistoryChartMathTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("7 天相邻窗不重叠、不留缝")
    func dayWindowsAreAdjacent() {
        let now = date(2026, 8, 16)
        let home = HistoryChartMath.window(range: .days7, now: now, calendar: calendar)
        let previous = HistoryChartMath.window(range: .days7, now: now, calendar: calendar, offset: 1)
        #expect(calendar.isDate(home.end, inSameDayAs: now))
        #expect(calendar.isDate(home.start, inSameDayAs: date(2026, 8, 10)))
        #expect(calendar.isDate(previous.end, inSameDayAs: date(2026, 8, 9)))
        #expect(calendar.isDate(previous.start, inSameDayAs: date(2026, 8, 3)))
        let gap = calendar.dateComponents([.day], from: previous.end, to: home.start).day
        #expect(gap == 1)
    }

    @Test("30 天翻一页是往前 30 天")
    func thirtyDayPageShiftsByThirty() {
        let now = date(2026, 8, 16)
        let home = HistoryChartMath.window(range: .days30, now: now, calendar: calendar)
        let previous = HistoryChartMath.window(range: .days30, now: now, calendar: calendar, offset: 1)
        #expect(calendar.isDate(home.start, inSameDayAs: date(2026, 7, 18)))
        #expect(calendar.isDate(previous.end, inSameDayAs: date(2026, 7, 17)))
        #expect(calendar.isDate(previous.start, inSameDayAs: date(2026, 6, 18)))
    }

    @Test("12 个月忽略 offset")
    func twelveMonthsIgnoresOffset() {
        let now = date(2026, 8, 16)
        let home = HistoryChartMath.window(range: .months12, now: now, calendar: calendar)
        let shifted = HistoryChartMath.window(range: .months12, now: now, calendar: calendar, offset: 4)
        #expect(home.start == shifted.start)
        #expect(home.end == shifted.end)
    }

    @Test("可平移的日线覆盖 12 个月回看，7 天和 30 天同一条")
    func spanLookbackUsesTwelveMonthDomain() {
        let now = date(2026, 8, 16)
        let account = AccountID.fixture(for: .cloudflare)
        let snapshots = [
            snapshot(account: account, day: date(2026, 8, 16), amount: 2.2),
            snapshot(account: account, day: date(2026, 8, 1), amount: 1.4),
        ]
        let week = HistoryChartMath.make(
            kind: .usage,
            snapshots: snapshots,
            range: .days7,
            now: now,
            calendar: calendar,
            spanLookback: true
        )
        let month = HistoryChartMath.make(
            kind: .usage,
            snapshots: snapshots,
            range: .days30,
            now: now,
            calendar: calendar,
            spanLookback: true
        )
        let lookback = HistoryChartMath.window(range: .months12, now: now, calendar: calendar)
        guard case .spend(let weekPoints, let weekStart, let weekEnd, false, _) = week else {
            Issue.record("expected day spend")
            return
        }
        guard case .spend(let monthPoints, let monthStart, _, false, _) = month else {
            Issue.record("expected day spend")
            return
        }
        #expect(calendar.isDate(weekStart, inSameDayAs: lookback.start))
        #expect(calendar.isDate(weekEnd, inSameDayAs: now))
        #expect(weekStart == monthStart)
        #expect(weekPoints.map(\.amount) == monthPoints.map(\.amount))
        #expect(weekPoints.contains { calendar.isDate($0.date, inSameDayAs: date(2026, 8, 1)) })
    }

    @Test("可平移日线按天混用日线和差量，七月的日线不顶掉八月的差量")
    func spanLookbackMixesDailyAndInterval() {
        let now = date(2026, 8, 16)
        let account = AccountID.fixture(for: .fly)
        let state = HistoryChartMath.make(
            kind: .usage,
            snapshots: [
                Snapshot(
                    providerID: .fly,
                    accountID: account,
                    kind: .usage,
                    fetchedAt: date(2026, 7, 1),
                    periodStart: date(2026, 7, 1),
                    periodEnd: date(2026, 7, 31),
                    currentSpendUSD: Money(usd: 40),
                    dailyUSD: [date(2026, 7, 1): Money(usd: 40)]
                ),
                Snapshot(
                    providerID: .fly,
                    accountID: account,
                    kind: .usage,
                    source: .inbox,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(usd: 8)
                ),
            ],
            range: .days30,
            now: now,
            calendar: calendar,
            spanLookback: true
        )
        guard case .spend(let points, _, _, false, true) = state else {
            Issue.record("expected mixed interval spend")
            return
        }
        #expect(points.contains { calendar.isDate($0.date, inSameDayAs: date(2026, 7, 1)) && $0.amount == 40 })
        #expect(points.contains { calendar.isDate($0.date, inSameDayAs: now) && $0.amount == 8 })
    }

    private func snapshot(account: AccountID, day: Date, amount: Double) -> Snapshot {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: day))!
        let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
        return Snapshot(
            providerID: .cloudflare,
            accountID: account,
            kind: .usage,
            fetchedAt: day,
            periodStart: monthStart,
            periodEnd: monthEnd,
            currentSpendUSD: Money(usd: Decimal(amount)),
            dailyUSD: [calendar.startOfDay(for: day): Money(usd: Decimal(amount))]
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
