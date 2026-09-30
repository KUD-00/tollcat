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

    private var monthToDate: MonthToDate { monthToDate() }

    private func monthToDate(facts: [Fact] = []) -> MonthToDate {
        MonthToDate(
            totalUSD: total,
            projectedMonthEndUSD: projected,
            confidence: .exact,
            estimatedAccounts: [],
            facts: facts,
            variableUSD: total,
            projectedVariableUSD: projected
        )
    }

    private func contents(
        budgetUSD: Decimal? = nil,
        segments: [CompositionSegment] = [],
        facts: [Fact] = [],
        comparison: ComparisonModuleContent? = nil
    ) -> DashboardContents {
        let result = monthToDate(facts: facts)
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
            comparisonContent: comparison,
            budgetContent: BudgetBuilder.make(monthToDate: result, budgetUSD: budgetUSD, presentation: .usd)
        )
    }

    private func build(
        _ contents: DashboardContents,
        isEmpty: Bool = false,
        canSpeak: Bool = true,
        budgetUSD: Decimal? = nil,
        details: GlanceBuilder.DetailSource? = nil
    ) -> Glance {
        GlanceBuilder.make(
            contents: contents,
            isEmpty: isEmpty,
            canSpeak: canSpeak,
            budgetUSD: budgetUSD,
            lastRefreshAt: clock.now,
            presentation: .usd,
            now: clock.now,
            calendar: clock.calendar,
            details: details
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

    // MARK: 手表 App 的详情页

    private let aws = AccountID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!)

    private var awsSegment: CompositionSegment {
        CompositionSegment(
            accountID: aws,
            providerID: ProviderID("aws"),
            displayName: "AWS",
            colorKey: "aws",
            amount: Money(roundedUSD: 21.40),
            fraction: 0.45,
            percent: 45,
            sublines: [SpendSubline(id: "ec2", title: "EC2", amountCaption: "$12.08", spokenLabel: "")]
        )
    }

    private func source(
        daily: [Date: Money] = [:],
        runways: [PrepaidRunway] = []
    ) -> GlanceBuilder.DetailSource {
        GlanceBuilder.DetailSource(dailySpend: { _ in daily }, runways: runways, connections: [])
    }

    private func day(_ back: Int) -> Date {
        clock.calendar.date(byAdding: .day, value: -back, to: clock.calendar.startOfDay(for: clock.now))!
    }

    @Test("锁屏那份不建详情")
    func noDetailWithoutSource() throws {
        let services = try #require(monthOf(build(contents(segments: [awsSegment])))).services
        #expect(services.allSatisfy { $0.detail == nil })
    }

    @Test("近 30 天到今天为止，缺的天记 0")
    func detailDaysEndToday() throws {
        let glance = build(
            contents(segments: [awsSegment]),
            details: source(daily: [day(0): Money(roundedUSD: 1.22), day(1): Money(roundedUSD: 0.70)])
        )
        let days = try #require(monthOf(glance)?.services.first?.detail).days
        #expect(days.count == GlanceBuilder.detailDays)
        #expect(days.last?.date == day(0))
        #expect(days.last?.amountText == "$1.22")
        #expect(days[days.count - 2].value == 0.70)
        #expect(days.first?.date == day(29))
        #expect(days.first?.value == 0)
    }

    /// 报不出按天的数、或者一个月都是 0：画一排空柱什么也没说。
    @Test("一整段都是 0 就不画柱")
    func allZeroDaysDropChart() throws {
        let glance = build(
            contents(segments: [awsSegment]),
            details: source(daily: [day(40): Money(roundedUSD: 3)])
        )
        let detail = try #require(monthOf(glance)?.services.first?.detail)
        #expect(detail.days.isEmpty)
    }

    @Test("同期、余额、明细直接用对比卡、余额告急、构成页那几样")
    func detailReusesModuleContent() throws {
        let comparison = ComparisonModuleContent(
            percentText: "+12%",
            caption: "",
            spokenLabel: "",
            current: 21.40,
            previous: 19.10,
            currentLabel: "",
            previousLabel: "",
            tone: .up,
            previousMonthName: "8月",
            items: [
                ComparisonItem(
                    accountID: aws,
                    providerID: ProviderID("aws"),
                    displayName: "AWS",
                    colorKey: "aws",
                    currentUSD: Money(roundedUSD: 21.40),
                    previousUSD: Money(roundedUSD: 19.10),
                    changeRatio: 0.12
                ),
            ]
        )
        let runway = PrepaidRunway(
            accountID: aws,
            providerID: ProviderID("aws"),
            balanceUSD: Money(roundedUSD: 32.10),
            averageDailyUSD: Money(roundedUSD: 6),
            daysRemaining: 5
        )
        let glance = build(
            contents(segments: [awsSegment], comparison: comparison),
            details: source(runways: [runway])
        )
        let detail = try #require(monthOf(glance)?.services.first?.detail)
        let item = try #require(comparison.items.first)
        #expect(detail.change?.direction == .up)
        #expect(detail.change?.text == String(localized: MeterModules.L("较上月同期 \(item.trailingText)")))
        #expect(detail.change?.detailText == item.subtitle(previousMonthName: "8月"))
        #expect(detail.balance?.balanceText == String(localized: MeterModules.L("余额 \(Money(roundedUSD: 32.10).formatted())")))
        #expect(detail.balance?.isLow == true)
        #expect(detail.sublines.map(\.title) == ["EC2"])
        #expect(detail.shareText != nil)
    }

    /// 柱只有按量的钱。本月有订阅就得另外说，否则柱加起来对不上大数字。
    @Test("有订阅又有柱时另说一句")
    func subscriptionNote() throws {
        let fact = Fact(
            providerID: ProviderID("aws"),
            accountID: aws,
            amountUSD: Money(roundedUSD: 5),
            confidence: .exact,
            type: .subscriptionIncluded
        )
        let withBars = build(
            contents(segments: [awsSegment], facts: [fact]),
            details: source(daily: [day(0): Money(roundedUSD: 1)])
        )
        #expect(monthOf(withBars)?.services.first?.detail?.subscriptionNote
            == String(localized: MeterModules.L("订阅 \(Money(roundedUSD: 5).formatted()) 按月扣，不在柱上")))

        let withoutBars = build(contents(segments: [awsSegment], facts: [fact]), details: source())
        #expect(monthOf(withoutBars)?.services.first?.detail?.subscriptionNote == nil)
    }

    @Test("「其他」那一行不能点")
    func remainderHasNoDetail() throws {
        let segments = (0..<7).map { index in
            CompositionSegment(
                accountID: AccountID(rawValue: UUID()),
                providerID: ProviderID("p\(index)"),
                displayName: "S\(index)",
                colorKey: "s\(index)",
                amount: Money(roundedUSD: Double(10 - index)),
                fraction: 0.1,
                percent: 10
            )
        }
        let services = try #require(monthOf(build(contents(segments: segments), details: source()))).services
        #expect(services.last?.isRemainder == true)
        #expect(services.last?.detail == nil)
        #expect(services.first?.detail != nil)
    }
}
