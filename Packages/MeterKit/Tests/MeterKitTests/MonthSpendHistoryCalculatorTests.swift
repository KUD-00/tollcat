import Foundation
import Testing
@testable import MeterCore

struct MonthSpendHistoryCalculatorTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("按时间从旧到新，当前月在最后")
    func chronologicalEndingAtCurrentMonth() {
        let now = date(2026, 8, 16, 12)
        var daily: [Date: Money] = [:]
        for day in 1...31 {
            daily[date(2026, 7, day)] = Money(usd: 2)
        }
        for day in 1...16 {
            daily[date(2026, 8, day)] = Money(usd: 1)
        }

        let points = MonthSpendHistoryCalculator.compute(
            snapshots: [
                Snapshot(
                    providerID: .cloudflare,
                    accountID: AccountID.fixture(for: .cloudflare),
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 7, 1),
                    periodEnd: date(2026, 8, 31),
                    dailyUSD: daily
                )
            ],
            subscriptions: [],
            now: now,
            calendar: calendar,
            monthCount: 3
        )

        #expect(points.count == 3)
        #expect(calendar.component(.month, from: points[0].monthStart) == 6)
        #expect(points[0].variableUSD == .zero)
        #expect(calendar.component(.month, from: points[1].monthStart) == 7)
        #expect(points[1].variableUSD == Money(usd: 62))
        #expect(calendar.component(.month, from: points[2].monthStart) == 8)
        #expect(points[2].variableUSD == Money(usd: 16))
    }

    @Test("回看某个月时窗口停在那个月，不把本月算进来")
    func pastMonthWindowStopsAtSelection() {
        let now = date(2026, 8, 16, 12)
        var daily: [Date: Money] = [:]
        for day in 1...31 {
            daily[date(2026, 7, day)] = Money(usd: 1)
        }
        for day in 1...16 {
            daily[date(2026, 8, day)] = Money(usd: 9)
        }

        let points = MonthSpendHistoryCalculator.compute(
            snapshots: [
                Snapshot(
                    providerID: .cloudflare,
                    accountID: AccountID.fixture(for: .cloudflare),
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 7, 1),
                    periodEnd: date(2026, 8, 31),
                    dailyUSD: daily
                )
            ],
            subscriptions: [],
            now: now,
            calendar: calendar,
            filter: DashboardFilter(monthsBack: 1),
            monthCount: 2
        )

        #expect(points.count == 2)
        #expect(calendar.component(.month, from: points.last?.monthStart ?? now) == 7)
        #expect(points.last?.variableUSD == Money(usd: 31))
        #expect(points.contains { calendar.component(.month, from: $0.monthStart) == 8 } == false)
    }

    @Test("累计式快照回看上月：用账期重叠的那条，不被本月快照顶掉")
    func cumulativeLookBackUsesOverlappingSnapshot() {
        // Android 场景：没有日粒度，每月一条「本周期至今」累计。上月那条的账期
        // 停在同期日；本月那条更新。回看上月时必须选中上月那条，而不是拿本月
        // 账期去摊出 $0。
        let now = date(2026, 8, 26, 13)
        let july = Snapshot(
            providerID: .aws,
            accountID: AccountID.fixture(for: .aws),
            kind: .usage,
            fetchedAt: date(2026, 7, 26),
            periodStart: date(2026, 7, 1),
            periodEnd: date(2026, 7, 26),
            currentSpendUSD: Money(roundedUSD: 13.2)
        )
        let august = Snapshot(
            providerID: .aws,
            accountID: AccountID.fixture(for: .aws),
            kind: .usage,
            fetchedAt: now,
            periodStart: date(2026, 8, 1),
            periodEnd: date(2026, 8, 31),
            currentSpendUSD: Money(roundedUSD: 21.4)
        )

        let points = MonthSpendHistoryCalculator.compute(
            snapshots: [july, august],
            subscriptions: [],
            now: now,
            calendar: calendar,
            monthCount: 2
        )

        #expect(points.count == 2)
        #expect(calendar.component(.month, from: points[0].monthStart) == 7)
        #expect(points[0].variableUSD == Money(roundedUSD: 13.2))
        #expect(calendar.component(.month, from: points[1].monthStart) == 8)
        #expect(points[1].variableUSD == Money(roundedUSD: 21.4))
    }

    @Test("订阅金额不进从量趋势")
    func subscriptionsDoNotEnterVariableHistory() {
        let now = date(2026, 8, 16, 12)
        let points = MonthSpendHistoryCalculator.compute(
            snapshots: [],
            subscriptions: [
                MonthlySubscription(
                    name: "Copilot",
                    amount: Money(usd: 10),
                    period: .monthly,
                    anchorDate: date(2026, 1, 3)
                )
            ],
            now: now,
            calendar: calendar,
            monthCount: 2
        )

        #expect(points.allSatisfy { $0.variableUSD == .zero })
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
