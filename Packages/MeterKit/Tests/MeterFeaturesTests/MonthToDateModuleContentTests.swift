import Foundation
import Testing
import MeterCore
@testable import MeterFeatures
@testable import MeterModules

struct MonthToDateModuleContentTests {
    @Test("估算时首屏金额仍是纯数字，用含估算说明")
    func estimatedUsesCaptionNotMark() {
        let content = MonthToDateModuleContent.make(
            from: MonthToDate(
                totalUSD: Money(roundedUSD: 47.20),
                projectedMonthEndUSD: Money(roundedUSD: 87.70),
                confidence: .estimated,
                estimatedAccounts: [AccountID.fixture(for: .neon)],
                facts: [],
                variableUSD: Money(roundedUSD: 47.20),
                projectedVariableUSD: Money(roundedUSD: 87.70)
            ),
            estimatedNames: ["Neon"],
            staleCaption: nil,
            now: MeterClock.design.now,
            calendar: MeterClock.design.calendar
        )

        #expect(content.amountText == "$47.20")
        #expect(!content.amountText.contains("≈"))
        #expect(content.showsEstimateCaption)
        #expect(content.estimateCaption == String(localized: MeterFeatures.L("含估算")))
        #expect(content.estimatedNames == ["Neon"])
    }

    @Test("精确时不出现含估算")
    func exactHasNoEstimateCaption() {
        let content = MonthToDateModuleContent.make(
            from: MonthToDate(
                totalUSD: Money(roundedUSD: 47.20),
                projectedMonthEndUSD: Money(usd: 80),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [],
                variableUSD: Money(roundedUSD: 47.20),
                projectedVariableUSD: Money(usd: 80)
            ),
            estimatedNames: [],
            staleCaption: nil,
            now: MeterClock.design.now,
            calendar: MeterClock.design.calendar
        )

        #expect(content.amountText == "$47.20")
        #expect(content.estimateCaption == nil)
    }

    @Test("算进订阅时大数字是合计，日期上面写括号里的订阅，预计月底同口径")
    func heroFollowsScopeAndSubscriptionLineSaysIncluded() {
        let content = MonthToDateModuleContent.make(
            from: MonthToDate(
                totalUSD: Money(roundedUSD: 67.20),
                projectedMonthEndUSD: Money(roundedUSD: 107.70),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [],
                variableUSD: Money(roundedUSD: 47.20),
                subscriptionUSD: Money(usd: 20),
                projectedVariableUSD: Money(roundedUSD: 87.70),
                subscriptionAccountIDs: [AccountID.fixture(for: .openai)]
            ),
            estimatedNames: [],
            staleCaption: nil,
            now: MeterClock.design.now,
            calendar: MeterClock.design.calendar
        )

        #expect(content.amountText == "$67.20")
        // 订阅在大数字里了，不能再有「+」——那会被读成「另加」。
        #expect(content.subscriptionCaption?.contains("+") != true)
        #expect(content.subscriptionCaption?.contains("已计入") != true)
        #expect(content.subscriptionCaption?.hasPrefix("（") == true)
        #expect(content.subscriptionCaption?.contains("20") == true)
        #expect(content.subscriptionAccountID == AccountID.fixture(for: .openai))
        #expect(content.projectedCaption?.contains("107.70") == true)
        #expect(content.includesSubscriptions)
        #expect(content.showsSubscriptionScope)
    }

    @Test("筛掉订阅时那一行不出现，切换还在")
    func excludedSubscriptionLineDisappears() {
        let content = MonthToDateModuleContent.make(
            from: MonthToDate(
                totalUSD: Money(roundedUSD: 47.20),
                projectedMonthEndUSD: Money(roundedUSD: 87.70),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [],
                filter: DashboardFilter(includesSubscriptions: false),
                variableUSD: Money(roundedUSD: 47.20),
                subscriptionUSD: Money(usd: 20),
                projectedVariableUSD: Money(roundedUSD: 87.70),
                subscriptionAccountIDs: [AccountID.fixture(for: .openai)]
            ),
            estimatedNames: [],
            staleCaption: nil,
            now: MeterClock.design.now,
            calendar: MeterClock.design.calendar
        )

        #expect(content.amountText == "$47.20")
        #expect(content.subscriptionCaption == nil)
        #expect(!content.includesSubscriptions)
        // 关着也要能切回来：有订阅就摆切换。
        #expect(content.showsSubscriptionScope)
    }

    @Test("一笔订阅都没有时不摆口径切换")
    func scopeControlHiddenWithoutSubscriptions() {
        let content = MonthToDateModuleContent.make(
            from: MonthToDate(
                totalUSD: Money(roundedUSD: 47.20),
                projectedMonthEndUSD: Money(roundedUSD: 87.70),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [],
                variableUSD: Money(roundedUSD: 47.20),
                projectedVariableUSD: Money(roundedUSD: 87.70)
            ),
            estimatedNames: [],
            staleCaption: nil,
            now: MeterClock.design.now,
            calendar: MeterClock.design.calendar
        )

        #expect(!content.showsSubscriptionScope)
        #expect(content.subscriptionCaption == nil)
    }

    @Test("统计区间和预计月底是两半，2×2 只留前半句")
    func periodIsSeparateFromProjection() throws {
        let content = MonthToDateModuleContent.make(
            from: MonthToDate(
                totalUSD: Money(roundedUSD: 47.20),
                projectedMonthEndUSD: Money(roundedUSD: 87.70),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [],
                variableUSD: Money(roundedUSD: 47.20),
                projectedVariableUSD: Money(roundedUSD: 87.70)
            ),
            estimatedNames: [],
            staleCaption: nil,
            now: MeterClock.design.now,
            calendar: MeterClock.design.calendar
        )

        let period = try #require(content.periodCaption)
        let projected = try #require(content.projectedCaption)
        // 126pt 宽里接上区间就要折三行。前半句不许带它。
        #expect(!projected.contains(period))
        #expect(projected.contains("87.70"))
        #expect(content.fullProjectedCaption == "\(projected) · \(period)")
    }

    @Test("回看已结束的月份没有前半句，区间自带「整月」前缀")
    func pastMonthKeepsPeriodOnly() throws {
        let content = MonthToDateModuleContent.make(
            from: MonthToDate(
                totalUSD: Money(roundedUSD: 47.20),
                projectedMonthEndUSD: Money(roundedUSD: 47.20),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [],
                filter: DashboardFilter(monthsBack: 1),
                variableUSD: Money(roundedUSD: 47.20),
                projectedVariableUSD: Money(roundedUSD: 47.20)
            ),
            estimatedNames: [],
            staleCaption: nil,
            now: MeterClock.design.now,
            calendar: MeterClock.design.calendar
        )

        #expect(content.projectedCaption == nil)
        // compact 掐掉的是前半句；这一档前半句本来就没有，区间得自己站得住，
        // 所以它带着「整月」前缀，而不是光秃秃一个月份。
        let period = try #require(content.periodCaption)
        #expect(period.contains("·"))
        #expect(content.fullProjectedCaption == period)
    }

    @Test("多月区间的日期前面不加「合计」")
    func multiMonthPeriodHasNoTotalPrefix() throws {
        let content = MonthToDateModuleContent.make(
            from: MonthToDate(
                totalUSD: Money(roundedUSD: 47.20),
                projectedMonthEndUSD: Money(roundedUSD: 47.20),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [],
                filter: DashboardFilter(period: .months(back: 0, count: 3)),
                window: MonthWindow(newestBack: 0, oldestBack: 2),
                variableUSD: Money(roundedUSD: 47.20),
                projectedVariableUSD: Money(roundedUSD: 47.20)
            ),
            estimatedNames: [],
            staleCaption: nil,
            now: MeterClock.design.now,
            calendar: MeterClock.design.calendar
        )

        let period = try #require(content.periodCaption)
        #expect(!period.hasPrefix("合计"))
        #expect(!period.contains("合计 ·"))
    }
}
