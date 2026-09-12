import Foundation
import Testing
@testable import MeterCore

/// 账本 vs 全量重算。**这一组是整个物化账本方案能不能信的凭据。**
struct LedgerSelfCheckTests {
    let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()
    var now: Date { calendar.date(from: DateComponents(year: 2026, month: 8, day: 17, hour: 12))! }

    func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    /// 每天 1 美元的日粒度读数。
    func dailyUsage(_ provider: ProviderID, _ account: AccountID, months: [(Int, Int)]) -> Snapshot {
        var daily: [Date: Money] = [:]
        for (y, m) in months {
            let count = calendar.range(of: .day, in: .month, for: day(y, m, 1))!.count
            for d in 1...count where day(y, m, d) <= now {
                daily[calendar.startOfDay(for: day(y, m, d))] = Money(usd: 1)
            }
        }
        return Snapshot(
            providerID: provider, accountID: account, kind: .usage,
            fetchedAt: now,
            periodStart: day(2026, 1, 1), periodEnd: day(2026, 8, 31),
            currentSpendUSD: Money(usd: Decimal(daily.count)),
            dailyUSD: daily
        )
    }

    /// 只有周期累计，没有日粒度——折算时按天摊，会降级成估算。
    func periodOnly(_ provider: ProviderID, _ account: AccountID) -> Snapshot {
        Snapshot(
            providerID: provider, accountID: account, kind: .usage,
            fetchedAt: now,
            periodStart: day(2026, 7, 10), periodEnd: day(2026, 8, 20),
            currentSpendUSD: Money(usd: 41)
        )
    }

    func prepaid(_ provider: ProviderID, _ account: AccountID) -> [Snapshot] {
        [(2026, 5, 1, 100), (2026, 6, 1, 88), (2026, 7, 1, 70), (2026, 8, 1, 55), (2026, 8, 15, 40)]
            .map { y, m, d, balance in
                Snapshot(
                    providerID: provider, accountID: account, kind: .prepaid,
                    fetchedAt: day(y, m, d),
                    periodStart: day(y, m, 1), periodEnd: day(y, m, 28),
                    balanceUSD: Money(usd: Decimal(balance))
                )
            }
    }

    func apiSubscription(_ provider: ProviderID, _ account: AccountID) -> Snapshot {
        Snapshot(
            providerID: provider, accountID: account, kind: .subscription,
            fetchedAt: now,
            periodStart: day(2026, 8, 1), periodEnd: day(2026, 8, 31),
            committedMonthlyUSD: Money(usd: 21),
            chargeDayOfMonth: 9
        )
    }

    func planAndUsage(_ provider: ProviderID, _ account: AccountID) -> Snapshot {
        Snapshot(
            providerID: provider, accountID: account, kind: .planAndUsage,
            fetchedAt: now,
            periodStart: day(2026, 8, 1), periodEnd: day(2026, 8, 31),
            currentSpendUSD: Money(usd: 12),
            committedMonthlyUSD: Money(usd: 20),
            chargeDayOfMonth: 3
        )
    }

    /// 取数失败：这条没有任何可计费字段。
    func empty(_ provider: ProviderID, _ account: AccountID) -> Snapshot {
        Snapshot(
            providerID: provider, accountID: account, kind: .usage,
            fetchedAt: now,
            periodStart: day(2026, 8, 1), periodEnd: day(2026, 8, 31)
        )
    }

    func manualSub(_ provider: ProviderID?, _ account: AccountID?, _ amount: Decimal) -> MonthlySubscription {
        MonthlySubscription(
            name: "manual", amount: Money(usd: amount), period: .monthly,
            anchorDate: day(2026, 2, 6), accountID: account, providerID: provider
        )
    }

    var accountA: AccountID { AccountID.fixture(1) }
    var accountB: AccountID { AccountID.fixture(2) }
    var accountC: AccountID { AccountID.fixture(3) }
    var accountD: AccountID { AccountID.fixture(4) }
    var accountE: AccountID { AccountID.fixture(5) }

    /// 一个尽量刁钻的账本：日粒度、只有周期累计、预充值、API 订阅、
    /// 套餐+用量、取数失败、同厂商两份账号、手动订阅（其中一笔顶掉 API 那笔）。
    var ledger: (snapshots: [Snapshot], subscriptions: [MonthlySubscription]) {
        var snapshots: [Snapshot] = [
            dailyUsage(.aws, accountA, months: [(2026, 6), (2026, 7), (2026, 8)]),
            periodOnly(.cloudflare, accountB),
            apiSubscription(.github, accountD),
            planAndUsage(.vercel, accountE),
            empty(.neon, accountC),
        ]
        snapshots.append(contentsOf: prepaid(.openai, accountC))
        return (
            snapshots,
            [manualSub(.openai, accountC, 15), manualSub(nil, nil, 7), manualSub(.vercel, accountE, 30)]
        )
    }

    var periods: [(String, DashboardPeriod)] {
        [
            ("本月", .currentMonth),
            ("上月", .months(back: 1, count: 1)),
            ("三个月前", .months(back: 3, count: 1)),
            ("近 3 个月", .months(back: 0, count: 3)),
            ("五月–七月", .months(back: 1, count: 3)),
            ("今年至今", .yearToDate),
            ("全期间", .allTime),
        ]
    }

    func check(_ filter: DashboardFilter) -> [LedgerSelfCheck.Discrepancy] {
        LedgerSelfCheck.run(
            snapshots: ledger.snapshots,
            subscriptions: ledger.subscriptions,
            now: now,
            calendar: calendar,
            filter: filter
        )
    }

    @Test("每种区间：账本和重算逐项相同")
    func everyPeriodAgrees() {
        for (name, period) in periods {
            let issues = check(DashboardFilter(period: period))
            #expect(issues.isEmpty, "\(name): \(issues.map(\.description).joined(separator: " | "))")
        }
    }

    @Test("关掉订阅口径之后还是相同")
    func withoutSubscriptionsAgrees() {
        for (name, period) in periods {
            let issues = check(DashboardFilter(period: period, includesSubscriptions: false))
            #expect(issues.isEmpty, "\(name): \(issues.map(\.description).joined(separator: " | "))")
        }
    }

    @Test("排掉账号之后还是相同")
    func withExclusionsAgrees() {
        for excluded in [[accountA], [accountC], [accountA, accountD], [accountB, accountC, accountE]] {
            for (name, period) in periods {
                let issues = check(
                    DashboardFilter(period: period, excludedAccounts: Set(excluded))
                )
                #expect(issues.isEmpty, "\(name) 排 \(excluded.count) 家: \(issues.map(\.description).joined(separator: " | "))")
            }
        }
    }

    @Test("空账本也相同——别在没有数据时两条路给出不同的零")
    func emptyLedgerAgrees() {
        let issues = LedgerSelfCheck.run(
            snapshots: [], subscriptions: [], now: now, calendar: calendar
        )
        #expect(issues.isEmpty, "\(issues.map(\.description).joined(separator: " | "))")
    }

    @Test("只有手动订阅、一条快照都没有时也相同")
    func subscriptionsOnlyAgrees() {
        for (name, period) in periods {
            let issues = LedgerSelfCheck.run(
                snapshots: [],
                subscriptions: ledger.subscriptions,
                now: now,
                calendar: calendar,
                filter: DashboardFilter(period: period)
            )
            #expect(issues.isEmpty, "\(name): \(issues.map(\.description).joined(separator: " | "))")
        }
    }
}

extension LedgerSelfCheckTests {
    /// 防"两边都是 nil 所以假通过"。
    @Test("本月的同期真的有值，而且逐笔都对得上")
    func comparisonIsActuallyProduced() {
        let rollups = LedgerSelfCheck.foldAll(
            snapshots: ledger.snapshots, now: now, calendar: calendar
        )
        let viaLedger = LedgerProjection.compute(
            rollups: rollups, subscriptions: ledger.subscriptions,
            now: now, calendar: calendar
        )
        let viaRecompute = PeriodTotalCalculator.compute(
            snapshots: ledger.snapshots, subscriptions: ledger.subscriptions,
            now: now, calendar: calendar
        )
        #expect(viaLedger.comparisonWindow != nil)
        #expect(viaLedger.comparisonUSD != nil)
        #expect(viaLedger.comparisonUSD == viaRecompute.comparisonUSD)
        #expect(viaLedger.changeRatio == viaRecompute.changeRatio)
        // 三种钱各自的同期都得有人产出，否则"对得上"只是因为都缺。
        let kinds = Set(viaLedger.facts.filter { $0.comparisonUSD != nil }.map(\.type))
        #expect(kinds.contains(.monthToDateUsage))
        #expect(kinds.contains(.prepaidConsumption))
        #expect(kinds.contains(.subscriptionIncluded))
    }

    @Test("多月区间一律不给同期——逐月的同期加起来是个重叠窗口")
    func rangedPeriodsHaveNoComparison() {
        let rollups = LedgerSelfCheck.foldAll(
            snapshots: ledger.snapshots, now: now, calendar: calendar
        )
        let ranged = LedgerProjection.compute(
            rollups: rollups, subscriptions: ledger.subscriptions,
            now: now, calendar: calendar,
            filter: DashboardFilter(period: .months(back: 0, count: 3))
        )
        #expect(ranged.comparisonWindow == nil)
        #expect(ranged.comparisonUSD == nil)
        #expect(ranged.facts.allSatisfy { $0.comparisonUSD == nil })
    }

    /// 趋势柱和顶上那个合计是同时出现在屏幕上的两个数。
    /// 柱子加起来对不上合计，是这一屏最刺眼的那种穿帮。
    @Test("逐月的柱子加起来，等于同一个窗口的合计")
    func monthlyHistorySumsToTheTotal() {
        let rollups = LedgerSelfCheck.foldAll(
            snapshots: ledger.snapshots, now: now, calendar: calendar
        )
        for period in [
            DashboardPeriod.months(back: 0, count: 3),
            .months(back: 1, count: 4),
            .yearToDate,
            .allTime,
        ] {
            for includesSubscriptions in [true, false] {
                let filter = DashboardFilter(
                    period: period,
                    includesSubscriptions: includesSubscriptions
                )
                let total = LedgerProjection.compute(
                    rollups: rollups, subscriptions: ledger.subscriptions,
                    now: now, calendar: calendar, filter: filter
                )
                let history = LedgerProjection.monthlyHistory(
                    rollups: rollups, subscriptions: ledger.subscriptions,
                    now: now, calendar: calendar, filter: filter
                )
                // 柱子会比窗口画得宽（至少 6 根），只加窗口里那几根。
                let window = total.window
                let oldest = calendar.date(
                    byAdding: .month,
                    value: -window.oldestBack,
                    to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                )!
                let inWindow = history.filter { $0.monthStart >= oldest }
                #expect(inWindow.count == window.monthCount, "\(period) 的柱子根数不对")
                let summed = inWindow.reduce(Money.zero) { $0 + $1.totalUSD }
                #expect(summed == total.totalUSD, "\(period) 含订阅=\(includesSubscriptions)")
                let summedVariable = inWindow.reduce(Money.zero) { $0 + $1.variableUSD }
                #expect(summedVariable == total.variableUSD, "\(period) 的从量对不上")
            }
        }
    }
}

/// 「这个月这个账号有没有读数」只认**读到数**的那些快照。
///
/// 第二轮审视第 13 条：接入第一天全部失败（key 填错），库里照样有几条账期覆盖
/// 本月的快照。把它们算成「有读数」会让「全期间」的起点落在一个从没读到过数的
/// 月份上，详情页的「—」也会变成 `$0`。
struct LedgerHasReadingTests {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()
    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 8, day: 17, hour: 12))! }

    private func at(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    /// 接入了，但一条都没读到数：账期覆盖七月和八月，四个金额格全空。
    private var failedOnly: [Snapshot] {
        [
            Snapshot(
                providerID: .aws,
                accountID: AccountID.fixture(1),
                kind: .usage,
                fetchedAt: at(2026, 7, 3),
                periodStart: at(2026, 7, 1),
                periodEnd: at(2026, 8, 31)
            )
        ]
    }

    @Test("一条全空的快照不让那个月算作「有读数」")
    func failedReadingsDoNotCountAsAReading() {
        let rollups = LedgerSelfCheck.foldAll(snapshots: failedOnly, now: now, calendar: calendar)
        #expect(!rollups.isEmpty)
        #expect(rollups.allSatisfy { !$0.hasReading })
    }

    @Test("「全期间」的起点不落在一个从没读到过数的月份上")
    func allTimeDoesNotStartFromAMonthWithoutReadings() {
        let rollups = LedgerSelfCheck.foldAll(snapshots: failedOnly, now: now, calendar: calendar)
        #expect(
            LedgerProjection.earliestMonthsBack(
                rollups: rollups,
                subscriptions: [],
                now: now,
                calendar: calendar
            ) == nil
        )
    }

    @Test("同一个账号后来读到数了，那个月就算有读数")
    func aRealReadingFlipsIt() {
        let snapshots = failedOnly + [
            Snapshot(
                providerID: .aws,
                accountID: AccountID.fixture(1),
                kind: .usage,
                fetchedAt: at(2026, 8, 10),
                periodStart: at(2026, 8, 1),
                periodEnd: at(2026, 8, 31),
                currentSpendUSD: Money(usd: 12)
            )
        ]
        let rollups = LedgerSelfCheck.foldAll(snapshots: snapshots, now: now, calendar: calendar)
        let august = rollups.first { calendar.component(.month, from: $0.monthStart) == 8 }
        #expect(august?.hasReading == true)
        let july = rollups.first { calendar.component(.month, from: $0.monthStart) == 7 }
        // 七月只被那条全空的快照覆盖过——仍然是「没读到过」。
        #expect(july?.hasReading == false)
    }
}
