import Foundation

/// 一段整月区间的合计。**做法就是把每个月各算一遍再加起来。**
///
/// 这是整个「多月区间」特性唯一的算法，而且它刻意什么都不算——每一项都还是
/// `MonthToDateCalculator` 那条已经被测过的路。这样换来三件事：
///
/// 1. 订阅自动乘对月数。近 3 个月的 Netflix 是三笔，因为它在三个月里各算了一次；
///    不需要再写一套「枚举窗口内的扣款日」的逻辑，也就不会和单月那套算出不同的数。
/// 2. `Confidence` 的规矩不用动。每个月各自降级，合起来取最差——
///    「筛选不改精度」仍然成立，因为多月区间没有引入任何新的估算。
/// 3. 单月区间（`monthCount == 1`）走的是**同一个返回值**，一个字节都没变，
///    所以现有行为不可能被这次改动碰坏。
public enum PeriodTotalCalculator {
    public static func compute(
        snapshots: [Snapshot],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        filter: DashboardFilter = .unfiltered,
        endedAccounts: [AccountID: Date] = [:]
    ) -> MonthToDate {
        let window = filter.window(
            now: now,
            calendar: calendar,
            earliestMonthsBack: earliestMonthsBack(
                snapshots: filter.scope(snapshots),
                subscriptions: filter.scope(subscriptions),
                now: now,
                calendar: calendar
            )
        )

        // 单月：原样返回，只补上窗口。多加一层 fold 只会多一处能出错的地方。
        guard !window.isSingleMonth else {
            var result = MonthToDateCalculator.compute(
                snapshots: snapshots,
                subscriptions: subscriptions,
                now: now,
                calendar: calendar,
                filter: filter.singleMonth(back: window.newestBack),
                endedAccounts: endedAccounts
            )
            result.filter = filter
            result.window = window
            return result
        }

        let months = window.monthsBackNewestFirst.map { back in
            MonthToDateCalculator.compute(
                snapshots: snapshots,
                subscriptions: subscriptions,
                now: now,
                calendar: calendar,
                filter: filter.singleMonth(back: back),
                endedAccounts: endedAccounts
            )
        }

        var total = Money.zero
        var variable = Money.zero
        var subscription = Money.zero
        var projectedVariable = Money.zero
        var projected = Money.zero
        var confidence = Confidence.exact
        var estimated = OrderedAccountSet()
        var subscriptionAccounts = OrderedAccountSet()

        for month in months {
            total += month.totalUSD
            variable += month.variableUSD
            subscription += month.subscriptionUSD
            projectedVariable += month.projectedVariableUSD
            projected += month.projectedMonthEndUSD
            confidence = confidence.merging(month.confidence)
            month.estimatedAccounts.forEach { estimated.insert($0) }
            month.subscriptionAccountIDs.forEach { subscriptionAccounts.insert($0) }
        }

        return MonthToDate(
            totalUSD: total.roundedToCents(),
            projectedMonthEndUSD: projected.roundedToCents(),
            confidence: confidence,
            estimatedAccounts: estimated.ordered,
            facts: mergedFacts(months),
            // 多月区间**不给对比**。逐月的「上月同期」加起来是一个重叠了
            // count-1 个月的窗口，看起来完全正常，其实是错的；正确的做法是把
            // 整个窗口往前平移 count 个月、并对当月做同日截断，那是另一轮工作。
            // 在那之前宁可没有对比，也不给一个半对的数。
            comparisonUSD: nil,
            changeRatio: nil,
            comparisonWindow: nil,
            filter: filter,
            window: window,
            variableUSD: variable.roundedToCents(),
            subscriptionUSD: subscription.roundedToCents(),
            projectedVariableUSD: projectedVariable.roundedToCents(),
            subscriptionAccountIDs: subscriptionAccounts.ordered
        )
    }

    /// 手上最老的那笔数据在几个月前。「全期间」的下界。
    ///
    /// 快照按账期起点算，订阅按 `anchorDate` 算——订阅在开始那个月就已经扣过一次钱。
    /// 一条都没有时返回 nil，「全期间」于是退化成「能回看的全部月份」。
    public static func earliestMonthsBack(
        snapshots: [Snapshot],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar
    ) -> Int? {
        var earliest: Date?
        for snapshot in snapshots {
            if earliest == nil || snapshot.periodStart < earliest! {
                earliest = snapshot.periodStart
            }
            if let firstDay = snapshot.dailyUSD?.keys.min(), firstDay < earliest ?? firstDay {
                earliest = firstDay
            }
        }
        for subscription in subscriptions where subscription.anchorDate < earliest ?? subscription.anchorDate {
            earliest = subscription.anchorDate
        }
        guard let earliest else { return nil }
        guard
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
            let thatMonthStart = calendar.date(
                from: calendar.dateComponents([.year, .month], from: earliest)
            ),
            let months = calendar.dateComponents([.month], from: thatMonthStart, to: thisMonthStart).month
        else {
            return nil
        }
        return min(max(months, 0), DashboardFilter.maxMonthsBack)
    }

    /// 逐月的 fact 按「同一个账号的同一类钱」合并求和。
    ///
    /// 键里带 `type` 是必须的：同一个账号的 `.monthToDateUsage` 和
    /// `.subscriptionIncluded` 是两笔不同的钱，构成条按 type 分段，并进一条会
    /// 让饼图少一块。顺序按第一次出现——`facts` 的顺序会一路传到构成条和分享卡上。
    ///
    /// 同期金额一律丢掉：多月区间没有对比（理由见上）。免费额度比例取**最新那个月**
    /// 的——它说的是「此刻用掉多少」，不是一段时间的和，加起来会超过 100%。
    private static func mergedFacts(_ months: [MonthToDate]) -> [Fact] {
        struct Key: Hashable {
            var providerID: ProviderID?
            var accountID: AccountID?
            var kind: ProviderKind?
            var type: FactKind
        }

        var order: [Key] = []
        var merged: [Key: Fact] = [:]

        for month in months {
            for fact in month.facts {
                let key = Key(
                    providerID: fact.providerID,
                    accountID: fact.accountID,
                    kind: fact.kind,
                    type: fact.type
                )
                guard var existing = merged[key] else {
                    order.append(key)
                    var seed = fact
                    seed.comparisonUSD = nil
                    seed.changeRatio = nil
                    merged[key] = seed
                    continue
                }
                if let amount = fact.amountUSD {
                    existing.amountUSD = (existing.amountUSD ?? .zero) + amount
                }
                existing.confidence = existing.confidence.merging(fact.confidence)
                merged[key] = existing
            }
        }

        // **不取整**。单月那条路（`MonthToDateCalculator`）吐出来的 fact 就是不取整的，
        // 这里取了整，同一个账号的同一笔钱就会因为"看的是一个月还是三个月"差一分。
        // 取整是给人看的最后一步，事实是拿来再加工的。
        return order.compactMap { merged[$0] }
    }
}
