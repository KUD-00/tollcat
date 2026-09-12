import Foundation
import Testing
import MeterCore
import MeterDesign
@testable import MeterFeatures
@testable import MeterModules

/// 筛选**说出口**的部分。
///
/// 这一组守的是同一条线：筛过的数字不是「本月账单」，所以任何把它画出来的
/// 地方都必须带着限定语。首屏、工具栏、分享卡三处漏一处，就会出现一个
/// 看起来完全正常、其实漏了东西的数字——而分享卡那一处漏了会传到别人手机上。
@MainActor
struct DashboardFilterSurfaceTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
    private var now: Date { date(2026, 8, 17) }

    private func asOf(_ filter: DashboardFilter) -> Date {
        filter.anchor(now: now, calendar: calendar)
    }

    private func summary(_ filter: DashboardFilter) -> String? {
        DashboardFilterSummary.full(
            filter: filter,
            window: filter.window(now: now, calendar: calendar),
            asOf: asOf(filter),
            calendar: calendar,
            connections: connections(for: filter.excludedAccounts)
        )
    }

    private func connections(for ids: Set<AccountID>) -> [ProviderConnectionState] {
        let known: [AccountID: ProviderID] = [
            AccountID.fixture(for: .aws): .aws,
            AccountID.fixture(for: .neon): .neon,
            AccountID.fixture(for: .openai): .openai,
            AccountID.fixture(for: .cloudflare): .cloudflare,
        ]
        return ids.map { id in
            ProviderConnectionState(
                accountID: id,
                providerID: known[id] ?? .aws,
                isEnabled: true,
                sortIndex: 0,
                lastSuccessfulRefreshAt: nil,
                credentialReference: "ref.\(id.rawValue.uuidString)",
                includeInGlobalRefresh: true
            )
        }
    }

    // MARK: - 文案

    @Test("什么都没筛就没有限定语——不给所有人加一句「本月」的废话")
    func unfilteredHasNoNote() {
        #expect(summary(.unfiltered) == nil)
    }

    @Test("订阅口径不进限定语——首屏切换和订阅那行自己说明")
    func subscriptionScopeIsNotANote() {
        #expect(summary(DashboardFilter(includesSubscriptions: false)) == nil)
        #expect(summary(DashboardFilter(includesSubscriptions: true)) == nil)
    }

    @Test("本月 + 只动了别的维度时，限定语里不写「本月」")
    func currentMonthIsNotSpelledOut() {
        let note = summary(DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws)]))
        #expect(note == "排除 AWS")
    }

    @Test("往前翻月份时写月名")
    func pastMonthIsNamed() {
        #expect(summary(DashboardFilter(monthsBack: 1)) == "七月")
        #expect(summary(DashboardFilter(monthsBack: 8)) == "十二月")
    }

    @Test("多月区间写成一句人话，不是把月份名往那一摆")
    func rangedPeriodsAreSpelledOut() {
        #expect(summary(DashboardFilter(period: .months(back: 0, count: 3))) == "近 3 个月")
        #expect(summary(DashboardFilter(period: .months(back: 1, count: 3))) == "五月–七月")
        #expect(summary(DashboardFilter(period: .yearToDate)) == "今年至今")
    }

    @Test("「全期间」必须写出从哪个月起——不写清楚会被当成「我这辈子花的钱」")
    func allTimeSaysWhereItStarts() {
        // 手上没有更早的数据时铺满能回看的 12 个月，起点落在去年。
        #expect(summary(DashboardFilter(period: .allTime)) == "全期间（自2025年9月起）")
    }

    @Test("标题和分享卡上单个整月写月份名，不写「本月」")
    func headingNamesTheMonth() {
        func heading(_ filter: DashboardFilter) -> String {
            DashboardFilterSummary.periodHeading(
                period: filter.period,
                window: filter.window(now: now, calendar: calendar),
                asOf: asOf(filter),
                calendar: calendar
            )
        }
        // 标题会跟着页面滚走、卡会发到别人手机上，那时候「本月」已经说不清是哪个月。
        #expect(heading(.unfiltered) == "八月")
        #expect(heading(DashboardFilter(monthsBack: 1)) == "七月")
        // 多月区间自己带着相对性，写成月份范围反而更难读。
        #expect(heading(DashboardFilter(period: .months(back: 0, count: 3))) == "近 3 个月")
    }

    @Test("一两家点名，三家以上报数")
    func exclusionsAreNamedThenCounted() {
        #expect(summary(DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws)])) == "排除 AWS")
        #expect(
            summary(DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws), AccountID.fixture(for: .neon)])) == "排除 AWS、Neon"
        )
        #expect(
            summary(DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws), AccountID.fixture(for: .neon), AccountID.fixture(for: .openai)])) == "排除 3 个账号"
        )
    }

    @Test("同一份筛选每次得到同一句话——Set 的遍历顺序不能漏出来")
    func summaryIsDeterministic() {
        let a = DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws), AccountID.fixture(for: .neon)])
        let b = DashboardFilter(excludedAccounts: [AccountID.fixture(for: .neon), AccountID.fixture(for: .aws)])
        #expect(summary(a) == summary(b))
        // 连算 20 次也不该抖。
        let once = summary(a)
        for _ in 0..<20 {
            #expect(summary(a) == once)
        }
    }

    @Test("时间和服务一起动时按「时间 · 服务」串起来，订阅口径不掺和")
    func allDimensionsCompose() {
        let note = summary(
            DashboardFilter(monthsBack: 1, includesSubscriptions: false, excludedAccounts: [AccountID.fixture(for: .aws)])
        )
        #expect(note == "七月 · 排除 AWS")
    }

    // MARK: - 首屏

    @Test("首屏英雄模块带上限定语，而且和数字在同一个模块里")
    func heroCarriesTheNote() {
        let filter = DashboardFilter(includesSubscriptions: false, excludedAccounts: [AccountID.fixture(for: .aws)])
        let content = heroContent(filter: filter)
        #expect(content.filterNote == "排除 AWS")
    }

    @Test("没筛就没有那一行")
    func heroHasNoNoteWhenUnfiltered() {
        #expect(heroContent(filter: .unfiltered).filterNote == nil)
    }

    @Test("回看已结束的月份不写「预计月底」——那个月没有月底可预计了")
    func heroDropsProjectionForPastMonths() {
        let past = heroContent(filter: DashboardFilter(monthsBack: 1))
        #expect(past.projectedCaption?.contains("预计月底") != true)
        #expect(past.filterNote == "七月")

        let current = heroContent(filter: .unfiltered)
        #expect(current.projectedCaption?.contains("预计月底") == true)
    }

    // MARK: - 分享卡

    @Test("分享卡带上限定语——这张图会传到别人手机上")
    func shareCardCarriesTheNote() {
        let card = shareCard(
            filter: DashboardFilter(monthsBack: 1, excludedAccounts: [AccountID.fixture(for: .aws)])
        )
        #expect(card.filterNote == "七月 · 排除 AWS")
        // 月份标题也跟着锚点走，不是「八月」。
        #expect(card.periodTitle == "七月")
    }

    @Test("多月区间的卡上写的是区间，不是最新那个月")
    func shareCardNamesTheRange() {
        let card = shareCard(filter: DashboardFilter(period: .months(back: 0, count: 3)))
        // 写「八月」会把一张三个月的合计冒充成一个月的账单。
        #expect(card.periodTitle == "近 3 个月")
        #expect(card.filterNote == "近 3 个月")
        // 多月没有月底可预计。
        #expect(card.projectionText?.contains("预计月底") != true)
    }

    @Test("没筛的卡不长出那一行")
    func unfilteredCardHasNoNote() {
        #expect(shareCard(filter: .unfiltered).filterNote == nil)
    }

    @Test("回看过去某个月的卡上不写「预计月底」")
    func shareCardDropsProjectionForPastMonths() {
        let past = shareCard(filter: DashboardFilter(monthsBack: 1))
        #expect(past.projectionText?.contains("预计月底") != true)
        let current = shareCard(filter: .unfiltered)
        #expect(current.projectionText?.contains("预计月底") == true)
    }

    @Test("带限定语的卡真的渲得出来，而且和不带的那张不一样")
    func filteredCardActuallyRenders() throws {
        func render(_ content: ShareCardContent) throws -> Data {
            let image = try #require(ShareCardView.rasterize(content))
            return try #require(RasterImage.pngData(from: image))
        }
        var filtered = ShareCardContent.preview
        filtered.filterNote = "七月 · 排除 AWS"
        let plain = try render(.preview)
        let withNote = try render(filtered)
        #expect(plain != withNote, "限定语没画出来")
    }

    // MARK: - 辅助

    private func heroContent(filter: DashboardFilter) -> MonthToDateModuleContent {
        let asOf = asOf(filter)
        return MonthToDateModuleContent.make(
            from: MonthToDate(
                totalUSD: Money(usd: 47),
                projectedMonthEndUSD: Money(usd: 94),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [],
                filter: filter,
                window: filter.window(now: now, calendar: calendar),
                variableUSD: Money(usd: 47),
                projectedVariableUSD: Money(usd: 94)
            ),
            estimatedNames: [],
            staleCaption: nil,
            now: asOf,
            calendar: calendar,
            connections: connections(for: filter.excludedAccounts)
        )
    }

    private func shareCard(filter: DashboardFilter) -> ShareCardContent {
        let asOf = asOf(filter)
        return ShareCardBuilder.content(
            monthToDate: MonthToDate(
                totalUSD: Money(usd: 47),
                projectedMonthEndUSD: Money(usd: 94),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [],
                changeRatio: 0.18,
                filter: filter,
                window: filter.window(now: now, calendar: calendar),
                variableUSD: Money(usd: 47),
                projectedVariableUSD: Money(usd: 94)
            ),
            composition: [],
            now: asOf,
            calendar: calendar,
            connections: connections(for: filter.excludedAccounts)
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)!
    }
}
