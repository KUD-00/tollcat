import Foundation

/// 把一个账号的快照日志折成按月的账本行。
///
/// ## 为什么是「一个账号」而不是「全部快照」
///
/// 因为**失效边界就是账号**。一次刷新只写一条快照、只属于一个账号，于是只有
/// 那个账号需要重折；别的账号一行都不用碰。
/// 如果折叠的入口是「全部快照」，那这条性质就表达不出来，每次刷新都得整份重来。
///
/// ## 为什么直接复用 `MonthToDateCalculator`
///
/// 折叠规则和现在的折算规则必须**逐项相同**，否则物化出来的账本会和重算的
/// 结果对不上——而那种不一致最坏的地方在于它看起来完全正常。让它们相同最
/// 可靠的办法不是"照着再写一遍"，是**就用同一段代码**：把这个账号的快照和
/// 一个单月取景框喂给现有的折算器，读它吐出来的 `facts`。
///
/// 于是「折叠正确」这件事是构造上成立的，不靠测试去追平。代价是折一行的成本
/// 和现在折一个月一样——但那只发生在**写入时**，而且只针对被触及的那一个账号。
public enum LedgerFolder {
    /// 折一个账号的全部月份。
    ///
    /// - Parameter months: 只折这几个月（`monthStart` 集合）。给 nil 折它有数据的全部月份。
    ///   刷新那条路折全部月份（没被账期覆盖的月份也依赖最新那条读数）；**跨天**那条
    ///   只传当月一个月——过去月份的行不依赖「今天」，见
    ///   `MonthlyLedgerStore.refoldCurrentMonth`。
    public static func fold(
        accountID: AccountID,
        snapshots: [Snapshot],
        now: Date,
        calendar: Calendar,
        months: Set<Date>? = nil,
        endedAccounts: [AccountID: Date] = [:]
    ) -> [MonthlyRollup] {
        let own = snapshots.filter { $0.accountID == accountID }
        guard let providerID = own.first?.providerID else { return [] }
        let foldedThrough = own.map(\.fetchedAt).max() ?? .distantPast

        // 日表**整段只合一次**，再按月切。这正是以前每次读都要重做、
        // 实测占单月折算一半以上时间的那件事。
        let daily = SnapshotDailyMap.merged(from: own, calendar: calendar)
        // 每天最后一次观测到的余额。和日表一样，整段只归约一次再按月切。
        var dailyBalance: [Date: (at: Date, balance: Money)] = [:]
        for snapshot in own where snapshot.kind == .prepaid {
            guard let balance = snapshot.balanceUSD else { continue }
            let day = calendar.startOfDay(for: snapshot.fetchedAt)
            if let existing = dailyBalance[day], existing.at > snapshot.fetchedAt { continue }
            dailyBalance[day] = (snapshot.fetchedAt, balance)
        }
        let balanceByDay = dailyBalance.mapValues(\.balance)

        // **每个账号都折满能回看的全部月份**，包括它还不存在的那些月。
        //
        // 看起来浪费（10 家 × 12 个月 = 120 行，其实没有），但它保证"账本里有行"
        // 和"重算会算到"完全一一对应。只折有数据的月份的话，账号出现之前的月份
        // 在账本里查不到、在重算里却仍然会被算一遍（并且会把这家标成估算）——
        // 那种差异正好落在最不容易发现的地方。
        let targets = months ?? Set(allMonthStarts(now: now, calendar: calendar))
        return targets
            .sorted()
            .compactMap { monthStart in
                row(
                    accountID: accountID,
                    providerID: providerID,
                    monthStart: monthStart,
                    snapshots: own,
                    daily: daily,
                    balanceByDay: balanceByDay,
                    now: now,
                    calendar: calendar,
                    foldedThrough: foldedThrough,
                    endedAccounts: endedAccounts
                )
            }
    }

    // MARK: - 一行

    private static func row(
        accountID: AccountID,
        providerID: ProviderID,
        monthStart: Date,
        snapshots: [Snapshot],
        daily: [Date: Money],
        balanceByDay: [Date: Money],
        now: Date,
        calendar: Calendar,
        foldedThrough: Date,
        endedAccounts: [AccountID: Date]
    ) -> MonthlyRollup? {
        guard let back = monthsBack(from: monthStart, now: now, calendar: calendar) else {
            return nil
        }
        let filter = DashboardFilter(monthsBack: back)
        let asOf = filter.anchor(now: now, calendar: calendar)
        let linesSource = snapshots
            .filter { $0.lines?.isEmpty == false && $0.fetchedAt <= asOf }
            .max(by: { $0.fetchedAt < $1.fetchedAt })
        // 订阅**不进折叠**：手动订阅是规则不是观测，而且规则可以被改。
        // 展开成行会引入一整类失效问题，而读的时候现算便宜得多（见 `LedgerProjection`）。
        let result = MonthToDateCalculator.compute(
            snapshots: snapshots,
            subscriptions: [],
            now: now,
            calendar: calendar,
            filter: filter,
            endedAccounts: endedAccounts,
            // 日表整段已经合过一次（见 `fold`），别让每个月再各合两遍。
            mergedDaily: [accountID: daily]
        )

        var rollup = MonthlyRollup(
            accountID: accountID,
            providerID: providerID,
            monthStart: monthStart,
            confidence: result.confidence,
            isEstimated: result.estimatedAccounts.contains(accountID),
            hasReading: hasReading(
                snapshots: snapshots,
                daily: daily,
                monthStart: monthStart,
                asOf: asOf,
                calendar: calendar
            ),
            dailyUSD: daily.filter { $0.key >= monthStart && $0.key <= asOf },
            dailyBalanceUSD: balanceByDay.filter { $0.key >= monthStart && $0.key <= asOf },
            // 明细取「截止这个月最后一瞬、最近一条带明细的」，和构成页原来的选法同一条。
            lines: linesSource?.lines,
            linesAt: linesSource?.fetchedAt,
            foldedAsOf: asOf,
            latestKind: snapshots.max(by: { $0.fetchedAt < $1.fetchedAt })?.kind,
            foldedThrough: foldedThrough
        )
        for fact in result.facts {
            rollup.producedFactKinds.insert(fact.type)
            switch fact.type {
            case .monthToDateUsage:
                rollup.usageUSD += fact.amountUSD ?? .zero
                rollup.comparisonUsageUSD = add(rollup.comparisonUsageUSD, fact.comparisonUSD)
            case .prepaidConsumption:
                rollup.prepaidUSD += fact.amountUSD ?? .zero
                rollup.comparisonPrepaidUSD = add(rollup.comparisonPrepaidUSD, fact.comparisonUSD)
            case .subscriptionIncluded:
                rollup.subscriptionUSD += fact.amountUSD ?? .zero
                rollup.comparisonSubscriptionUSD = add(
                    rollup.comparisonSubscriptionUSD,
                    fact.comparisonUSD
                )
            case .subscriptionSuperseded:
                // 折叠时不传手动订阅，所以 API 那笔永远不会在这里让位，
                // 这条分支到不了。「让位」是读取时的判断（见 `LedgerProjection`）。
                break
            case .fetchFailed:
                rollup.didFailFetch = true
            case .freeQuota:
                // 不是钱，是个瞬时比例——加起来会超过 100%，所以单独存一格不进合计。
                rollup.freeQuotaUsedRatio = fact.freeQuotaUsedRatio
            }
        }
        return rollup
    }

    /// nil 和 0 是两件事：**同期为 nil 表示「这一家还不能比」**，
    /// 涨跌幅的分母里不该有它（见 `FactComparisonAggregate`）。加成 0 会把
    /// 「没有上个月的数据」悄悄读成「上个月花了 0」，涨幅当场变成 +∞。
    private static func add(_ lhs: Money?, _ rhs: Money?) -> Money? {
        guard let rhs else { return lhs }
        return (lhs ?? .zero) + rhs
    }

    /// 这个月这个账号到底有没有读数。
    ///
    /// 直接看快照，不从折算结果反推：折算结果里 `$0` 和「没数据」长得一模一样，
    /// 而这两件事在这个 App 里必须分得开。
    ///
    /// **只认读到数的那些快照**（`hasBillableMetrics`）。接入第一天全部失败时
    /// 库里照样有几条账期覆盖本月的快照，把它们算成「有读数」会让「全期间」
    /// 的起点落在一个从没读到过数的月份上，详情页的「—」也会变成 `$0`。
    private static func hasReading(
        snapshots: [Snapshot],
        daily: [Date: Money],
        monthStart: Date,
        asOf: Date,
        calendar: Calendar
    ) -> Bool {
        if daily.keys.contains(where: { $0 >= monthStart && $0 <= asOf }) { return true }
        return snapshots.contains {
            $0.hasBillableMetrics && $0.periodStart <= asOf && $0.periodEnd >= monthStart
        }
    }

    // MARK: - 月份

    /// 能回看的全部月份的月首，从老到新。
    public static func allMonthStarts(now: Date, calendar: Calendar) -> [Date] {
        guard
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        else {
            return []
        }
        return (0...DashboardPeriod.maxMonthsBack).reversed().compactMap { back in
            calendar.date(byAdding: .month, value: -back, to: thisMonthStart)
        }
    }

    /// 月首 → 「往前第几个月」。超出能回看的范围返回 nil。
    private static func monthsBack(from monthStart: Date, now: Date, calendar: Calendar) -> Int? {
        guard
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
            let back = calendar.dateComponents([.month], from: monthStart, to: thisMonthStart).month,
            back >= 0,
            back <= DashboardPeriod.maxMonthsBack
        else {
            return nil
        }
        return back
    }
}
