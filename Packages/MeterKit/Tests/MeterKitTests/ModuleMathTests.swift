import Foundation
import Testing
@testable import MeterCore

/// 下沉到 Core 的那几条模块规则。**它们下来的理由就是曾经有两份且已经漂了**，
/// 所以钉住的是那几处具体的分歧，不是「跑一遍是什么就是什么」。
struct ModuleMathTests {
    // MARK: - 按类别构成

    private func member(_ id: String, _ amount: Double, name: String? = nil) -> CategoryShareMember {
        CategoryShareMember(
            providerID: ProviderID(rawValue: id),
            displayName: name ?? id,
            colorKey: id,
            amount: Money(roundedUSD: amount)
        )
    }

    /// 桥那一版按各自 `round()` 算，能凑出 99 或 101。整数百分比必须加起来是 100。
    @Test func categoryPercentsSumTo100() {
        let shares = CategoryShares.make(from: [
            member("openai", 1),
            member("anthropic", 1),
            member("cloudflare", 1),
        ])
        #expect(shares.map(\.percent).reduce(0, +) == 100)
    }

    @Test func categorySharesSortByAmount() {
        let shares = CategoryShares.make(from: [
            member("cloudflare", 1),
            member("openai", 90),
        ])
        #expect(shares.first?.amount == Money(roundedUSD: 90))
    }

    /// 合计为 0 时不出这块，而不是画一圈 0%。
    @Test func categorySharesEmptyWhenNothingSpent() {
        #expect(CategoryShares.make(from: [member("openai", 0)]).isEmpty)
    }

    // MARK: - 本月之最

    /// 顺序也是单源的：涨得最多 → 占比最大 → 最久没刷。
    @Test func superlativeOrderIsFixed() {
        #expect(SuperlativeSelection.order == [.biggestRise, .biggestShare, .stalest])
    }

    /// 只看正增长。全在跌的时候这一块不出现，而不是挑一个「跌得最少的」当涨得最多。
    @Test func biggestRiseIgnoresDrops() {
        #expect(SuperlativeSelection.biggestRise(changeRatios: [-0.5, -0.1, nil]) == nil)
        #expect(SuperlativeSelection.biggestRise(changeRatios: [0.1, 0.9, -0.2]) == 1)
    }

    /// 并列取靠前的：同一份数据每次挑出来的必须是同一个。
    @Test func biggestRiseBreaksTiesByOrder() {
        #expect(SuperlativeSelection.biggestRise(changeRatios: [0.5, 0.5]) == 0)
    }

    @Test func biggestShareSkipsZero() {
        #expect(SuperlativeSelection.biggestShare(fractions: [0, 0]) == nil)
        #expect(SuperlativeSelection.biggestShare(fractions: [0.2, 0.7, 0.1]) == 1)
    }

    /// 只有一份接入时不给：唯一的那份自然是最久的，说出来没有信息量。
    @Test func stalestNeedsAtLeastTwo() {
        #expect(SuperlativeSelection.stalest(lastRefreshedAt: [Date()]) == nil)
    }

    /// 还没刷过的（nil）排最前。
    @Test func stalestPrefersNeverRefreshed() {
        let now = Date(timeIntervalSince1970: 1_760_000_000)
        #expect(SuperlativeSelection.stalest(lastRefreshedAt: [now, nil]) == 1)
        #expect(
            SuperlativeSelection.stalest(lastRefreshedAt: [now, now.addingTimeInterval(-86_400)]) == 1
        )
    }

    // MARK: - 预算线

    @Test func budgetGaugeNilWithoutBudget() {
        #expect(BudgetGauge.make(spent: Money(roundedUSD: 10), budgetUSD: nil) == nil)
        #expect(BudgetGauge.make(spent: Money(roundedUSD: 10), budgetUSD: 0) == nil)
    }

    @Test func budgetGaugeSplitsRemainingAndOverspend() throws {
        let under = try #require(BudgetGauge.make(spent: Money(roundedUSD: 40), budgetUSD: 100))
        #expect(under.remaining == Money(roundedUSD: 60))
        #expect(under.overspend == .zero)
        #expect(!under.isOver)
        #expect(!under.isClose)

        let over = try #require(BudgetGauge.make(spent: Money(roundedUSD: 120), budgetUSD: 100))
        #expect(over.overspend == Money(roundedUSD: 20))
        #expect(over.remaining == .zero)
        #expect(over.isOver)
    }

    /// 「快到了」的阈值只有一处，两端同一刻变色。
    @Test func budgetGaugeCloseThreshold() throws {
        let close = try #require(BudgetGauge.make(spent: Money(roundedUSD: 86), budgetUSD: 100))
        #expect(close.isClose)
        let notYet = try #require(BudgetGauge.make(spent: Money(roundedUSD: 85), budgetUSD: 100))
        #expect(!notYet.isClose)
    }

    // MARK: - 热力图格子

    @Test func heatmapLeavesFutureDaysNil() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Shanghai"))
        let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 10)))
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 12)))

        let months = HeatmapMonths.make(
            dailyTotals: [day: Money(roundedUSD: 3)],
            now: now,
            calendar: calendar
        )
        let month = try #require(months.first)
        #expect(month.values.count == 31)
        #expect(month.values[9] == Money(roundedUSD: 3))
        // 11 号没读数但已经过去 → 0；13 号还没到 → nil。
        #expect(month.values[10] == .zero)
        #expect(month.values[12] == nil)
        #expect(month.total == Money(roundedUSD: 3))
        #expect(month.peakDay == day)
    }

    // MARK: - 明细分组

    private func line(_ category: String, _ label: String, _ amount: Double, scope: String? = nil) -> SpendLine {
        SpendLine(
            category: category,
            label: label,
            scope: scope,
            amountUSD: Money(roundedUSD: amount)
        )
    }

    /// 超过 6 组折成「其他」，但行一条都不丢。
    @Test func spendGroupingCollapsesTail() {
        let lines = (1...9).map { line("c\($0)", "l\($0)", Double(10 - $0)) }
        let groups = SpendGrouping.make(lines: lines, mode: .category)
        #expect(groups.buckets.count == SpendGrouping.maxGroups)
        #expect(groups.buckets.last?.isOther == true)
        #expect(groups.buckets.last?.items.count == 4)
        #expect(groups.itemCount == 9)
    }

    /// 这份数据没有归属维度时，选了「按归属」也退回按类别，而不是给一屏空的。
    @Test func spendGroupingFallsBackWhenNoScope() {
        let groups = SpendGrouping.make(lines: [line("a", "x", 1)], mode: .scope)
        #expect(groups.mode == .category)
        #expect(!groups.supportsScope)
    }

    /// 不足 1% 写 `<1%`，不是 0%——0% 看起来像没用过。
    @Test func spendGroupingShareIsThreeState() {
        let groups = SpendGrouping.make(
            lines: [line("big", "b", 1000), line("tiny", "t", 1)],
            mode: .category
        )
        #expect(groups.buckets.first?.share == .percent(100))
        #expect(groups.buckets.last?.share == .belowOnePercent)
    }
}
