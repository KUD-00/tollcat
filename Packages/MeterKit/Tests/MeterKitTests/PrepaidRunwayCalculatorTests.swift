import Foundation
import Testing
@testable import MeterCore

struct PrepaidRunwayCalculatorTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("近 7 日均速：余额 $42、7 日前 $58.33 → 还能用 18 天")
    func sevenDayAverageYieldsEighteenDays() throws {
        let now = date(2026, 8, 16, 12)
        let runways = PrepaidRunwayCalculator.compute(
            snapshots: [
                prepaid(.openai, fetchedAt: date(2026, 8, 1), balance: Money(roundedUSD: 49.62)),
                prepaid(.openai, fetchedAt: date(2026, 8, 9), balance: Money(roundedUSD: 58.33)),
                prepaid(.openai, fetchedAt: now, balance: Money(usd: 42)),
            ],
            now: now,
            calendar: calendar
        )

        let runway = try #require(runways.first { $0.providerID == .openai })
        #expect(runway.balanceUSD == Money(usd: 42))
        #expect(runway.daysRemaining == 18)
    }

    @Test("没有 7 天前的余额快照时整条为 nil")
    func missingWeekOldSnapshotReturnsNothing() {
        let now = date(2026, 8, 16, 12)
        let runways = PrepaidRunwayCalculator.compute(
            snapshots: [
                prepaid(.openai, fetchedAt: date(2026, 8, 12), balance: Money(usd: 50)),
                prepaid(.openai, fetchedAt: now, balance: Money(usd: 42)),
            ],
            now: now,
            calendar: calendar
        )

        #expect(runways.isEmpty)
    }

    @Test("近 7 日余额上升（充值）时不算燃烧速度")
    func topUpInWindowReturnsNothing() {
        let now = date(2026, 8, 16, 12)
        let runways = PrepaidRunwayCalculator.compute(
            snapshots: [
                prepaid(.openai, fetchedAt: date(2026, 8, 9), balance: Money(usd: 20)),
                prepaid(.openai, fetchedAt: now, balance: Money(usd: 42)),
            ],
            now: now,
            calendar: calendar
        )

        #expect(runways.isEmpty)
    }

    private func prepaid(_ id: ProviderID, fetchedAt: Date, balance: Money) -> Snapshot {
        Snapshot(
            providerID: id,
            accountID: AccountID.fixture(for: id),
            kind: .prepaid,
            fetchedAt: fetchedAt,
            periodStart: fetchedAt,
            periodEnd: fetchedAt,
            balanceUSD: balance
        )
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
