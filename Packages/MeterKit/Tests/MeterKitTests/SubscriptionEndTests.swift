import Foundation
import Testing
@testable import MeterCore
@testable import MeterModules

/// 「结束」和「删除」不是一回事。
///
/// 这组测试盯的是一个真会丢钱的 bug：历史月份是拿**当前**订阅表现算的
/// （`MonthSpendHistoryCalculator` 逐月重跑 `MonthToDateCalculator`）。
/// 在没有终点字段的年代，退订唯一的出路是删，而删会让那笔钱从过去每一个月里
/// 一起消失——真付过的钱在账本上不见了。
///
/// 所以下面每一条都在钉同一件事：**结束月当月照算，之后归零，更早的月份一分不少。**
struct SubscriptionEndTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    // MARK: - 单月

    @Test("结束月当月仍全额计入：那个月的钱确实扣了")
    func endMonthStillCharges() {
        let subscription = monthly(start: date(2026, 1, 1), end: date(2026, 8, 1))
        let result = compute(subscriptions: [subscription], now: date(2026, 8, 16, 12))
        #expect(result.totalUSD == Money(usd: 20))
    }

    @Test("结束月的下一个月起计 0")
    func monthAfterEndIsZero() {
        let subscription = monthly(start: date(2026, 1, 1), end: date(2026, 8, 1))
        let result = compute(subscriptions: [subscription], now: date(2026, 9, 1, 12))
        #expect(result.totalUSD == .zero)
    }

    @Test("没有终点的订阅照旧每个月计入")
    func openEndedKeepsCharging() {
        let subscription = monthly(start: date(2026, 1, 1), end: nil)
        let result = compute(subscriptions: [subscription], now: date(2027, 3, 9, 12))
        #expect(result.totalUSD == Money(usd: 20))
    }

    @Test("结束在月初也算整月：按日历月比，不比瞬时")
    func endOnFirstDayStillChargesThatMonth() {
        // 8 月 1 日 00:00 结束，8 月 31 日读——仍是 8 月，仍要算。
        let subscription = monthly(start: date(2026, 1, 1), end: date(2026, 8, 1))
        let result = compute(subscriptions: [subscription], now: date(2026, 8, 31, 23))
        #expect(result.totalUSD == Money(usd: 20))
    }

    @Test("年付：周年月落在结束之后不再计入")
    func annualAfterEndIsZero() {
        let subscription = MonthlySubscription(
            name: "Copilot",
            amount: Money(usd: 100),
            period: .annual,
            anchorDate: date(2025, 3, 17),
            endDate: date(2026, 8, 1)
        )
        // 2027 年 3 月本该是周年月，但订阅在 2026 年 8 月就停了。
        let result = compute(subscriptions: [subscription], now: date(2027, 3, 20, 12))
        #expect(result.totalUSD == .zero)
    }

    @Test("年付：结束之前的周年月照常整笔计入")
    func annualBeforeEndStillCharges() {
        let subscription = MonthlySubscription(
            name: "Copilot",
            amount: Money(usd: 100),
            period: .annual,
            anchorDate: date(2025, 3, 17),
            endDate: date(2026, 8, 1)
        )
        let result = compute(subscriptions: [subscription], now: date(2026, 3, 20, 12))
        #expect(result.totalUSD == Money(usd: 100))
    }

    @Test("结束月填在未来：这几个月照常计入，之后才归零")
    func futureEndStillCharges() {
        // 8 月取消、服务用到 11 月底。9–11 月的钱还得付。
        let subscription = monthly(start: date(2026, 1, 1), end: date(2026, 11, 1))
        #expect(compute(subscriptions: [subscription], now: date(2026, 9, 5, 12)).totalUSD == Money(usd: 20))
        #expect(compute(subscriptions: [subscription], now: date(2026, 11, 30, 12)).totalUSD == Money(usd: 20))
        #expect(compute(subscriptions: [subscription], now: date(2026, 12, 1, 12)).totalUSD == .zero)
    }

    /// 「恢复」这个概念不存在，取而代之的是两段独立的记录。
    @Test("同一个产品的两段订阅：中间没付钱的月份是 0")
    func twoSeparateRunsLeaveTheGapEmpty() {
        let first = monthly(start: date(2026, 1, 1), end: date(2026, 3, 1))
        let second = monthly(start: date(2026, 5, 1), end: nil)
        let history = MonthSpendHistoryCalculator.compute(
            snapshots: [],
            subscriptions: [first, second],
            now: date(2026, 6, 16, 12),
            calendar: calendar,
            monthCount: 6
        )
        let byMonth = Dictionary(
            uniqueKeysWithValues: history.map { (calendar.component(.month, from: $0.monthStart), $0.totalUSD) }
        )
        #expect(byMonth[1] == Money(usd: 20))
        #expect(byMonth[3] == Money(usd: 20))
        // 4 月两段都不覆盖。把第一段「恢复」成第二段就会在这里凭空长出 $20。
        #expect(byMonth[4] == .zero)
        #expect(byMonth[5] == Money(usd: 20))
        #expect(byMonth[6] == Money(usd: 20))
    }

    // MARK: - 历史

    /// 这一条就是当初那个 bug 的回归测试。
    @Test("退掉之后，过去每个月的合计一分不少")
    func historyKeepsPaidMonths() {
        let subscription = monthly(start: date(2026, 3, 1), end: date(2026, 8, 1))
        let history = MonthSpendHistoryCalculator.compute(
            snapshots: [],
            subscriptions: [subscription],
            now: date(2026, 10, 16, 12),
            calendar: calendar,
            monthCount: 9
        )
        let byMonth = Dictionary(
            uniqueKeysWithValues: history.map { (calendar.component(.month, from: $0.monthStart), $0.totalUSD) }
        )
        // 3–8 月付过，9、10 月没有。
        for month in 3...8 {
            #expect(byMonth[month] == Money(usd: 20), "\(month) 月应当仍是 $20")
        }
        #expect(byMonth[9] == .zero)
        #expect(byMonth[10] == .zero)
        // 开始之前也是 0，起点那把闸没被终点弄坏。
        #expect(byMonth[2] == .zero)
    }

    @Test("较上月同期：上月还在付、这月退了，同期算得出上月那一笔")
    func comparisonSeesLastMonth() {
        let subscription = monthly(start: date(2026, 1, 1), end: date(2026, 8, 1))
        let result = compute(subscriptions: [subscription], now: date(2026, 9, 16, 12))
        let fact = result.facts.first { $0.type == .subscriptionIncluded }
        #expect(fact?.amountUSD == .zero)
        #expect(fact?.comparisonUSD == Money(usd: 20))
    }

    // MARK: - 即将扣款

    @Test("退掉的年付不再出现在「即将扣款」里")
    func endedAnnualDropsOutOfUpcoming() {
        let now = date(2026, 3, 14, 12)
        let live = MonthlySubscription(
            name: "还在付",
            amount: Money(usd: 100),
            period: .annual,
            anchorDate: date(2025, 3, 17)
        )
        let ended = MonthlySubscription(
            name: "退掉了",
            amount: Money(usd: 100),
            period: .annual,
            anchorDate: date(2025, 3, 18),
            endDate: date(2026, 1, 1)
        )
        let charges = UpcomingChargeCalculator.charges(
            snapshots: [],
            subscriptions: [live, ended],
            now: now,
            calendar: calendar
        )
        #expect(charges.map(\.name) == ["还在付"])
    }

    // MARK: - 结束的接入

    @Test("结束掉的接入：结束月照算，之后本月不再续那笔月费")
    func endedAccountStopsRenewing() {
        let accountID = AccountID.fixture(for: .github)
        let snapshot = Snapshot(
            providerID: .github,
            accountID: accountID,
            kind: .subscription,
            fetchedAt: date(2026, 8, 10, 12),
            periodStart: date(2026, 8, 1),
            periodEnd: date(2026, 8, 31),
            committedMonthlyUSD: Money(usd: 4),
            chargeDayOfMonth: 1
        )
        let ended = [accountID: date(2026, 8, 20)]

        // 结束当月：仍是这个月的账单。
        let august = MonthToDateCalculator.compute(
            snapshots: [snapshot],
            subscriptions: [],
            now: date(2026, 8, 25, 12),
            calendar: calendar,
            endedAccounts: ended
        )
        #expect(august.totalUSD == Money(usd: 4))

        // 之后：不能照着最后一条快照永远续下去。
        let october = MonthToDateCalculator.compute(
            snapshots: [snapshot],
            subscriptions: [],
            now: date(2026, 10, 5, 12),
            calendar: calendar,
            endedAccounts: ended
        )
        #expect(october.totalUSD == .zero)
        #expect(october.facts.isEmpty)
    }

    @Test("结束掉的接入不影响它自己那几个月的历史")
    func endedAccountKeepsItsHistory() {
        let accountID = AccountID.fixture(for: .github)
        let snapshot = Snapshot(
            providerID: .github,
            accountID: accountID,
            kind: .subscription,
            fetchedAt: date(2026, 7, 10, 12),
            periodStart: date(2026, 7, 1),
            periodEnd: date(2026, 7, 31),
            committedMonthlyUSD: Money(usd: 4),
            chargeDayOfMonth: 1
        )
        let history = MonthSpendHistoryCalculator.compute(
            snapshots: [snapshot],
            subscriptions: [],
            now: date(2026, 10, 16, 12),
            calendar: calendar,
            monthCount: 4,
            endedAccounts: [accountID: date(2026, 7, 31)]
        )
        let byMonth = Dictionary(
            uniqueKeysWithValues: history.map { (calendar.component(.month, from: $0.monthStart), $0.totalUSD) }
        )
        #expect(byMonth[7] == Money(usd: 4))
        #expect(byMonth[8] == .zero)
        #expect(byMonth[9] == .zero)
    }

    // MARK: - 压住 API 档位

    /// 这一条盯的是「结束」最贵的一个漏：**总数上凭空少一笔钱，页面上还不吭声。**
    ///
    /// 手动录的档位会让同一账号 API 报回来的 `committedMonthlyUSD` 让位
    /// （`.subscriptionSuperseded`，不进总数）。让位名单以前是无条件的
    /// `Set(subscriptions.compactMap(\.accountID))`——手动那笔退掉之后，
    /// 名单里还留着这个账号，于是两边都不算：手动的算 0，API 的被压住。
    @Test("手动订阅退掉后，同账号 API 报的档位重新计入总数")
    func endedManualSubscriptionStopsSupersedingAPI() {
        let accountID = AccountID.fixture(for: .github)
        let snapshot = Snapshot(
            providerID: .github,
            accountID: accountID,
            kind: .subscription,
            fetchedAt: date(2026, 9, 10, 12),
            periodStart: date(2026, 9, 1),
            periodEnd: date(2026, 9, 30),
            committedMonthlyUSD: Money(usd: 4),
            chargeDayOfMonth: 1
        )
        let manual = MonthlySubscription(
            name: "Copilot",
            amount: Money(usd: 10),
            period: .monthly,
            anchorDate: date(2026, 1, 1),
            endDate: date(2026, 8, 1),
            accountID: accountID,
            providerID: .github
        )

        // 8 月：手动那笔还在付，$10 算数，API 的 $4 让位。
        let august = compute(snapshots: [snapshot], subscriptions: [manual], now: date(2026, 8, 20, 12))
        #expect(august.totalUSD == Money(usd: 10))
        #expect(august.facts.contains { $0.type == .subscriptionSuperseded })

        // 9 月：手动那笔退了，API 的 $4 必须回来，不能两边都不算。
        let september = compute(snapshots: [snapshot], subscriptions: [manual], now: date(2026, 9, 20, 12))
        #expect(september.totalUSD == Money(usd: 4))
        #expect(!september.facts.contains { $0.type == .subscriptionSuperseded })
    }

    @Test("还没开始的手动订阅不压住 API 档位")
    func futureManualSubscriptionDoesNotSupersedeYet() {
        let accountID = AccountID.fixture(for: .github)
        let snapshot = Snapshot(
            providerID: .github,
            accountID: accountID,
            kind: .subscription,
            fetchedAt: date(2026, 3, 10, 12),
            periodStart: date(2026, 3, 1),
            periodEnd: date(2026, 3, 31),
            committedMonthlyUSD: Money(usd: 4),
            chargeDayOfMonth: 1
        )
        let manual = MonthlySubscription(
            name: "Copilot",
            amount: Money(usd: 10),
            period: .monthly,
            anchorDate: date(2026, 5, 1),
            accountID: accountID,
            providerID: .github
        )
        let march = compute(snapshots: [snapshot], subscriptions: [manual], now: date(2026, 3, 20, 12))
        #expect(march.totalUSD == Money(usd: 4))
    }

    @Test("退掉的订阅不再往「本月订阅」那行挂账号")
    func endedSubscriptionDropsOutOfAccountGlyphs() {
        let accountID = AccountID.fixture(for: .openai)
        let subscription = MonthlySubscription(
            name: "ChatGPT Plus",
            amount: Money(usd: 20),
            period: .monthly,
            anchorDate: date(2026, 1, 1),
            endDate: date(2026, 8, 1),
            accountID: accountID,
            providerID: .openai
        )
        #expect(compute(subscriptions: [subscription], now: date(2026, 8, 9, 12))
            .subscriptionAccountIDs == [accountID])
        #expect(compute(subscriptions: [subscription], now: date(2026, 9, 9, 12))
            .subscriptionAccountIDs.isEmpty)
    }

    /// 账本那条路**自己也要对**，不只是和重算一致。
    ///
    /// `LedgerSelfCheck` 比的是两条路一不一致——两边同时错它一声不吭。
    /// 而让位名单以前在 `LedgerProjection` 里抄了两份（投影一份、趋势柱一份），
    /// 都是按整个窗口算一次的：手动那笔在窗口中途退掉时，退掉之后的月份
    /// 仍然被压着，柱子和合计一起少一笔。
    @Test("账本路径：手动订阅中途退掉，之后几个月 API 那笔回到柱子里")
    func ledgerPathRestoresAPISubscriptionAfterManualEnds() {
        let accountID = AccountID.fixture(for: .github)
        let now = date(2026, 9, 20, 12)
        let snapshots = (7...9).map { month in
            Snapshot(
                providerID: .github,
                accountID: accountID,
                kind: .subscription,
                fetchedAt: date(2026, month, 10, 12),
                periodStart: date(2026, month, 1),
                periodEnd: date(2026, month, 28),
                committedMonthlyUSD: Money(usd: 4),
                chargeDayOfMonth: 1
            )
        }
        let manual = MonthlySubscription(
            name: "Copilot",
            amount: Money(usd: 10),
            period: .monthly,
            anchorDate: date(2026, 1, 1),
            endDate: date(2026, 8, 1),
            accountID: accountID,
            providerID: .github
        )
        let rollups = LedgerFolder.fold(
            accountID: accountID,
            snapshots: snapshots,
            now: now,
            calendar: calendar
        )
        let history = LedgerProjection.monthlyHistory(
            rollups: rollups,
            subscriptions: [manual],
            now: now,
            calendar: calendar,
            monthCount: 3
        )
        let byMonth = Dictionary(
            uniqueKeysWithValues: history.map { (calendar.component(.month, from: $0.monthStart), $0.totalUSD) }
        )
        // 7、8 月手动那笔还在付：$10，API 的 $4 让位。
        #expect(byMonth[7] == Money(usd: 10))
        #expect(byMonth[8] == Money(usd: 10))
        // 9 月手动那笔退了：API 的 $4 必须回来，不能两边都不算。
        #expect(byMonth[9] == Money(usd: 4))

        // 柱子加起来必须等于同一窗口的合计——屏幕上这两个数同时出现。
        let total = LedgerProjection.compute(
            rollups: rollups,
            subscriptions: [manual],
            now: now,
            calendar: calendar,
            filter: DashboardFilter(period: .months(back: 0, count: 3))
        )
        #expect(total.totalUSD == Money(usd: 24))
    }

    // MARK: - 仪表盘「固定订阅」模块

    /// 单月这张卡回答的是「那个月每月固定要出多少钱」。把退掉的算进来，
    /// 它的合计会比首屏那行订阅多出一截——两个数字在同一屏上打架。
    @Test("固定订阅模块不列退掉的那几笔")
    func subscriptionsModuleExcludesEnded() {
        let live = monthly(start: date(2026, 1, 1), end: nil)
        let ended = MonthlySubscription(
            name: "Midjourney",
            amount: Money(usd: 30),
            period: .monthly,
            anchorDate: date(2026, 1, 1),
            endDate: date(2026, 5, 1)
        )
        let content = subscriptionsModule([live, ended], now: date(2026, 9, 9, 12))
        #expect(content?.items.map(\.name) == ["ChatGPT Plus"])
        #expect(content?.monthlyTotalValue == 20)
    }

    @Test("全都退掉了：这张卡整个不出现")
    func subscriptionsModuleDisappearsWhenAllEnded() {
        let ended = monthly(start: date(2026, 1, 1), end: date(2026, 5, 1))
        #expect(subscriptionsModule([ended], now: date(2026, 9, 9, 12)) == nil)
    }

    @Test("回看历史月份：列的是那个月还在付的那几笔")
    func subscriptionsModuleFollowsTheAnchorMonth() {
        let ended = monthly(start: date(2026, 1, 1), end: date(2026, 5, 1))
        // 取景框锚在 5 月：那个月还在付。
        #expect(subscriptionsModule([ended], now: date(2026, 5, 31, 23))?.items.count == 1)
    }

    @Test("下个月才首扣的订阅这个月不进合计")
    func subscriptionsModuleExcludesNotYetStarted() {
        let future = monthly(start: date(2026, 10, 1), end: nil)
        #expect(subscriptionsModule([future], now: date(2026, 9, 9, 12)) == nil)
    }

    @Test("退掉的年付不再预告「下一笔」")
    func subscriptionsModuleDropsNextChargeOfEnded() {
        let ended = MonthlySubscription(
            name: "Copilot",
            amount: Money(usd: 100),
            period: .annual,
            anchorDate: date(2025, 3, 17),
            endDate: date(2026, 1, 1)
        )
        #expect(subscriptionsModule([ended], now: date(2026, 3, 1, 12)) == nil)
    }

    @Test("多月区间列出窗口里扣过的每一笔，含已经退掉的")
    func subscriptionsModulePeriodTotalsIncludeEndedInWindow() {
        let live = monthly(start: date(2026, 1, 1), end: nil)
        let ended = MonthlySubscription(
            name: "Midjourney",
            amount: Money(usd: 30),
            period: .monthly,
            anchorDate: date(2026, 1, 1),
            endDate: date(2026, 5, 1)
        )
        let content = subscriptionsModule(
            [live, ended],
            now: date(2026, 9, 9, 12),
            window: MonthWindow(newestBack: 0, oldestBack: 8)
        )
        #expect(Set(content?.items.map(\.name) ?? []) == ["ChatGPT Plus", "Midjourney"])
        // ChatGPT：1–9 月九笔；$20 × 9。Midjourney：1–5 月五笔；$30 × 5。
        #expect(content?.monthlyTotalValue == 330)
        #expect(content?.isMonthlyRunRate == false)
        #expect(content?.headlineCaption == "合计")
    }

    @Test("多月区间的行金额是这段实扣，不是一张月费")
    func subscriptionsModulePeriodRowIsActualCharges() {
        let sub = monthly(start: date(2026, 7, 1), end: nil)
        let content = subscriptionsModule(
            [sub],
            now: date(2026, 9, 9, 12),
            window: MonthWindow(newestBack: 0, oldestBack: 2)
        )
        #expect(content?.monthlyTotalValue == 60)
        #expect(content?.items.first?.amountValue == 60)
        #expect(content?.items.first?.periodCaption == "每月 × 3")
    }

    @Test("多月区间里没扣过的年付不出现")
    func subscriptionsModulePeriodDropsAnnualThatDidNotCharge() {
        let annual = MonthlySubscription(
            name: "Copilot",
            amount: Money(usd: 120),
            period: .annual,
            anchorDate: date(2026, 3, 1)
        )
        let content = subscriptionsModule(
            [annual],
            now: date(2026, 9, 9, 12),
            window: MonthWindow(newestBack: 0, oldestBack: 2)
        )
        #expect(content == nil)
    }

    // MARK: - Helpers

    private func subscriptionsModule(
        _ subscriptions: [MonthlySubscription],
        now: Date,
        window: MonthWindow = .currentMonth
    ) -> SubscriptionsModuleContent? {
        SubscriptionsModuleBuilder.make(
            subscriptions: subscriptions,
            connections: [],
            now: now,
            calendar: calendar,
            presentation: .usd,
            window: window
        )
    }

    private func monthly(start: Date, end: Date?) -> MonthlySubscription {
        MonthlySubscription(
            name: "ChatGPT Plus",
            amount: Money(usd: 20),
            period: .monthly,
            anchorDate: start,
            endDate: end
        )
    }

    private func compute(
        snapshots: [Snapshot] = [],
        subscriptions: [MonthlySubscription] = [],
        now: Date
    ) -> MonthToDate {
        MonthToDateCalculator.compute(
            snapshots: snapshots,
            subscriptions: subscriptions,
            now: now,
            calendar: calendar
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return calendar.date(from: components)!
    }
}
