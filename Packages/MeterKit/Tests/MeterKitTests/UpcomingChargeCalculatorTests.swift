import Foundation
import Testing
@testable import MeterCore

struct UpcomingChargeCalculatorTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("年付首次扣款日在未来 7 天内会出现")
    func annualSubscriptionWithinSevenDaysAppears() {
        let now = date(2026, 8, 16, 12)
        let charges = UpcomingChargeCalculator.charges(
            snapshots: [],
            subscriptions: [
                MonthlySubscription(
                    name: "SuperGrok（年付）",
                    amount: Money(usd: 300),
                    period: .annual,
                    anchorDate: date(2026, 8, 20),
                    providerID: .xai
                )
            ],
            now: now,
            calendar: calendar
        )

        #expect(charges.count == 1)
        #expect(charges[0].name == "SuperGrok（年付）")
        #expect(charges[0].amount == Money(usd: 300))
        #expect(calendar.component(.day, from: charges[0].chargeDate) == 20)
    }

    @Test("手动月付不记扣款日，不算即将")
    func monthlyManualSubscriptionIsNotUpcoming() {
        let now = date(2026, 8, 16, 12)
        let charges = UpcomingChargeCalculator.charges(
            snapshots: [],
            subscriptions: [
                MonthlySubscription(
                    name: "ChatGPT Plus",
                    amount: Money(usd: 20),
                    period: .monthly,
                    anchorDate: date(2026, 8, 20),
                    providerID: .openai
                )
            ],
            now: now,
            calendar: calendar
        )

        #expect(charges.isEmpty)
    }

    @Test("GitHub 扣款日 3 号在 8 月 16 日不算即将（下一次是 9 月 3 日）")
    func githubChargeDayThreeIsNotUpcomingOnAugust16() {
        let now = date(2026, 8, 16, 12)
        let charges = UpcomingChargeCalculator.charges(
            snapshots: [
                Snapshot(
                    providerID: .github,
                    accountID: AccountID.fixture(for: .github),
                    kind: .planAndUsage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    committedMonthlyUSD: Money(usd: 4),
                    chargeDayOfMonth: 3
                )
            ],
            subscriptions: [],
            now: now,
            calendar: calendar
        )

        #expect(charges.isEmpty)
    }

    @Test("扣款日 31 在 2 月钳到月末，2 月 25 日看仍在 7 天内")
    func februaryChargeDay31IsClampedAndUpcoming() throws {
        let now = date(2026, 2, 25, 12)
        let date = UpcomingChargeCalculator.nextMonthlyChargeDate(
            dayOfMonth: 31,
            now: now,
            calendar: calendar
        )

        #expect(date == self.date(2026, 2, 28, 12))
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
