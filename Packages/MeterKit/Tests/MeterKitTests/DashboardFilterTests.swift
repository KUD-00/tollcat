import Foundation
import Testing
@testable import MeterCore

/// 取景框本身的行为。折算侧的行为在 `MonthToDateFilterTests`。
struct DashboardFilterTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    // MARK: - 默认与钳制

    @Test("默认就是「什么都不筛」，而且 isActive 为假")
    func defaultIsInert() {
        let filter = DashboardFilter()
        #expect(filter == .unfiltered)
        #expect(!filter.isActive)
        #expect(filter.isCurrentMonth)
        #expect(filter.includesSubscriptions)
        #expect(filter.excludedAccounts.isEmpty)
    }

    @Test("任意一维动过就算 active")
    func anyDimensionMakesItActive() {
        #expect(DashboardFilter(monthsBack: 1).isActive)
        // 订阅口径不算筛选：它是首屏一等公民切换，自己带说明。
        #expect(!DashboardFilter(includesSubscriptions: false).isActive)
        #expect(DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws)]).isActive)
    }

    @Test("monthsBack 钳到 0...11，负数和越界都不会算出别的月份")
    func monthsBackIsClamped() {
        #expect(DashboardFilter(monthsBack: -5).monthsBack == 0)
        #expect(DashboardFilter(monthsBack: 99).monthsBack == DashboardFilter.maxMonthsBack)
        #expect(DashboardFilter(monthsBack: 11).monthsBack == 11)
    }

    // MARK: - 时间锚点

    @Test("本月至今用真正的此刻，一秒都不动")
    func currentMonthKeepsNow() {
        let now = date(2026, 8, 17, 13, 45)
        #expect(DashboardFilter(monthsBack: 0).anchor(now: now, calendar: calendar) == now)
    }

    @Test("往前翻取那个月的最后一瞬——整月都算进来")
    func pastMonthAnchorsAtTheVeryEnd() {
        let now = date(2026, 8, 17, 13, 45)
        let anchor = DashboardFilter(monthsBack: 1).anchor(now: now, calendar: calendar)
        #expect(calendar.component(.year, from: anchor) == 2026)
        #expect(calendar.component(.month, from: anchor) == 7)
        #expect(calendar.component(.day, from: anchor) == 31)
        #expect(calendar.component(.hour, from: anchor) == 23)
        #expect(calendar.component(.minute, from: anchor) == 59)
        #expect(calendar.component(.second, from: anchor) == 59)
    }

    @Test("锚点落在当月最后一天，于是外推系数正好是 1")
    func anchorDayEqualsDaysInMonth() {
        // 8 月 17 日往前翻 1..6 个月，每次锚点的日都应等于那个月的天数。
        let now = date(2026, 8, 17, 13, 45)
        for back in 1...6 {
            let anchor = DashboardFilter(monthsBack: back).anchor(now: now, calendar: calendar)
            let daysInMonth = calendar.range(of: .day, in: .month, for: anchor)!.count
            #expect(
                calendar.component(.day, from: anchor) == daysInMonth,
                "往前 \(back) 个月锚点不在月末"
            )
        }
    }

    @Test("跨年往前翻不会算错年份")
    func anchorCrossesTheYearBoundary() {
        let now = date(2026, 2, 3, 9)
        let anchor = DashboardFilter(monthsBack: 3).anchor(now: now, calendar: calendar)
        #expect(calendar.component(.year, from: anchor) == 2025)
        #expect(calendar.component(.month, from: anchor) == 11)
        #expect(calendar.component(.day, from: anchor) == 30)
    }

    @Test("从 31 号往前翻到只有 30 天的月份，锚点是 30 号不是溢出到下个月")
    func anchorDoesNotOverflowShortMonths() {
        // 用 `now - 1 month` 会把 8/31 变成 9/31 → 10/1。锚点必须先取月首再退。
        let now = date(2026, 8, 31, 20)
        let anchor = DashboardFilter(monthsBack: 1).anchor(now: now, calendar: calendar)
        #expect(calendar.component(.month, from: anchor) == 7)
        #expect(calendar.component(.day, from: anchor) == 31)

        let june = DashboardFilter(monthsBack: 2).anchor(now: now, calendar: calendar)
        #expect(calendar.component(.month, from: june) == 6)
        #expect(calendar.component(.day, from: june) == 30)
    }

    @Test("闰年 2 月锚点是 29 号")
    func anchorHandlesLeapFebruary() {
        let now = date(2024, 4, 10)
        let anchor = DashboardFilter(monthsBack: 2).anchor(now: now, calendar: calendar)
        #expect(calendar.component(.month, from: anchor) == 2)
        #expect(calendar.component(.day, from: anchor) == 29)
    }

    // MARK: - 排除服务

    @Test("排除按 providerID 生效，其余原样保留")
    func scopeDropsExcludedSnapshots() {
        let snapshots = [
            snapshot(.aws),
            snapshot(.cloudflare),
            snapshot(.openai),
        ]
        let scoped = DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws), AccountID.fixture(for: .openai)]).scope(snapshots)
        #expect(scoped.map(\.providerID) == [.cloudflare])
    }

    @Test("没排任何东西时原数组返回，不做无谓拷贝也不改顺序")
    func scopeIsIdentityWhenEmpty() {
        let snapshots = [snapshot(.openai), snapshot(.aws)]
        #expect(DashboardFilter().scope(snapshots).map(\.providerID) == [.openai, .aws])
    }

    @Test("无主的手动订阅排不掉——排除是按服务排的，它没有可排的对象")
    func ownerlessSubscriptionSurvivesExclusion() {
        let subscriptions = [
            subscription(nil, amount: 5),
            subscription(.aws, amount: 10),
            subscription(.github, amount: 4),
        ]
        let scoped = DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws)]).scope(subscriptions)
        #expect(scoped.map(\.providerID) == [nil, .github])
    }

    // MARK: - 编辑

    @Test("排除 / 恢复是幂等的")
    func excludingAndIncludingAreIdempotent() {
        var filter = DashboardFilter()
        filter = filter.excluding(AccountID.fixture(for: .aws)).excluding(AccountID.fixture(for: .aws))
        #expect(filter.excludedAccounts == [AccountID.fixture(for: .aws)])
        #expect(!filter.includes(AccountID.fixture(for: .aws)))
        filter = filter.including(AccountID.fixture(for: .aws)).including(AccountID.fixture(for: .aws))
        #expect(filter == .unfiltered)
        #expect(filter.includes(AccountID.fixture(for: .aws)))
    }

    @Test("已经删掉的服务从排除名单里清掉——否则重新接入会莫名不算进总数")
    func pruningDropsDisconnectedProviders() {
        let filter = DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws), AccountID.fixture(for: .openai), AccountID.fixture(for: .neon)])
        let pruned = filter.pruned(to: [AccountID.fixture(for: .aws), AccountID.fixture(for: .cloudflare)])
        #expect(pruned.excludedAccounts == [AccountID.fixture(for: .aws)])
        // 其余维度不受影响。
        #expect(pruned.monthsBack == filter.monthsBack)
        #expect(pruned.includesSubscriptions == filter.includesSubscriptions)
    }

    @Test("回看过去某个月时，「预计月底」和「此刻」类模块都关掉")
    func pastMonthsSuppressPresentTense() {
        let current = DashboardFilter(monthsBack: 0)
        #expect(current.allowsProjection)
        #expect(current.showsPresentTenseModules)

        let past = DashboardFilter(monthsBack: 1)
        #expect(!past.allowsProjection)
        #expect(!past.showsPresentTenseModules)
    }

    // MARK: - 辅助

    private func date(
        _ year: Int, _ month: Int, _ day: Int,
        _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0
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

    private func snapshot(_ provider: ProviderID) -> Snapshot {
        Snapshot(
            providerID: provider,
            accountID: AccountID.fixture(for: provider),
            kind: .usage,
            fetchedAt: date(2026, 8, 17),
            periodStart: date(2026, 8, 1),
            periodEnd: date(2026, 8, 31),
            currentSpendUSD: Money(usd: 1)
        )
    }

    private func subscription(_ provider: ProviderID?, amount: Decimal) -> MonthlySubscription {
        MonthlySubscription(
            name: "x",
            amount: Money(usd: amount),
            period: .monthly,
            anchorDate: date(2026, 1, 5),
            accountID: provider.map { AccountID.fixture(for: $0) },
            providerID: provider
        )
    }
}

/// 时间那一维本身：解析、钳制、落盘往返。
///
/// 这一组守的是「多月区间只是若干个单月的和」这条设计线——一旦哪天有人
/// 为了「一段时间」另写一套折算，下面「三个月的订阅是三笔」那条会先响。
struct DashboardPeriodTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return calendar.date(from: components)!
    }

    private var now: Date { date(2026, 8, 17) }

    // MARK: - 解析

    @Test("本月只有一种写法：.months(back: 0, count: 1)")
    func currentMonthHasOneSpelling() {
        #expect(DashboardPeriod.currentMonth == .months(back: 0, count: 1))
        #expect(DashboardPeriod.months(back: 0, count: 1).isCurrentMonth)
        #expect(!DashboardPeriod.months(back: 0, count: 3).isCurrentMonth)
        #expect(!DashboardFilter().isActive)
        #expect(DashboardFilter(period: .months(back: 0, count: 3)).isActive)
    }

    @Test("count 钳到「从 back 到最老一个月」剩下的空间里，不会越过 11 个月")
    func countIsClampedToRemainingRoom() {
        let period = DashboardPeriod.months(back: 10, count: 5).normalized
        #expect(period == .months(back: 10, count: 2))
        #expect(DashboardPeriod.months(back: 0, count: 0).normalized == .currentMonth)
        #expect(DashboardPeriod.months(back: -3, count: 2).normalized == .months(back: 0, count: 2))
    }

    @Test("近 3 个月解析成 0...2 三个月")
    func recentMonthsResolves() {
        let window = DashboardPeriod.months(back: 0, count: 3).window(now: now, calendar: calendar)
        #expect(window.newestBack == 0)
        #expect(window.oldestBack == 2)
        #expect(window.monthCount == 3)
        #expect(window.monthsBackNewestFirst == [0, 1, 2])
    }

    @Test("今年至今按当前月份现算——存成算好的 count，元旦一过就变成去年")
    func yearToDateIsResolvedEachTime() {
        let august = DashboardPeriod.yearToDate.window(now: now, calendar: calendar)
        #expect(august.oldestBack == 7)
        let january = DashboardPeriod.yearToDate.window(now: date(2026, 1, 9), calendar: calendar)
        #expect(january.oldestBack == 0)
        // 一月份解析出来只有一个月，但它不是「本月」——用户选的是会自己长大的区间。
        #expect(!DashboardPeriod.yearToDate.isCurrentMonth)
    }

    @Test("全期间的下界由数据给；一条数据都没有时铺满能回看的全部月份")
    func allTimeUsesEarliestData() {
        let bounded = DashboardPeriod.allTime.window(
            now: now,
            calendar: calendar,
            earliestMonthsBack: 4
        )
        #expect(bounded.oldestBack == 4)
        let unbounded = DashboardPeriod.allTime.window(now: now, calendar: calendar)
        #expect(unbounded.oldestBack == DashboardFilter.maxMonthsBack)
    }

    @Test("锚点只认最新那个月，区间多长都不影响")
    func anchorIgnoresLength() {
        let single = DashboardFilter(period: .months(back: 1, count: 1))
        let ranged = DashboardFilter(period: .months(back: 1, count: 4))
        #expect(single.anchor(now: now, calendar: calendar) == ranged.anchor(now: now, calendar: calendar))
    }

    // MARK: - 时态

    @Test("现在时模块看窗口压不压着今天，不是看是不是单个当月")
    func presentTenseFollowsWindowEnd() {
        // 看「近 3 个月」时账户余额照样告急，藏起来是把「区间多长」和「说的是哪个时态」搞混。
        #expect(DashboardFilter(period: .months(back: 0, count: 3)).showsPresentTenseModules)
        #expect(DashboardFilter(period: .allTime).showsPresentTenseModules)
        #expect(!DashboardFilter(period: .months(back: 1, count: 1)).showsPresentTenseModules)
    }

    @Test("预计月底和月度预算只在单个当月成立")
    func projectionAndBudgetNeedASingleCurrentMonth() {
        #expect(DashboardFilter().allowsProjection)
        #expect(DashboardFilter().allowsMonthlyBudget)
        #expect(!DashboardFilter(period: .months(back: 0, count: 3)).allowsProjection)
        #expect(!DashboardFilter(period: .months(back: 0, count: 3)).allowsMonthlyBudget)
        #expect(!DashboardFilter(period: .yearToDate).allowsMonthlyBudget)
    }

    // MARK: - 落盘

    @Test("三个标量往返回来还是同一份意图")
    func storageRoundTrips() {
        let cases: [DashboardPeriod] = [
            .currentMonth,
            .months(back: 2, count: 3),
            .yearToDate,
            .allTime,
        ]
        for period in cases {
            let restored = DashboardPeriod.fromStorage(
                kind: period.storageKind,
                monthsBack: period.newestMonthsBack,
                monthCount: period.storageMonthCount
            )
            #expect(restored == period)
        }
    }

    @Test("旧库没有那两列时读出来就是单月——加这个特性之前的行为")
    func legacyStorageFallsBackToSingleMonth() {
        #expect(DashboardPeriod.fromStorage(kind: "months", monthsBack: 0, monthCount: 1) == .currentMonth)
        // 认不出来的 kind 也回落，不炸。
        #expect(DashboardPeriod.fromStorage(kind: "???", monthsBack: 3, monthCount: 1) == .months(back: 3, count: 1))
    }
}

/// 多月区间的折算。
///
/// **这一组的核心断言只有一句：多月 = 若干个单月的和。**
/// 一旦哪天有人为「一段时间」另写一套折算，这里会先响——而那正是最危险的一类
/// 改动，因为算出来的数看起来永远像是对的。
struct PeriodTotalCalculatorTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return calendar.date(from: components)!
    }

    private var now: Date { date(2026, 8, 17) }

    /// 一家按天报数的服务：指定的那几个月里，每月 1 号花掉 `amount`。
    private func dailySnapshot(_ provider: ProviderID, months: [Int], amount: Decimal) -> Snapshot {
        var daily: [Date: Money] = [:]
        for month in months {
            daily[date(2026, month, 1)] = Money(usd: amount)
        }
        return Snapshot(
            providerID: provider,
            accountID: AccountID.fixture(for: provider),
            kind: .usage,
            fetchedAt: now,
            periodStart: date(2026, 1, 1),
            periodEnd: date(2026, 8, 31),
            currentSpendUSD: Money(usd: 0),
            dailyUSD: daily
        )
    }

    private func monthlySubscription(_ amount: Decimal) -> MonthlySubscription {
        MonthlySubscription(
            name: "seat",
            amount: Money(usd: amount),
            period: .monthly,
            anchorDate: date(2026, 1, 5),
            accountID: AccountID.fixture(for: .openai),
            providerID: .openai
        )
    }

    private func compute(_ filter: DashboardFilter, subscriptions: [MonthlySubscription] = []) -> MonthToDate {
        PeriodTotalCalculator.compute(
            snapshots: [dailySnapshot(.aws, months: [6, 7, 8], amount: 10)],
            subscriptions: subscriptions,
            now: now,
            calendar: calendar,
            filter: filter
        )
    }

    @Test("单月区间原样转发：和直接调 MonthToDateCalculator 一个字节不差")
    func singleMonthIsUntouched() {
        let filter = DashboardFilter(monthsBack: 1)
        let folded = compute(filter, subscriptions: [monthlySubscription(5)])
        let direct = MonthToDateCalculator.compute(
            snapshots: [dailySnapshot(.aws, months: [6, 7, 8], amount: 10)],
            subscriptions: [monthlySubscription(5)],
            now: now,
            calendar: calendar,
            filter: filter
        )
        #expect(folded.totalUSD == direct.totalUSD)
        #expect(folded.variableUSD == direct.variableUSD)
        #expect(folded.subscriptionUSD == direct.subscriptionUSD)
        #expect(folded.facts.count == direct.facts.count)
        // 单月仍然给对比——多月才没有。
        #expect(folded.comparisonWindow != nil)
        #expect(folded.window.isSingleMonth)
    }

    @Test("三个月的从量是三个月各自的和")
    func variableSumsAcrossMonths() {
        let single = compute(DashboardFilter())
        let ranged = compute(DashboardFilter(period: .months(back: 0, count: 3)))
        #expect(single.variableUSD == Money(usd: 10))
        #expect(ranged.variableUSD == Money(usd: 30))
        #expect(ranged.window.monthCount == 3)
    }

    @Test("三个月的订阅是三笔——月费按月计，不是把一笔摊到三个月里")
    func subscriptionIsChargedPerMonth() {
        let subscriptions = [monthlySubscription(5)]
        let single = compute(DashboardFilter(), subscriptions: subscriptions)
        let ranged = compute(
            DashboardFilter(period: .months(back: 0, count: 3)),
            subscriptions: subscriptions
        )
        #expect(single.subscriptionUSD == Money(usd: 5))
        #expect(ranged.subscriptionUSD == Money(usd: 15))
        #expect(ranged.totalUSD == Money(usd: 45))
    }

    @Test("同一个账号的同一类钱合并成一条，不是三条")
    func factsMergePerAccountAndType() {
        let ranged = compute(
            DashboardFilter(period: .months(back: 0, count: 3)),
            subscriptions: [monthlySubscription(5)]
        )
        let usage = ranged.facts.filter { $0.type == .monthToDateUsage }
        #expect(usage.count == 1)
        #expect(usage.first?.amountUSD == Money(usd: 30))
        // 用量和订阅是两笔不同的钱，键里带 type 才不会并成一块，
        // 否则构成条上会少一段。
        let subscription = ranged.facts.filter { $0.type == .subscriptionIncluded }
        #expect(subscription.count == 1)
        #expect(subscription.first?.amountUSD == Money(usd: 15))
    }

    @Test("多月区间不给对比：逐月的「上月同期」加起来是一个重叠的窗口，是错的")
    func rangedPeriodHasNoComparison() {
        let ranged = compute(DashboardFilter(period: .months(back: 0, count: 3)))
        #expect(ranged.comparisonWindow == nil)
        #expect(ranged.comparisonUSD == nil)
        #expect(ranged.changeRatio == nil)
        #expect(ranged.facts.allSatisfy { $0.comparisonUSD == nil })
    }

    @Test("全期间的下界取最老那笔数据所在的月")
    func earliestMonthsBackFollowsData() {
        let earliest = PeriodTotalCalculator.earliestMonthsBack(
            snapshots: [dailySnapshot(.aws, months: [6, 7, 8], amount: 10)],
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        // 快照的 periodStart 是 1 月 1 日，也就是往前第 7 个月。
        #expect(earliest == 7)
        #expect(PeriodTotalCalculator.earliestMonthsBack(
            snapshots: [],
            subscriptions: [],
            now: now,
            calendar: calendar
        ) == nil)
    }

    @Test("排除名单在多月区间里照样生效，而且每个月都生效")
    func exclusionAppliesToEveryMonth() {
        let ranged = compute(
            DashboardFilter(
                period: .months(back: 0, count: 3),
                excludedAccounts: [AccountID.fixture(for: .aws)]
            )
        )
        #expect(ranged.variableUSD == .zero)
    }
}
