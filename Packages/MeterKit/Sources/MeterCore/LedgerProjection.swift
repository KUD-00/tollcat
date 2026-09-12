import Foundation

/// 从物化账本读出一份 `MonthToDate`。**读路径不再碰快照。**
///
/// 这是整套改动的收益兑现处：以前「近 3 个月」要把全部快照扫 3 遍（每遍还要重新
/// 分组、重新合并日表），现在是把 3×账号数 行加起来。行数上限是 12 × 账号数，
/// 和刷新了多少次彻底无关。
///
/// ## 取景框在这里降级成投影
///
/// `DashboardFilter` 不再是折算的输入，只是对已经算好的行做 filter / group / sum。
/// 「换个看法」于是不再等于「重新算账」——那是点一下「全期间」要等半天的根因。
///
/// ## 手动订阅为什么不在账本里
///
/// 它是**规则**不是观测：一笔月费加一个扣款日，可以随时被编辑。折进按月的行，
/// 等于让一条规则的改动去失效一批观测的行。而读的时候现算是 O(订阅数 × 月数)，
/// 便宜到不值得为它引入一整类失效问题。
///
/// 现算的办法仍然是**复用同一段代码**：把订阅喂给 `MonthToDateCalculator`，快照给空。
///
/// ## 「上月同期」从哪来
///
/// 不在这里现推，是**折叠时一并折出来的**（`MonthlyRollup.comparison*USD`）。
/// 三种钱的同期规则各不相同——用量按日截断、预充值按余额差、订阅按账单口径全额——
/// 让折叠跑真正的折算器，这三条就一个字都不用抄第二遍。
///
/// 只有**单月**区间给同期。多月区间下逐月的同期加起来是一个重叠了 count-1 个月的
/// 窗口，看起来完全正常其实是错的；宁可没有对比，也不给一个半对的数。
public enum LedgerProjection {
    public static func compute(
        rollups: [MonthlyRollup],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        filter: DashboardFilter = .unfiltered
    ) -> MonthToDate {
        let scopedSubscriptions = filter.scope(subscriptions)
        let scopedRollups = rollups.filter { filter.includes($0.accountID) }
        let window = filter.window(
            now: now,
            calendar: calendar,
            earliestMonthsBack: earliestMonthsBack(
                rollups: scopedRollups,
                subscriptions: scopedSubscriptions,
                now: now,
                calendar: calendar
            )
        )

        var monthStarts: [Int: Date] = [:]
        for back in window.monthsBackNewestFirst {
            monthStarts[back] = monthStart(back: back, now: now, calendar: calendar)
        }
        let wanted = Set(monthStarts.values.compactMap { $0 })
        let rows = scopedRollups.filter { wanted.contains($0.monthStart) }

        var confidence = Confidence.exact
        var estimated = OrderedAccountSet()
        var subscriptionAccounts = OrderedAccountSet()
        var variable = Money.zero
        var observedSubscription = Money.zero
        var projectedVariable = Money.zero

        var usageByAccount: [AccountID: Money] = [:]
        var prepaidByAccount: [AccountID: Money] = [:]
        var apiSubByAccount: [AccountID: Money] = [:]
        var supersededByAccount: [AccountID: Money] = [:]
        // 让位是**逐月**的事，所以「这个账号该出哪一类订阅事实」不能一次算完。
        // 手动那笔六月退掉的账号，六月及以前让位、七月起 API 那笔回来——
        // 重算那条路会为它同时吐出 superseded 和 included 两条事实
        // （`PeriodTotalCalculator.mergedFacts` 按 type 分键），这里必须一样。
        var supersededAccounts: Set<AccountID> = []
        var includedAccounts: Set<AccountID> = []
        var comparisonUsage: [AccountID: Money] = [:]
        var comparisonPrepaid: [AccountID: Money] = [:]
        var comparisonSubscription: [AccountID: Money] = [:]
        var manualFacts: [Fact] = []
        var failedAccounts: Set<AccountID> = []
        // 哪几类事实该出现，**照账本记的来**，不按金额是否为 0 推。
        var producedByAccount: [AccountID: Set<FactKind>] = [:]
        // 免费额度取**窗口里最新那个月**的那一格。多月区间下重算那条路也是这么并的
        // （`mergedFacts` 保留第一次出现的，而它从新到旧遍历）。
        var freeQuotaByAccount: [AccountID: Double] = [:]
        var accountOrder = OrderedAccountSet()
        var providerByAccount: [AccountID: ProviderID] = [:]
        var kindByAccount: [AccountID: ProviderKind] = [:]

        let byMonth = Dictionary(grouping: rows, by: \.monthStart)

        // **逐月合，每月各自取整，再相加。**
        //
        // 不是"全部加完最后取一次整"。一个月的账单是一个真实的分位金额，
        // 先合并再取整会让"三个月的合计"比"三个月各自的合计相加"差一两分——
        // 而屏幕上这两个数会同时出现（趋势柱 vs 顶上那个合计），差一分就是穿帮。
        for back in window.monthsBackNewestFirst {
            guard let start = monthStarts[back] ?? nil else { continue }
            var monthVariable = Money.zero
            var monthSubscription = Money.zero

            let monthAnchor = DashboardPeriod.months(back: back, count: 1)
                .anchor(now: now, calendar: calendar)
            // 让位名单**逐月各判一次**，按这个月的锚点、不按此刻。
            let accountsWithManual = scopedSubscriptions
                .accountsSupersedingAPISubscriptions(on: monthAnchor, calendar: calendar)

            // 同月内按厂商再按账号——行的顺序不该跟着数据库返回顺序变，
            // 否则同一份账每次读出来的 facts 顺序都不一样。
            for row in (byMonth[start] ?? []).sorted(by: rowOrder) {
                accountOrder.insert(row.accountID)
                providerByAccount[row.accountID] = row.providerID
                if let kind = row.latestKind { kindByAccount[row.accountID] = kind }
                confidence = confidence.merging(row.confidence)
                if row.isEstimated { estimated.insert(row.accountID) }
                if row.didFailFetch { failedAccounts.insert(row.accountID) }
                producedByAccount[row.accountID, default: []].formUnion(row.producedFactKinds)
                if let ratio = row.freeQuotaUsedRatio, freeQuotaByAccount[row.accountID] == nil {
                    freeQuotaByAccount[row.accountID] = ratio
                }

                usageByAccount[row.accountID, default: .zero] += row.usageUSD
                prepaidByAccount[row.accountID, default: .zero] += row.prepaidUSD
                monthVariable += row.variableUSD
                if let value = row.comparisonUsageUSD {
                    comparisonUsage[row.accountID, default: .zero] += value
                }
                if let value = row.comparisonPrepaidUSD {
                    comparisonPrepaid[row.accountID, default: .zero] += value
                }
                if let value = row.comparisonSubscriptionUSD {
                    comparisonSubscription[row.accountID, default: .zero] += value
                }

                let producedSubscription = row.producedFactKinds.contains(.subscriptionIncluded)
                if accountsWithManual.contains(row.accountID) {
                    supersededByAccount[row.accountID, default: .zero] += row.subscriptionUSD
                    if producedSubscription { supersededAccounts.insert(row.accountID) }
                } else {
                    if producedSubscription { includedAccounts.insert(row.accountID) }
                    if row.subscriptionUSD != .zero {
                        apiSubByAccount[row.accountID, default: .zero] += row.subscriptionUSD
                        monthSubscription += row.subscriptionUSD
                        subscriptionAccounts.insert(row.accountID)
                    }
                }
            }

            let manual = manualSubscriptions(
                scopedSubscriptions,
                monthsBack: back,
                now: now,
                calendar: calendar
            )
            monthSubscription += manual.total
            manualFacts.append(contentsOf: manual.facts)
            for id in manual.accountIDs { subscriptionAccounts.insert(id) }

            variable += monthVariable.roundedToCents()
            observedSubscription += monthSubscription.roundedToCents()
            projectedVariable += MonthProjection
                .extrapolate(monthVariable, now: monthAnchor, calendar: calendar)
                .roundedToCents()
        }

        let includedSubscription = filter.includesSubscriptions
            ? observedSubscription.roundedToCents()
            : .zero
        let variableRounded = variable.roundedToCents()
        let projectedVariableRounded = projectedVariable.roundedToCents()

        // 同期只在单月区间成立。多月区间下把逐月的同期加起来，得到的是一个
        // 重叠了 count-1 个月的窗口——看起来完全正常，其实是错的。
        let comparisonWindow = window.isSingleMonth
            ? ComparisonWindow.samePeriodLastMonth(
                now: DashboardPeriod.months(back: window.newestBack, count: 1)
                    .anchor(now: now, calendar: calendar),
                calendar: calendar
            )
            : nil

        var facts: [Fact] = []
        for accountID in accountOrder.ordered {
            let providerID = providerByAccount[accountID]
            func append(
                _ type: FactKind,
                _ amount: Money?,
                comparison: Money? = nil,
                freeQuotaUsedRatio: Double? = nil,
                kind: ProviderKind?
            ) {
                let previous = comparisonWindow == nil ? nil : comparison
                facts.append(
                    Fact(
                        providerID: providerID,
                        accountID: accountID,
                        kind: kind,
                        amountUSD: amount,
                        comparisonUSD: previous,
                        changeRatio: ChangeRatio.compute(current: amount ?? .zero, previous: previous),
                        freeQuotaUsedRatio: freeQuotaUsedRatio,
                        confidence: type == .fetchFailed ? .partial : .exact,
                        type: type
                    )
                )
            }
            // 金额**不取整**：合计取整是为了给人看一个分位数，事实是拿来再加工的
            // （构成条按段求和、对比算涨跌幅），提前取整会让下游的和对不上顶上那个数。
            let produced = producedByAccount[accountID] ?? []
            if produced.contains(.monthToDateUsage) {
                append(
                    .monthToDateUsage,
                    usageByAccount[accountID] ?? .zero,
                    comparison: comparisonUsage[accountID],
                    kind: .usage
                )
            }
            if produced.contains(.prepaidConsumption) {
                append(
                    .prepaidConsumption,
                    prepaidByAccount[accountID] ?? .zero,
                    comparison: comparisonPrepaid[accountID],
                    kind: .prepaid
                )
            }
            // 让位之后 API 那笔是 superseded，不是 included。**两条可以同时出现**：
            // 手动那笔在窗口中途退掉时，前半段让位、后半段计入。
            if filter.includesSubscriptions {
                if supersededAccounts.contains(accountID) {
                    append(
                        .subscriptionSuperseded,
                        supersededByAccount[accountID] ?? .zero,
                        kind: .subscription
                    )
                }
                if includedAccounts.contains(accountID) {
                    append(
                        .subscriptionIncluded,
                        apiSubByAccount[accountID] ?? .zero,
                        comparison: comparisonSubscription[accountID],
                        kind: .subscription
                    )
                }
            }
            if let ratio = freeQuotaByAccount[accountID] {
                append(.freeQuota, .zero, freeQuotaUsedRatio: ratio, kind: .freeTier)
            }
            if failedAccounts.contains(accountID) {
                append(.fetchFailed, nil, kind: kindByAccount[accountID])
            }
        }
        if filter.includesSubscriptions {
            // 手动订阅的同期是读取时那次折算自己带回来的，原样留着。
            facts.append(contentsOf: merged(manualFacts, keepsComparison: comparisonWindow != nil))
        }
        let (overallComparison, overallRatio) = overall(facts)

        return MonthToDate(
            totalUSD: (variableRounded + includedSubscription).roundedToCents(),
            projectedMonthEndUSD: (projectedVariableRounded + includedSubscription).roundedToCents(),
            confidence: confidence,
            estimatedAccounts: estimated.ordered,
            facts: facts,
            comparisonUSD: overallComparison,
            changeRatio: overallRatio,
            comparisonWindow: comparisonWindow,
            filter: filter,
            window: window,
            variableUSD: variableRounded,
            subscriptionUSD: observedSubscription,
            projectedVariableUSD: projectedVariableRounded,
            subscriptionAccountIDs: subscriptionAccounts.ordered
        )
    }

    /// 逐月的钱，从老到新。趋势柱走这条。
    ///
    /// 以前趋势柱自己跑一遍 `MonthSpendHistoryCalculator`——那等于把合计已经
    /// 逐月算过的东西再算一遍，实测常常比合计本身还贵。现在两边读同一批行。
    ///
    /// **不变量：这里逐月的和，必须等于 `compute` 在同一个窗口上给的合计。**
    /// 屏幕上这两个数是同时出现的（柱子 vs 顶上那个合计），差一分就是穿帮。
    /// 测试里有一条守它。
    public static func monthlyHistory(
        rollups: [MonthlyRollup],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        filter: DashboardFilter = .unfiltered,
        monthCount: Int = MonthSpendHistoryCalculator.defaultMonthCount
    ) -> [MonthSpendPoint] {
        let scopedSubscriptions = filter.scope(subscriptions)
        let scopedRollups = rollups.filter { filter.includes($0.accountID) }
        let window = filter.window(
            now: now,
            calendar: calendar,
            earliestMonthsBack: earliestMonthsBack(
                rollups: scopedRollups,
                subscriptions: scopedSubscriptions,
                now: now,
                calendar: calendar
            )
        )
        // 柱子至少要盖住整个取景框选中的区间——不然图上那几根加起来，
        // 和顶上那个合计对不上号。
        let count = max(monthCount, window.monthCount)
        let newest = window.newestBack
        let oldest = min(newest + count - 1, DashboardPeriod.maxMonthsBack)
        let byMonth = Dictionary(grouping: scopedRollups, by: \.monthStart)

        return (newest...oldest).reversed().compactMap { back in
            guard let start = monthStart(back: back, now: now, calendar: calendar) else { return nil }
            var variable = Money.zero
            var subscription = Money.zero
            // 和 `compute` 一样逐月判让位。按整个窗口判一次会让「中途退订」那一
            // 段的柱子和顶上的合计对不上——`LedgerSelfCheck` 的不变量正是守这个。
            let accountsWithManual = scopedSubscriptions.accountsSupersedingAPISubscriptions(
                on: DashboardPeriod.months(back: back, count: 1).anchor(now: now, calendar: calendar),
                calendar: calendar
            )
            for row in byMonth[start] ?? [] {
                variable += row.variableUSD
                if !accountsWithManual.contains(row.accountID) {
                    subscription += row.subscriptionUSD
                }
            }
            subscription += manualSubscriptions(
                scopedSubscriptions,
                monthsBack: back,
                now: now,
                calendar: calendar
            ).total
            let variableRounded = variable.roundedToCents()
            let included = filter.includesSubscriptions
                ? subscription.roundedToCents()
                : .zero
            return MonthSpendPoint(
                monthStart: start,
                variableUSD: variableRounded,
                totalUSD: (variableRounded + included).roundedToCents()
            )
        }
    }

    /// 账本里最老的一个**有读数**的月份在几个月前。「全期间」的下界。
    ///
    /// 只认有读数的行：折叠会给每个账号铺满 12 个月，按"有行"算的话「全期间」
    /// 永远是 12 个月，那句「自 X 月起」就成了假话。
    public static func earliestMonthsBack(
        rollups: [MonthlyRollup],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar
    ) -> Int? {
        var earliest = rollups.filter(\.hasReading).map(\.monthStart).min()
        for subscription in subscriptions {
            guard
                let anchorMonth = calendar.date(
                    from: calendar.dateComponents([.year, .month], from: subscription.anchorDate)
                )
            else {
                continue
            }
            if anchorMonth < earliest ?? anchorMonth { earliest = anchorMonth }
        }
        guard
            let earliest,
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
            let back = calendar.dateComponents([.month], from: earliest, to: thisMonthStart).month
        else {
            return nil
        }
        return min(max(back, 0), DashboardPeriod.maxMonthsBack)
    }

    // MARK: - 手动订阅

    private struct ManualTotals {
        var total: Money = .zero
        var facts: [Fact] = []
        var accountIDs: [AccountID] = []
    }

    /// 把订阅规则在**某一个月**展开成金额。
    ///
    /// 走的还是 `MonthToDateCalculator`——「这个月该不该算这一笔、算多少」的规则
    /// 只能有一份实现。快照给空，所以这一次调用只在处理订阅，成本与账本大小无关。
    private static func manualSubscriptions(
        _ subscriptions: [MonthlySubscription],
        monthsBack: Int,
        now: Date,
        calendar: Calendar
    ) -> ManualTotals {
        guard !subscriptions.isEmpty else { return ManualTotals() }
        let result = MonthToDateCalculator.compute(
            snapshots: [],
            subscriptions: subscriptions,
            now: now,
            calendar: calendar,
            filter: DashboardFilter(monthsBack: monthsBack)
        )
        return ManualTotals(
            total: result.subscriptionUSD,
            facts: result.facts.filter { $0.type == .subscriptionIncluded },
            accountIDs: result.subscriptionAccountIDs
        )
    }

    /// 整体涨跌幅。和 `MonthToDateCalculator` 走同一个聚合规则：本月金额全进，
    /// 上月只加两边都有数的——缺同期的不当 $0，否则分母会被"没有的那段历史"拉平。
    private static func overall(_ facts: [Fact]) -> (Money?, Double?) {
        let kinds = Set(FactKind.allCases.filter(\.contributesToTotal))
        guard let totals = FactComparisonAggregate.totals(facts: facts, including: kinds) else {
            return (nil, nil)
        }
        return (
            totals.previous,
            ChangeRatio.compute(current: totals.current, previous: totals.previous)
        )
    }

    private static func merged(_ facts: [Fact], keepsComparison: Bool) -> [Fact] {
        struct Key: Hashable {
            var providerID: ProviderID?
            var accountID: AccountID?
            var type: FactKind
        }
        var order: [Key] = []
        var byKey: [Key: Fact] = [:]
        for fact in facts {
            let key = Key(providerID: fact.providerID, accountID: fact.accountID, type: fact.type)
            if var existing = byKey[key] {
                existing.amountUSD = (existing.amountUSD ?? .zero) + (fact.amountUSD ?? .zero)
                existing.comparisonUSD = nil
                existing.changeRatio = nil
                byKey[key] = existing
            } else {
                order.append(key)
                var seed = fact
                if !keepsComparison {
                    seed.comparisonUSD = nil
                    seed.changeRatio = nil
                }
                byKey[key] = seed
            }
        }
        return order.compactMap { byKey[$0] }
    }

    // MARK: - 月份

    private static func monthStart(back: Int, now: Date, calendar: Calendar) -> Date? {
        guard
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        else {
            return nil
        }
        return calendar.date(byAdding: .month, value: -back, to: thisMonthStart)
    }

    private static func rowOrder(_ lhs: MonthlyRollup, _ rhs: MonthlyRollup) -> Bool {
        if lhs.monthStart != rhs.monthStart { return lhs.monthStart > rhs.monthStart }
        if lhs.providerID.rawValue != rhs.providerID.rawValue {
            return lhs.providerID.rawValue < rhs.providerID.rawValue
        }
        return lhs.accountID.rawValue.uuidString < rhs.accountID.rawValue.uuidString
    }
}
