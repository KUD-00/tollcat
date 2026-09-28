import Foundation
import MeterDashboard
import Testing
import MeterCore
import MeterGlance
@testable import MeterFeatures
@testable import MeterModules

/// 仪表内容 → 手表和锁屏那一眼。数字和字直接来自模块内容，这里核的是
/// 模块内容里没有、要在这一步补的那几样。
@Suite("一眼：从仪表内容折出来")
struct GlanceBuilderTests {
    private let clock = MeterClock.design
    private let total = Money(roundedUSD: 47.20)
    private let projected = Money(roundedUSD: 61.57)

    private var monthToDate: MonthToDate {
        MonthToDate(
            totalUSD: total,
            projectedMonthEndUSD: projected,
            confidence: .exact,
            estimatedAccounts: [],
            facts: [],
            variableUSD: total,
            projectedVariableUSD: projected
        )
    }

    private func contents(budgetUSD: Decimal? = nil, segments: [CompositionSegment] = []) -> DashboardContents {
        let result = monthToDate
        let monthStart = clock.calendar.dateInterval(of: .month, for: clock.now)!.start
        var values: [Double?] = Array(repeating: nil, count: 31)
        for day in 0..<16 { values[day] = 2 }
        return DashboardContents(
            monthToDate: result,
            monthToDateContent: MonthToDateModuleContent.make(
                from: result,
                estimatedNames: [],
                staleCaption: nil,
                now: clock.now,
                calendar: clock.calendar
            ),
            compositionContent: segments.isEmpty ? nil : CompositionModuleContent(
                segments: segments,
                totalText: "$47.20",
                spokenTotal: ""
            ),
            heatmapContent: HeatmapModuleContent(months: [
                HeatmapMonth(
                    monthStart: monthStart,
                    title: "",
                    monthTitle: "",
                    values: values,
                    leadingEmptyDays: 0,
                    totalText: "",
                    spokenTotal: ""
                ),
            ]),
            budgetContent: BudgetBuilder.make(monthToDate: result, budgetUSD: budgetUSD, presentation: .usd)
        )
    }

    private func build(_ contents: DashboardContents, isEmpty: Bool = false, canSpeak: Bool = true, budgetUSD: Decimal? = nil) -> Glance {
        GlanceBuilder.make(
            contents: contents,
            isEmpty: isEmpty,
            canSpeak: canSpeak,
            budgetUSD: budgetUSD,
            lastRefreshAt: clock.now,
            presentation: .usd,
            now: clock.now,
            calendar: clock.calendar
        )
    }

    private func monthOf(_ glance: Glance) -> GlanceMonth? {
        if case let .month(month) = glance.content { month } else { nil }
    }

    @Test("金额和预计月底直接用首屏那两句")
    func headlineComesFromModuleContent() throws {
        let built = contents()
        let month = try #require(monthOf(build(built)))
        #expect(month.amountText == built.monthToDateContent?.amountText)
        #expect(month.projectionText == built.monthToDateContent?.projectedCaption)
        #expect(month.compactAmountText == "$47")
        #expect(month.budget == nil)
    }

    @Test("月份边界按注入的日历")
    func monthBounds() {
        let glance = build(contents())
        let interval = clock.calendar.dateInterval(of: .month, for: clock.now)!
        #expect(glance.monthStart == interval.start)
        #expect(glance.monthEnd == interval.end)
    }

    @Test("没账单、等本月、有数是三种内容")
    func contentStates() {
        #expect(build(DashboardContents(), isEmpty: true).content == .noBills)
        #expect(build(contents(), canSpeak: false).content == .waitingForMonth)
        #expect(build(DashboardContents()).content == .waitingForMonth)
    }

    /// 累计线按比例缩到正好落在大数字上：终点 = 合计 / max(合计, 外推)。
    @Test("走势线终点落在大数字上")
    func trendEndsAtTotal() throws {
        let trend = try #require(monthOf(build(contents()))?.trend)
        #expect(trend.cumulative.count == 16)
        #expect(trend.dayCount == 31)
        let expectedEnd = 47.20 / 61.57
        let end = try #require(trend.cumulative.last)
        #expect(abs(end - expectedEnd) < 0.0001)
        #expect(trend.projectedEnd == 1)
    }

    @Test("按当前速度月底会超预算就说出来")
    func projectedOverspend() throws {
        let budget = try #require(monthOf(build(contents(budgetUSD: 60), budgetUSD: 60))?.budget)
        #expect(budget.level == .normal)
        #expect(budget.projectedOverspendText == String(localized: MeterModules.L("预计超预算 \(Money(roundedUSD: 1.57).formatted())")))
    }

    @Test("已经超了就不再说会超")
    func alreadyOver() throws {
        let budget = try #require(monthOf(build(contents(budgetUSD: 40), budgetUSD: 40))?.budget)
        #expect(budget.level == .over)
        #expect(budget.projectedOverspendText == nil)
    }

    @Test("月底也超不了就不提")
    func comfortablyUnder() throws {
        let budget = try #require(monthOf(build(contents(budgetUSD: 100), budgetUSD: 100))?.budget)
        #expect(budget.projectedOverspendText == nil)
    }

    @Test("前五名各一行，其余并成其他")
    func servicesRankAndRemainder() throws {
        let amounts: [Double] = [3.13, 21.40, 4.00, 11.05, 7.62, 0.50, 0.25]
        let segments = amounts.enumerated().map { index, amount in
            CompositionSegment(
                displayName: "S\(index)",
                colorKey: "s\(index)",
                amount: Money(roundedUSD: amount),
                fraction: amount / 47.95,
                percent: 0
            )
        }
        let services = try #require(monthOf(build(contents(segments: segments)))).services
        #expect(services.map(\.name) == ["S1", "S3", "S4", "S2", "S0", String(localized: MeterModules.L("其他"))])
        #expect(services.map(\.rank) == [0, 1, 2, 3, 4, 5])
        #expect(services.last?.isRemainder == true)
        #expect(services.last?.amountText == "$0.75")
    }

    @Test("短金额")
    func compactAmounts() {
        #expect(GlanceAmountFormat.compact(47.2, code: "USD") == "$47")
        #expect(GlanceAmountFormat.compact(999.4, code: "USD") == "$999")
        #expect(GlanceAmountFormat.compact(1_234, code: "USD") == "$1.2K")
        #expect(GlanceAmountFormat.compact(9_990, code: "USD") == "$10K")
        #expect(GlanceAmountFormat.compact(12_600, code: "USD") == "$13K")
        #expect(GlanceAmountFormat.compact(7_000, code: "JPY") == "¥7K")
        #expect(GlanceAmountFormat.compact(2_500_000, code: "USD") == "$2.5M")
        #expect(GlanceAmountFormat.compact(-5, code: "USD") == "-$5")
    }
}
