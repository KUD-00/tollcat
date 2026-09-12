import Foundation
import Testing
import MeterCore
@testable import MeterFeatures

/// 回看过去某个月时，页面上不能留下任何在讲「此刻 / 将来」的东西。
///
/// 这一类错很难在代码里看出来，因为每一处单独看都对：余额确实快用完了、
/// Vercel 确实用了 84%、按这个速度月底确实是那个数。错的是它们和顶上那句
/// 「七月」放在同一屏——那一屏在同时说两个时态。
@MainActor
struct DashboardFilterPastMonthTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private func monthToDate(filter: DashboardFilter) -> MonthToDate {
        MonthToDate(
            totalUSD: Money(usd: 10),
            projectedMonthEndUSD: Money(usd: 10),
            confidence: .exact,
            estimatedAccounts: [],
            facts: [],
            filter: filter,
            variableUSD: Money(usd: 10),
            projectedVariableUSD: Money(usd: 10)
        )
    }

    private func prompt(filter: DashboardFilter) -> CatSpeechPrompt {
        CatSpeechFacts.make(
            from: monthToDate(filter: filter),
            mood: .normal,
            hasAnyProvider: true,
            runways: [],
            locale: Locale(identifier: "zh-Hans")
        )
    }

    @Test("猫在回看已过完的月份时不提「月底」")
    func catStopsTalkingAboutMonthEnd() throws {
        let past = CatSpeechFallback.candidates(for: prompt(filter: DashboardFilter(monthsBack: 1)))
        #expect(!past.isEmpty)
        for candidate in past {
            #expect(!candidate.text.contains("月底"), "还在说月底：\(candidate.text)")
        }
        #expect(try #require(past.first).text.contains("10.00"))
    }

    @Test("本月照旧说「预计月底」——这条是防止上面那个修法把正常情况也改坏")
    func catStillProjectsForTheCurrentMonth() {
        let current = CatSpeechFallback.candidates(for: prompt(filter: .unfiltered))
        #expect(current.contains { $0.text.contains("月底") })
    }

    @Test("取景框自己就说清楚了哪些模块该关")
    func filterDeclaresWhichModulesSurvive() {
        // 这三个 Bool 是 `DashboardModel.rebuildPresentation()` 唯一的依据，
        // 把它们钉住比逐个断言模块内容便宜也稳。
        let past = DashboardFilter(monthsBack: 1)
        #expect(!past.allowsProjection)
        #expect(!past.showsPresentTenseModules)

        // 只关订阅、不翻月份时，「此刻」类模块照常显示——
        // 余额告急和排除订阅是两件不相干的事。
        let noSubscriptions = DashboardFilter(includesSubscriptions: false)
        #expect(noSubscriptions.allowsProjection)
        #expect(noSubscriptions.showsPresentTenseModules)
    }
}
