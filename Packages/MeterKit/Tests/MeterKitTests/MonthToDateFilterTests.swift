import Foundation
import Testing
@testable import MeterCore

/// 取景框作用在折算上的行为。
///
/// 这一组的重点不是「筛掉了吗」，而是**筛掉之后剩下的数字仍然自洽**：
/// 外推、上月同期、精度、facts 四样必须一起跟着变，任何一样没跟上，
/// 屏幕上就会出现一个内部矛盾的数。
struct MonthToDateFilterTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    /// 8 月 16 日：已过 16 天，当月 31 天，外推系数 31/16。
    private var now: Date { date(2026, 8, 16, 12) }

    // MARK: - 排除服务

    @Test("排掉一家，总数只剩另一家，构成 facts 里也没有它")
    func excludingProviderRemovesItFromTotalAndFacts() {
        let snapshots = [
            dailySnapshot(.cloudflare, perDay: 1),
            dailySnapshot(.aws, perDay: 2),
        ]
        let all = compute(snapshots: snapshots)
        #expect(all.totalUSD == Money(usd: 48))

        let withoutAWS = compute(
            snapshots: snapshots,
            filter: DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws)])
        )
        #expect(withoutAWS.totalUSD == Money(usd: 16))
        #expect(!withoutAWS.facts.contains { $0.providerID == .aws })
        #expect(withoutAWS.facts.contains { $0.providerID == .cloudflare })
    }

    @Test("排掉的那家会不会外推?——外推只对留下的部分做")
    func projectionFollowsTheScopedTotal() {
        let snapshots = [
            dailySnapshot(.cloudflare, perDay: 1),
            dailySnapshot(.aws, perDay: 2),
        ]
        let scoped = compute(
            snapshots: snapshots,
            filter: DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws)])
        )
        // 16 × 31/16 = 31
        #expect(scoped.projectedMonthEndUSD == Money(usd: 31))
    }

    @Test("排掉一家取数失败的，精度回到 exact——不看它，它坏了就不算缺口")
    func excludingAFailedProviderRestoresExactConfidence() {
        let snapshots = [
            dailySnapshot(.cloudflare, perDay: 1),
            // 没有任何可用字段：接了但这次没读到。
            Snapshot(
                providerID: .aws,
                accountID: AccountID.fixture(for: .aws),
                kind: .usage,
                fetchedAt: now,
                periodStart: date(2026, 8, 1),
                periodEnd: date(2026, 8, 31)
            ),
        ]
        #expect(compute(snapshots: snapshots).confidence == .partial)

        let scoped = compute(
            snapshots: snapshots,
            filter: DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws)])
        )
        #expect(scoped.confidence == .exact)
        #expect(!scoped.facts.contains { $0.type == .fetchFailed })
    }

    @Test("筛选本身不会把总数变成估算——ta 是选择，不是缺陷")
    func filteringNeverDegradesConfidence() {
        let snapshots = [dailySnapshot(.cloudflare, perDay: 1), dailySnapshot(.aws, perDay: 2)]
        let filters: [DashboardFilter] = [
            DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws)]),
            DashboardFilter(includesSubscriptions: false),
            DashboardFilter(monthsBack: 0, includesSubscriptions: false, excludedAccounts: [AccountID.fixture(for: .aws)]),
        ]
        for filter in filters {
            let result = compute(snapshots: snapshots, subscriptions: [plus()], filter: filter)
            #expect(result.confidence == .exact, "\(filter) 让精度降级了")
            #expect(result.estimatedAccounts.isEmpty, "\(filter) 把账号标成了估算")
        }
    }

    @Test("排除名单原样带回结果里，展示层拿得到限定语")
    func resultCarriesTheFilter() {
        let filter = DashboardFilter(monthsBack: 1, includesSubscriptions: false, excludedAccounts: [AccountID.fixture(for: .aws)])
        let result = compute(snapshots: [dailySnapshot(.cloudflare, perDay: 1)], filter: filter)
        #expect(result.filter == filter)
        // 默认路径仍然是 unfiltered，Widget 那条调用不受影响。
        #expect(compute(snapshots: []).filter == .unfiltered)
    }

    // MARK: - 不含订阅

    @Test("关掉订阅，手动录的那笔既不进总数也不进 facts")
    func manualSubscriptionDisappearsEntirely() {
        let base = compute(snapshots: [dailySnapshot(.openai, perDay: 1)], subscriptions: [plus()])
        #expect(base.totalUSD == Money(usd: 36))
        #expect(base.variableUSD == Money(usd: 16))
        #expect(base.subscriptionUSD == Money(usd: 20))
        #expect(base.facts.contains { $0.type == FactKind.subscriptionIncluded })

        let scoped = compute(
            snapshots: [dailySnapshot(.openai, perDay: 1)],
            subscriptions: [plus()],
            filter: DashboardFilter(includesSubscriptions: false)
        )
        #expect(scoped.totalUSD == Money(usd: 16))
        #expect(scoped.variableUSD == Money(usd: 16))
        // 关掉之后合计不含它，但仪表那行还要能写出「未计入」。
        #expect(scoped.subscriptionUSD == Money(usd: 20))
        // 只是「不计入总数」不够：fact 留着的话构成条和分享卡还会画出那一块。
        #expect(!scoped.facts.contains { $0.type == FactKind.subscriptionIncluded })
    }

    @Test("API 报回来的档位也一起关掉——只关手动那半边会对 GitHub 这类说谎")
    func apiReportedPlanIsGatedToo() {
        let github = Snapshot(
            providerID: .github,
            accountID: AccountID.fixture(for: .github),
            kind: .planAndUsage,
            fetchedAt: now,
            periodStart: date(2026, 8, 1),
            periodEnd: date(2026, 8, 31),
            currentSpendUSD: Money(roundedUSD: 0.08),
            committedMonthlyUSD: Money(usd: 4),
            chargeDayOfMonth: 5,
            dailyUSD: [date(2026, 8, 1): Money(roundedUSD: 0.08)]
        )
        #expect(compute(snapshots: [github]).totalUSD == Money(roundedUSD: 4.08))

        let scoped = compute(
            snapshots: [github],
            filter: DashboardFilter(includesSubscriptions: false)
        )
        #expect(scoped.totalUSD == Money(roundedUSD: 0.08))
        #expect(scoped.variableUSD == Money(roundedUSD: 0.08))
        #expect(scoped.subscriptionUSD == Money(usd: 4))
        #expect(scoped.facts.contains { $0.type == FactKind.monthToDateUsage })
        #expect(!scoped.facts.contains { $0.type == FactKind.subscriptionIncluded })
    }

    @Test("planAndUsage 只掉档位那半边，用量还在")
    func planAndUsageKeepsItsUsageHalf() {
        var daily: [Date: Money] = [:]
        for day in 1...16 {
            daily[date(2026, 8, day)] = Money(usd: 1)
        }
        let posthog = Snapshot(
            providerID: .posthog,
            accountID: AccountID.fixture(for: .posthog),
            kind: .planAndUsage,
            fetchedAt: now,
            periodStart: date(2026, 8, 1),
            periodEnd: date(2026, 8, 31),
            committedMonthlyUSD: Money(usd: 29),
            chargeDayOfMonth: 3,
            dailyUSD: daily
        )
        #expect(compute(snapshots: [posthog]).totalUSD == Money(usd: 45))

        let scoped = compute(
            snapshots: [posthog],
            filter: DashboardFilter(includesSubscriptions: false)
        )
        #expect(scoped.totalUSD == Money(usd: 16))
        #expect(scoped.variableUSD == Money(usd: 16))
        #expect(scoped.subscriptionUSD == Money(usd: 29))
        #expect(scoped.facts.contains { $0.type == FactKind.monthToDateUsage })
        #expect(!scoped.facts.contains { $0.type == FactKind.subscriptionIncluded })
    }

    @Test("关掉订阅后外推的是全部剩余部分——订阅本来不外推，去掉它系数不变")
    func projectionAfterDroppingSubscriptions() {
        let scoped = compute(
            snapshots: [dailySnapshot(.openai, perDay: 1)],
            subscriptions: [plus()],
            filter: DashboardFilter(includesSubscriptions: false)
        )
        // 16 × 31/16 = 31，不再有那笔不外推的 $20。
        #expect(scoped.projectedMonthEndUSD == Money(usd: 31))
    }

    @Test("上月同期跟着一起去掉订阅，不然涨跌幅是拿不同口径在比")
    func comparisonDropsSubscriptionsToo() {
        var daily: [Date: Money] = [:]
        for day in 1...16 {
            daily[date(2026, 8, day)] = Money(usd: 1)
            daily[date(2026, 7, day)] = Money(usd: 1)
        }
        let snapshot = Snapshot(
            providerID: .openai,
            accountID: AccountID.fixture(for: .openai),
            kind: .usage,
            fetchedAt: now,
            periodStart: date(2026, 7, 1),
            periodEnd: date(2026, 8, 31),
            dailyUSD: daily
        )
        let scoped = compute(
            snapshots: [snapshot],
            subscriptions: [plus()],
            filter: DashboardFilter(includesSubscriptions: false)
        )
        // 本月 16、上月同期 16 → 持平。带上订阅两边各 +20 也持平，
        // 所以这条要看的是 comparisonUSD 本身没把 $20 算进去。
        #expect(scoped.comparisonUSD == Money(usd: 16))
        #expect(scoped.changeRatio == 0)
    }

    // MARK: - 往前翻月份

    @Test("往前翻一个月，算的是那整个月")
    func pastMonthSumsTheWholeMonth() {
        var daily: [Date: Money] = [:]
        for day in 1...31 {
            daily[date(2026, 7, day)] = Money(usd: 1)
        }
        for day in 1...16 {
            daily[date(2026, 8, day)] = Money(usd: 5)
        }
        let snapshot = Snapshot(
            providerID: .cloudflare,
            accountID: AccountID.fixture(for: .cloudflare),
            kind: .usage,
            fetchedAt: now,
            periodStart: date(2026, 7, 1),
            periodEnd: date(2026, 8, 31),
            dailyUSD: daily
        )
        #expect(compute(snapshots: [snapshot]).totalUSD == Money(usd: 80))

        let july = compute(snapshots: [snapshot], filter: DashboardFilter(monthsBack: 1))
        #expect(july.totalUSD == Money(usd: 31))
    }

    @Test("已经结束的月份，「预计月底」等于总数——没有可推的东西了")
    func completedMonthProjectsToItself() {
        var daily: [Date: Money] = [:]
        for day in 1...31 {
            daily[date(2026, 7, day)] = Money(usd: 2)
        }
        let snapshot = Snapshot(
            providerID: .cloudflare,
            accountID: AccountID.fixture(for: .cloudflare),
            kind: .usage,
            fetchedAt: now,
            periodStart: date(2026, 7, 1),
            periodEnd: date(2026, 7, 31),
            dailyUSD: daily
        )
        let july = compute(snapshots: [snapshot], filter: DashboardFilter(monthsBack: 1))
        #expect(july.totalUSD == Money(usd: 62))
        #expect(july.projectedMonthEndUSD == july.totalUSD)
    }

    @Test("往前翻时，上月同期变成再往前一个月")
    func comparisonWindowShiftsWithThePeriod() {
        let july = compute(
            snapshots: [dailySnapshot(.cloudflare, perDay: 1)],
            filter: DashboardFilter(monthsBack: 1)
        )
        let window = try? #require(july.comparisonWindow)
        #expect(calendar.component(.month, from: window!.start) == 6)
    }

    @Test("往前翻的月份里，只按扣款日落在那个月计订阅——不是按今天")
    func subscriptionAttributionFollowsTheChosenMonth() {
        // 7 月 20 日才第一次扣款的月付：8 月看它计入，6 月不该计入。
        let subscription = MonthlySubscription(
            name: "Plus",
            amount: Money(usd: 20),
            period: .monthly,
            anchorDate: date(2026, 7, 20),
            providerID: .openai
        )
        #expect(compute(subscriptions: [subscription]).totalUSD == Money(usd: 20))
        #expect(
            compute(subscriptions: [subscription], filter: DashboardFilter(monthsBack: 1))
                .totalUSD == Money(usd: 20)
        )
        // 6 月这笔还没开始。
        #expect(
            compute(subscriptions: [subscription], filter: DashboardFilter(monthsBack: 2))
                .totalUSD == .zero
        )
    }

    @Test("三个维度一起用互不干扰")
    func allThreeDimensionsCompose() {
        var daily: [Date: Money] = [:]
        for day in 1...31 {
            daily[date(2026, 7, day)] = Money(usd: 1)
        }
        let snapshots = [
            Snapshot(
                providerID: .cloudflare,
                accountID: AccountID.fixture(for: .cloudflare),
                kind: .usage,
                fetchedAt: now,
                periodStart: date(2026, 7, 1),
                periodEnd: date(2026, 8, 31),
                dailyUSD: daily
            ),
            dailySnapshot(.aws, perDay: 9),
        ]
        let result = compute(
            snapshots: snapshots,
            subscriptions: [plus()],
            filter: DashboardFilter(
                monthsBack: 1,
                includesSubscriptions: false,
                excludedAccounts: [AccountID.fixture(for: .aws)]
            )
        )
        #expect(result.totalUSD == Money(usd: 31))
        #expect(!result.facts.contains { $0.providerID == .aws })
        #expect(!result.facts.contains { $0.type == FactKind.subscriptionIncluded })
    }

    // MARK: - 辅助

    private func compute(
        snapshots: [Snapshot] = [],
        subscriptions: [MonthlySubscription] = [],
        filter: DashboardFilter = .unfiltered
    ) -> MonthToDate {
        MonthToDateCalculator.compute(
            snapshots: snapshots,
            subscriptions: subscriptions,
            now: now,
            calendar: calendar,
            filter: filter
        )
    }

    /// 8 月 1..16 日每天 `perDay`，共 16 × perDay。
    private func dailySnapshot(_ provider: ProviderID, perDay: Decimal) -> Snapshot {
        var daily: [Date: Money] = [:]
        for day in 1...16 {
            daily[date(2026, 8, day)] = Money(usd: perDay)
        }
        return Snapshot(
            providerID: provider,
            accountID: AccountID.fixture(for: provider),
            kind: .usage,
            fetchedAt: now,
            periodStart: date(2026, 8, 1),
            periodEnd: date(2026, 8, 31),
            dailyUSD: daily
        )
    }

    private func plus() -> MonthlySubscription {
        MonthlySubscription(
            name: "ChatGPT Plus",
            amount: Money(usd: 20),
            period: .monthly,
            anchorDate: date(2026, 1, 5),
            providerID: .openai
        )
    }

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
}
