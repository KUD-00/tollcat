import Foundation
import Testing
import MeterCore
import MeterPersistence
@testable import MeterFeatures

struct ProviderHistoryChartBuilderTests {
    /// 图表现在收 `ReadingSeries`（门上那个明确开的口）。测试仍从裸快照出发，
    /// 包一层就好——这一层不改变数据，只是把「范围由门决定」这件事写在类型上。
    private func series(_ readings: [Snapshot]) -> ReadingSeries {
        ReadingSeries(
            accountIDs: Set(readings.compactMap(\.accountID)),
            interval: nil,
            readings: readings
        )
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("usage 用每日花费柱，缺天不补 0")
    func usageDoesNotFillMissingDaysWithZero() {
        let now = date(2026, 8, 16)
        let content = ProviderHistoryChartBuilder.make(
            kind: .usage,
            readings: series([
                Snapshot(
                    providerID: .aws,
                    accountID: AccountID.fixture(for: .aws),
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(roundedUSD: 4.7),
                    dailyUSD: [
                        date(2026, 8, 1): Money(roundedUSD: 0.5),
                        date(2026, 8, 3): Money(roundedUSD: 2.2),
                    ]
                ),
            ]),
            range: .days30,
            now: now,
            calendar: calendar
        )

        guard case .spend(let points, let start, let end, let granularity, _) = content else {
            Issue.record("expected spend chart")
            return
        }
        #expect(points.map(\.amount) == [0.5, 2.2])
        #expect(points.count == 2)
        #expect(!points.contains(where: { $0.amount == 0 }))
        #expect(granularity == .day)
        #expect(calendar.isDate(start, inSameDayAs: date(2026, 7, 18)))
        #expect(calendar.isDate(end, inSameDayAs: now))
    }

    @Test("窗里没有日线时回落到本月至今差量，不被窗外的月合计挡住")
    func dayChartFallsBackWhenDailyPointsLieOutsideWindow() {
        let now = date(2026, 8, 16)
        let content = ProviderHistoryChartBuilder.make(
            kind: .usage,
            readings: series([
                Snapshot(
                    providerID: .heroku,
                    accountID: AccountID.fixture(for: .heroku),
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(usd: 8),
                    dailyUSD: [
                        date(2026, 7, 1): Money(usd: 40),
                    ]
                ),
            ]),
            range: .days30,
            now: now,
            calendar: calendar
        )
        guard case .spend(let points, _, _, let granularity, let isInterval) = content else {
            Issue.record("expected spend chart")
            return
        }
        #expect(granularity == .day)
        #expect(isInterval)
        #expect(points.contains { calendar.isDate($0.date, inSameDayAs: now) && $0.amount == 8 })
        #expect(!points.contains { $0.amount == 40 })
    }

    @Test("12 个月按月聚合，缺月不补 0")
    func monthlyAggregationSkipsEmptyMonths() {
        let now = date(2026, 8, 16)
        let content = ProviderHistoryChartBuilder.make(
            kind: .usage,
            readings: series([
                Snapshot(
                    providerID: .aws,
                    accountID: AccountID.fixture(for: .aws),
                    kind: .usage,
                    fetchedAt: date(2026, 7, 16),
                    periodStart: date(2026, 7, 1),
                    periodEnd: date(2026, 7, 31),
                    currentSpendUSD: Money(roundedUSD: 13.2)
                ),
                Snapshot(
                    providerID: .aws,
                    accountID: AccountID.fixture(for: .aws),
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(roundedUSD: 2.7),
                    dailyUSD: [
                        date(2026, 8, 1): Money(roundedUSD: 0.5),
                        date(2026, 8, 3): Money(roundedUSD: 2.2),
                    ]
                ),
            ]),
            range: .months12,
            now: now,
            calendar: calendar
        )

        guard case .spend(let points, _, _, let granularity, _) = content else {
            Issue.record("expected monthly spend chart")
            return
        }
        #expect(granularity == .month)
        #expect(points.map(\.amount) == [13.2, 2.7])
        #expect(!points.contains(where: { $0.amount == 0 }))
        #expect(calendar.isDate(points[0].date, equalTo: date(2026, 7, 1), toGranularity: .month))
        #expect(calendar.isDate(points[1].date, equalTo: date(2026, 8, 1), toGranularity: .month))
    }

    @Test("prepaid 用余额折线，缺口出虚线段")
    func prepaidBuildsBalanceLineWithInferredGaps() {
        let now = date(2026, 8, 16)
        let content = ProviderHistoryChartBuilder.make(
            kind: .prepaid,
            readings: series([
                Snapshot(
                    providerID: .openai,
                    accountID: AccountID.fixture(for: .openai),
                    kind: .prepaid,
                    fetchedAt: date(2026, 8, 1),
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    balanceUSD: Money(roundedUSD: 49.62)
                ),
                Snapshot(
                    providerID: .openai,
                    accountID: AccountID.fixture(for: .openai),
                    kind: .prepaid,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    balanceUSD: Money(usd: 42)
                ),
            ]),
            range: .days30,
            now: now,
            calendar: calendar
        )

        guard case .balance(let points, _, _, _, let inferred) = content else {
            Issue.record("expected balance chart")
            return
        }
        #expect(points.map(\.amount) == [49.62, 42])
        #expect(inferred.count == 1)
        #expect(inferred[0].isInferred)
        #expect(inferred[0].start.amount == 49.62)
        #expect(inferred[0].end.amount == 42)
    }

    @Test("用量没有日数组时仍是柱：两次本月至今的差")
    func usageWithoutDailyUsesIntervalBars() {
        let now = date(2026, 8, 20)
        let account = AccountID.fixture(for: .fly)
        let content = ProviderHistoryChartBuilder.make(
            kind: .usage,
            readings: series([
                Snapshot(
                    providerID: .fly,
                    accountID: account,
                    kind: .usage,
                    source: .manual,
                    fetchedAt: date(2026, 8, 5),
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(usd: 10)
                ),
                Snapshot(
                    providerID: .fly,
                    accountID: account,
                    kind: .usage,
                    source: .manual,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(usd: 22)
                ),
            ]),
            range: .days30,
            now: now,
            calendar: calendar
        )

        guard case .spend(let points, _, _, let granularity, let isIntervalSpend) = content else {
            Issue.record("expected spend bars")
            return
        }
        #expect(granularity == .day)
        #expect(isIntervalSpend)
        #expect(points.map(\.amount) == [10, 12])
        #expect(calendar.isDate(points[0].date, inSameDayAs: date(2026, 8, 5)))
        #expect(calendar.isDate(points[1].date, inSameDayAs: now))
        #expect(content.readingNote != nil)
    }

    @Test("同一天两次填写只留最新那次")
    func sameDayKeepsLatestObservation() {
        let morning = calendar.date(from: DateComponents(year: 2026, month: 8, day: 16, hour: 9))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 8, day: 16, hour: 16))!
        let account = AccountID.fixture(for: .fly)
        let content = ProviderHistoryChartBuilder.make(
            kind: .usage,
            readings: series([
                Snapshot(
                    providerID: .fly,
                    accountID: account,
                    kind: .usage,
                    source: .manual,
                    fetchedAt: morning,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(usd: 10)
                ),
                Snapshot(
                    providerID: .fly,
                    accountID: account,
                    kind: .usage,
                    source: .manual,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(usd: 22)
                ),
            ]),
            range: .days7,
            now: now,
            calendar: calendar
        )

        guard case .spend(let points, _, _, _, true) = content else {
            Issue.record("expected spend bars")
            return
        }
        #expect(points.map(\.amount) == [22])
    }

    @Test("12 个月柱多次刷新同一天不把日费用加总")
    func monthlyBarsDoNotMultiplyRepeatedDaily() {
        let now = date(2026, 8, 16)
        var july: [Date: Money] = [:]
        for day in 1...16 {
            july[date(2026, 7, day)] = Money(usd: 2)
        }
        let snapshots = (0..<8).map { offset in
            Snapshot(
                providerID: .aws,
                accountID: AccountID.fixture(for: .aws),
                kind: .usage,
                fetchedAt: date(2026, 7, 16).addingTimeInterval(TimeInterval(offset * 3600)),
                periodStart: date(2026, 7, 1),
                periodEnd: date(2026, 7, 31),
                dailyUSD: july
            )
        }
        let content = ProviderHistoryChartBuilder.make(
            kind: .usage,
            readings: series(snapshots),
            range: .months12,
            now: now,
            calendar: calendar
        )
        guard case .spend(let points, _, _, .month, _) = content else {
            Issue.record("expected monthly spend chart")
            return
        }
        let julyBar = points.first { calendar.isDate($0.date, equalTo: date(2026, 7, 1), toGranularity: .month) }
        #expect(julyBar?.amount == 32)
    }

    @Test("跨月各自从 0 起，不拿上月累计来减")
    func intervalSpendResetsAcrossMonths() {
        let now = date(2026, 9, 5)
        let account = AccountID.fixture(for: .fly)
        let content = ProviderHistoryChartBuilder.make(
            kind: .usage,
            readings: series([
                Snapshot(
                    providerID: .fly,
                    accountID: account,
                    kind: .usage,
                    source: .inbox,
                    fetchedAt: date(2026, 8, 20),
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(usd: 40)
                ),
                Snapshot(
                    providerID: .fly,
                    accountID: account,
                    kind: .usage,
                    source: .inbox,
                    fetchedAt: now,
                    periodStart: date(2026, 9, 1),
                    periodEnd: date(2026, 9, 30),
                    currentSpendUSD: Money(usd: 8)
                ),
            ]),
            range: .days30,
            now: now,
            calendar: calendar
        )

        guard case .spend(let points, _, _, _, true) = content else {
            Issue.record("expected spend bars")
            return
        }
        #expect(points.map(\.amount) == [40, 8])
    }

    @Test("事后补填的过去月份不进 7 / 30 天柱")
    func backfilledMonthDoesNotCreateIntervalBar() {
        let now = date(2026, 8, 20)
        let account = AccountID.fixture(for: .fly)
        let content = ProviderHistoryChartBuilder.make(
            kind: .usage,
            readings: series([
                Snapshot(
                    providerID: .fly,
                    accountID: account,
                    kind: .usage,
                    source: .manual,
                    fetchedAt: now,
                    periodStart: date(2026, 7, 1),
                    periodEnd: date(2026, 7, 31),
                    currentSpendUSD: Money(usd: 40)
                ),
                Snapshot(
                    providerID: .fly,
                    accountID: account,
                    kind: .usage,
                    source: .manual,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(usd: 8)
                ),
            ]),
            range: .days30,
            now: now,
            calendar: calendar
        )
        guard case .spend(let points, _, _, .day, true) = content else {
            Issue.record("expected interval spend bars")
            return
        }
        #expect(points.map(\.amount) == [8])
        #expect(calendar.isDate(points[0].date, inSameDayAs: now))
    }

    @Test("subscription 和 freeTier 不画图")
    func subscriptionAndFreeTierStayList() {
        let now = date(2026, 8, 16)
        let subscription = ProviderHistoryChartBuilder.make(
            kind: .subscription,
            readings: series([]),
            range: .days30,
            now: now,
            calendar: calendar
        )
        let freeTier = ProviderHistoryChartBuilder.make(
            kind: .freeTier,
            readings: series([]),
            range: .days30,
            now: now,
            calendar: calendar
        )
        #expect(subscription == .none)
        #expect(freeTier == .none)
        #expect(!subscription.hasPlot)
        #expect(!freeTier.hasPlot)
    }

    @Test("可平移日线从 12 个月回看铺点")
    func scrollableDayChartSpansLookback() {
        let now = date(2026, 8, 16)
        let content = ProviderHistoryChartBuilder.make(
            kind: .usage,
            readings: series([
                Snapshot(
                    providerID: .aws,
                    accountID: AccountID.fixture(for: .aws),
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(roundedUSD: 3.6),
                    dailyUSD: [
                        date(2026, 8, 1): Money(roundedUSD: 1.4),
                        date(2026, 8, 16): Money(roundedUSD: 2.2),
                    ]
                ),
            ]),
            range: .days7,
            now: now,
            calendar: calendar,
            spanLookback: true
        )
        guard case .spend(let points, let start, let end, .day, _) = content else {
            Issue.record("expected scrollable spend chart")
            return
        }
        let lookback = ProviderHistoryChartBuilder.window(
            range: .months12,
            now: now,
            calendar: calendar
        )
        #expect(calendar.isDate(start, inSameDayAs: lookback.start))
        #expect(calendar.isDate(end, inSameDayAs: now))
        #expect(points.map(\.amount) == [1.4, 2.2])
    }

    @Test("空 spend 没有可画的点")
    func emptySpendHasNoPlot() {
        let now = date(2026, 8, 16)
        let content = ProviderHistoryChartBuilder.make(
            kind: .usage,
            readings: series([]),
            range: .days30,
            now: now,
            calendar: calendar
        )
        #expect(content.showsChart)
        #expect(!content.hasPlot)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
