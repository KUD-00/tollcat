import Foundation

/// 把各家四种「钱」折到同一个日历月。时间必须从外面传入，否则固定时钟测不了。
///
/// 预计月底（SPEC 第 12.5 节）：
/// - 订阅已按扣款日全额计入，不再外推。
/// - 用量与预充值消耗按「本月至今 ÷ 已过天数 × 当月天数」外推。
/// - 已过天数取 `now` 的日历日；1 号 00:00 视为 0，避免除以零。
/// - 当月天数由传入的 `calendar` 计算，不写死 30。
public enum MonthToDateCalculator {
    public static func compute(
        snapshots inputSnapshots: [Snapshot],
        subscriptions inputSubscriptions: [MonthlySubscription],
        now inputNow: Date,
        calendar: Calendar,
        filter: DashboardFilter = .unfiltered,
        endedAccounts: [AccountID: Date] = [:]
    ) -> MonthToDate {
        compute(
            snapshots: inputSnapshots,
            subscriptions: inputSubscriptions,
            now: inputNow,
            calendar: calendar,
            filter: filter,
            endedAccounts: endedAccounts,
            mergedDaily: nil
        )
    }

    /// 折叠那条路专用的入口：日表**已经合好了**，按账号索引。
    ///
    /// 折一个账号的 12 个月要调这个函数 12 次，而每一次里 `appendUsage` 和
    /// `usageComparison` 各自会把这个账号的整段日表重新合一遍——一次折叠于是合
    /// 1 + 24 遍，而 `LedgerFolder` 的注释写着「整段只合一次」。
    /// 把合好的那份传进来，公开签名一个字不改。
    ///
    /// 传进来的必须是**同一批快照**合出来的（`SnapshotDailyMap.merged`），
    /// 否则这里算出的钱和重算对不上——那种不一致看起来完全正常。
    static func compute(
        snapshots inputSnapshots: [Snapshot],
        subscriptions inputSubscriptions: [MonthlySubscription],
        now inputNow: Date,
        calendar: Calendar,
        filter: DashboardFilter,
        endedAccounts: [AccountID: Date],
        mergedDaily: [AccountID: [Date: Money]]?
    ) -> MonthToDate {
        // 取景框在**入口一次性**折进这三个值，函数体其余部分一个字都不用改。
        //
        // 这么写不只是省事：如果改成在下面各处判断 filter，任何一条分支漏判
        // 都会产出一个「部分应用了筛选」的数——那种数字比明显错的更危险。
        // 遮蔽掉原始入参之后，body 里再也拿不到未筛选的版本。
        let now = filter.anchor(now: inputNow, calendar: calendar)
        let snapshots = filter.scope(inputSnapshots)
        let subscriptions = filter.scope(inputSubscriptions)
        // 这里永远只算**一个月**。多月区间由 `PeriodTotalCalculator` 逐月调本函数
        // 再求和，所以窗口按锚点那个月记，不看 `filter.period` 有多长。
        let window = MonthWindow(
            newestBack: filter.period.newestMonthsBack,
            oldestBack: filter.period.newestMonthsBack
        )

        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return MonthToDate(
                totalUSD: .zero,
                projectedMonthEndUSD: .zero,
                confidence: .partial,
                estimatedAccounts: [],
                facts: [],
                filter: filter,
                window: window,
                variableUSD: .zero,
                projectedVariableUSD: .zero
            )
        }

        var variableTotal = Money.zero
        var includedSubscriptionTotal = Money.zero
        var observedSubscriptionTotal = Money.zero
        var subscriptionAccountIDs = OrderedAccountSet()
        var confidence = Confidence.exact
        var estimatedAccounts = OrderedAccountSet()
        var facts: [Fact] = []
        let comparisonWindow = ComparisonWindow.samePeriodLastMonth(now: now, calendar: calendar)
        let accountsWithManualSubscriptions = subscriptions
            .accountsSupersedingAPISubscriptions(on: now, calendar: calendar)

        let (groups, skippedUnstamped) = SnapshotGrouping.byAccount(snapshots)
        if skippedUnstamped {
            #if DEBUG
            preconditionFailure("unstamped Snapshot")
            #else
            confidence = confidence.merging(.partial)
            #endif
        }

        for group in groups {
            // 已经结束的接入：结束月之后不再产生本月账单，但历史月份照算。
            // 快照必须留着（否则过去几个月的柱子会跟着塌），所以闸只能设在这里；
            // 尤其是 `appendSubscription` 那条路一个月份闸都没有——不挡住的话，
            // 一份停掉的 GitHub 月费会照着最后一条快照永远续下去。
            if let endDate = endedAccounts[group.id],
               hasEndedBeforeCurrentMonth(endDate: endDate, now: now, calendar: calendar) {
                continue
            }
            let latest = group.ordered.last!
            // 回看过去某个月时（趋势、按月筛选），最新一条快照的账期可能整个落在
            // 目标月之后——按它去摊会把有数的月份算成 $0，而那个月自己的快照被
            // 无声跳过。先取「账期与 [monthStart, now] 有重叠」的最后一条（重叠
            // 判断与 usageComparison 同一把尺）；一条都不重叠再回落到最新，保住
            // 「只剩陈旧数据 → 本月至今 $0 + 降级」的现有语义。
            let source = group.ordered.last(where: { snapshot in
                snapshot.hasBillableMetrics
                    && snapshot.periodStart < now
                    && periodExclusiveEnd(snapshot.periodEnd, calendar: calendar) > monthStart
            }) ?? group.ordered.last(where: \.hasBillableMetrics)

            guard let source else {
                // 接了但没有任何可用读数：不记 $0，只把总数从「精确账单」里拿下来。
                confidence = confidence.merging(.partial)
                facts.append(
                    Fact(
                        providerID: group.providerID,
                        accountID: group.id,
                        kind: latest.kind,
                        amountUSD: nil,
                        confidence: .partial,
                        type: .fetchFailed
                    )
                )
                continue
            }

            let isStale = source.fetchedAt < latest.fetchedAt && !latest.hasBillableMetrics
            if isStale {
                confidence = confidence.merging(.partial)
            }

            // 换算过的读数按定义就不精确：汇率是几天前的，厂商实际按哪天的中间价
            // 结算我们不知道。总数降为估算，而且这家要出现在「哪几家是估的」里。
            if source.isCurrencyConverted {
                confidence = confidence.merging(.estimated)
                estimatedAccounts.insert(group.id)
            }

            // 按 kind 只认该认的字段。同一条 snapshot 填了多种钱也不双计。
            switch source.kind {
            case .usage:
                if source.source.isUserSupplied,
                   !source.belongsToCalendarMonth(monthStart: monthStart, calendar: calendar) {
                    confidence = confidence.merging(.partial)
                    continue
                }
                appendUsage(
                    source: source,
                    group: group,
                    mergedDaily: mergedDaily?[group.id],
                    monthStart: monthStart,
                    now: now,
                    calendar: calendar,
                    comparisonWindow: comparisonWindow,
                    variableTotal: &variableTotal,
                    confidence: &confidence,
                    estimatedAccounts: &estimatedAccounts,
                    facts: &facts
                )

            case .prepaid:
                let balanceHistory = group.ordered.filter { $0.kind == .prepaid && $0.balanceUSD != nil }
                if !balanceHistory.isEmpty {
                    let (amount, prepaidConfidence) = prepaidConsumption(
                        snapshots: balanceHistory,
                        monthStart: monthStart,
                        asOf: now
                    )
                    variableTotal += amount
                    confidence = confidence.merging(prepaidConfidence)
                    if prepaidConfidence == .estimated {
                        estimatedAccounts.insert(group.id)
                    }
                    let comparison = prepaidComparison(
                        snapshots: balanceHistory,
                        window: comparisonWindow
                    )
                    facts.append(
                        Fact(
                            providerID: group.providerID,
                            accountID: group.id,
                            kind: .prepaid,
                            amountUSD: amount,
                            comparisonUSD: comparison,
                            changeRatio: ChangeRatio.compute(current: amount, previous: comparison),
                            confidence: prepaidConfidence,
                            type: .prepaidConsumption
                        )
                    )
                }

            case .subscription:
                appendSubscription(
                    source: source,
                    group: group,
                    now: now,
                    calendar: calendar,
                    comparisonWindow: comparisonWindow,
                    accountsWithManualSubscriptions: accountsWithManualSubscriptions,
                    includesSubscriptions: filter.includesSubscriptions,
                    includedSubscriptionTotal: &includedSubscriptionTotal,
                    observedSubscriptionTotal: &observedSubscriptionTotal,
                    subscriptionAccountIDs: &subscriptionAccountIDs,
                    facts: &facts
                )

            case .freeTier:
                if let ratio = source.freeQuotaUsedRatio {
                    facts.append(
                        Fact(
                            providerID: group.providerID,
                            accountID: group.id,
                            kind: .freeTier,
                            amountUSD: .zero,
                            freeQuotaUsedRatio: ratio,
                            confidence: .exact,
                            type: .freeQuota
                        )
                    )
                }

            case .planAndUsage:
                if source.source.isUserSupplied,
                   !source.belongsToCalendarMonth(monthStart: monthStart, calendar: calendar) {
                    confidence = confidence.merging(.partial)
                } else {
                    appendUsage(
                        source: source,
                        group: group,
                        mergedDaily: mergedDaily?[group.id],
                        monthStart: monthStart,
                        now: now,
                        calendar: calendar,
                        comparisonWindow: comparisonWindow,
                        variableTotal: &variableTotal,
                        confidence: &confidence,
                        estimatedAccounts: &estimatedAccounts,
                        facts: &facts
                    )
                }
                appendSubscription(
                    source: source,
                    group: group,
                    now: now,
                    calendar: calendar,
                    comparisonWindow: comparisonWindow,
                    accountsWithManualSubscriptions: accountsWithManualSubscriptions,
                    includesSubscriptions: filter.includesSubscriptions,
                    includedSubscriptionTotal: &includedSubscriptionTotal,
                    observedSubscriptionTotal: &observedSubscriptionTotal,
                    subscriptionAccountIDs: &subscriptionAccountIDs,
                    facts: &facts
                )
            }
        }

        // 订阅金额始终算出来，给仪表那行「本月订阅」。
        // 关掉开关时不进 total、不进 facts：构成条和分享卡都从 fact 读，
        // 留着 `.subscriptionIncluded` 会让饼图里那一块还在。
        for subscription in subscriptions {
            let amount = subscriptionAmount(subscription, now: now, calendar: calendar)
            observedSubscriptionTotal += amount
            // 只有还在付的才把账号记进来。这串 ID 是「本月订阅」那行旁边挂的那几个
            // glyph，退掉之后不该继续挂着——那会让一个 $0 的贡献者看起来还在出钱。
            // 不能改判 `amount > 0`：年付在非周年月是 $0，但它确实还在付。
            if let accountID = subscription.accountID,
               subscription.isActive(on: now, calendar: calendar) {
                subscriptionAccountIDs.insert(accountID)
            }
            guard filter.includesSubscriptions else { continue }
            includedSubscriptionTotal += amount
            let comparison = subscriptionComparison(
                subscription,
                window: comparisonWindow,
                calendar: calendar
            )
            facts.append(
                Fact(
                    providerID: subscription.providerID,
                    accountID: subscription.accountID,
                    kind: .subscription,
                    amountUSD: amount,
                    comparisonUSD: comparison,
                    changeRatio: ChangeRatio.compute(current: amount, previous: comparison),
                    confidence: .exact,
                    type: .subscriptionIncluded
                )
            )
        }

        let variable = variableTotal.roundedToCents()
        let observedSubscription = observedSubscriptionTotal.roundedToCents()
        let includedSubscription = includedSubscriptionTotal.roundedToCents()
        let projectedVariable = projectVariable(variableTotal, now: now, calendar: calendar)
            .roundedToCents()
        let (overallComparison, overallRatio) = overallComparison(from: facts)

        return MonthToDate(
            totalUSD: (variable + includedSubscription).roundedToCents(),
            projectedMonthEndUSD: (projectedVariable + includedSubscription).roundedToCents(),
            confidence: confidence,
            estimatedAccounts: estimatedAccounts.ordered,
            facts: facts,
            comparisonUSD: overallComparison,
            changeRatio: overallRatio,
            comparisonWindow: comparisonWindow,
            filter: filter,
            window: window,
            variableUSD: variable,
            subscriptionUSD: observedSubscription,
            projectedVariableUSD: projectedVariable,
            subscriptionAccountIDs: subscriptionAccountIDs.ordered
        )
    }

    private static func appendUsage(
        source: Snapshot,
        group: AccountSnapshots,
        /// 已经合好的日表；nil 就现合。见 `compute(…mergedDaily:)`。
        mergedDaily: [Date: Money]?,
        monthStart: Date,
        now: Date,
        calendar: Calendar,
        comparisonWindow: ComparisonWindow?,
        variableTotal: inout Money,
        confidence: inout Confidence,
        estimatedAccounts: inout OrderedAccountSet,
        facts: inout [Fact]
    ) {
        let daily = mergedDaily ?? SnapshotDailyMap.merged(from: group.ordered, calendar: calendar)
        let hasWindowDays = daily.keys.contains { day in
            day >= monthStart && day < now
        }
        if hasWindowDays {
            let amount = sumDaily(daily, monthStart: monthStart, now: now, calendar: calendar)
            variableTotal += amount
            let comparison = usageComparison(
                snapshots: group.ordered,
                mergedDaily: daily,
                window: comparisonWindow,
                calendar: calendar
            )
            facts.append(
                Fact(
                    providerID: group.providerID,
                    accountID: group.id,
                    kind: .usage,
                    amountUSD: amount,
                    comparisonUSD: comparison,
                    changeRatio: ChangeRatio.compute(current: amount, previous: comparison),
                    confidence: .exact,
                    type: .monthToDateUsage
                )
            )
        } else if let spend = source.currentSpendUSD {
            let amount = proratePeriodSpend(
                spend,
                periodStart: source.periodStart,
                periodEnd: source.periodEnd,
                monthStart: monthStart,
                now: now,
                calendar: calendar
            )
            variableTotal += amount
            confidence = confidence.merging(.estimated)
            estimatedAccounts.insert(group.id)
            let comparison = usageComparison(
                snapshots: group.ordered,
                mergedDaily: daily,
                window: comparisonWindow,
                calendar: calendar
            )
            facts.append(
                Fact(
                    providerID: group.providerID,
                    accountID: group.id,
                    kind: .usage,
                    amountUSD: amount,
                    comparisonUSD: comparison,
                    changeRatio: ChangeRatio.compute(current: amount, previous: comparison),
                    confidence: .estimated,
                    type: .monthToDateUsage
                )
            )
        }
    }

    private static func appendSubscription(
        source: Snapshot,
        group: AccountSnapshots,
        now: Date,
        calendar: Calendar,
        comparisonWindow: ComparisonWindow?,
        accountsWithManualSubscriptions: Set<AccountID>,
        includesSubscriptions: Bool,
        includedSubscriptionTotal: inout Money,
        observedSubscriptionTotal: inout Money,
        subscriptionAccountIDs: inout OrderedAccountSet,
        facts: inout [Fact]
    ) {
        // API 报回来的档位和手动录的档位一起受这个开关管。只关一边，
        // 这个开关就会对「档位来自 API」的那几家（GitHub、Grafana…）说谎。
        guard let committed = source.committedMonthlyUSD else { return }
        if accountsWithManualSubscriptions.contains(group.id) {
            if includesSubscriptions {
                facts.append(
                    Fact(
                        providerID: group.providerID,
                        accountID: group.id,
                        kind: .subscription,
                        amountUSD: committed,
                        confidence: .exact,
                        type: .subscriptionSuperseded
                    )
                )
            }
            return
        }
        let amount = subscriptionAmount(committed, chargeDayOfMonth: source.chargeDayOfMonth)
        observedSubscriptionTotal += amount
        subscriptionAccountIDs.insert(group.id)
        guard includesSubscriptions else { return }
        includedSubscriptionTotal += amount
        let comparison = subscriptionComparisonAmount(
            committed,
            chargeDayOfMonth: source.chargeDayOfMonth,
            window: comparisonWindow
        )
        facts.append(
            Fact(
                providerID: group.providerID,
                accountID: group.id,
                kind: .subscription,
                amountUSD: amount,
                comparisonUSD: comparison,
                changeRatio: ChangeRatio.compute(current: amount, previous: comparison),
                confidence: .exact,
                type: .subscriptionIncluded
            )
        )
    }

    // MARK: - 用量

    /// 日粒度按日历日归属本月；`now` 正好落在某日 00:00 时该日尚未开始，不计入。
    private static func sumDaily(
        _ daily: [Date: Money],
        monthStart: Date,
        now: Date,
        calendar: Calendar
    ) -> Money {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return .zero
        }
        return daily.reduce(into: .zero) { sum, entry in
            let day = calendar.startOfDay(for: entry.key)
            guard day >= monthStart, day < nextMonth, day < now else { return }
            sum += entry.value
        }
    }

    /// 「本周期至今」按周期内已过日历日线性摊到本月。没有日粒度，只能估算。
    private static func proratePeriodSpend(
        _ spend: Money,
        periodStart: Date,
        periodEnd: Date,
        monthStart: Date,
        now: Date,
        calendar: Calendar
    ) -> Money {
        let bound = min(now, periodExclusiveEnd(periodEnd, calendar: calendar))
        let start = calendar.startOfDay(for: periodStart)
        let periodDays = daysCount(from: start, before: bound, calendar: calendar)
        guard periodDays > 0 else { return .zero }

        let monthDays = daysCount(from: max(start, monthStart), before: bound, calendar: calendar)
        let ratio = Decimal(monthDays) / Decimal(periodDays)
        return spend * ratio
    }

    /// 完整账期的账单（发票）按窗口覆盖的天数切开。
    /// `proratePeriodSpend` 假定金额是「截至 now 的累计」，会把整月发票当成同期。
    private static func prorateCompletedPeriod(
        _ spend: Money,
        periodStart: Date,
        periodEnd: Date,
        window: ComparisonWindow,
        calendar: Calendar
    ) -> Money? {
        let start = calendar.startOfDay(for: periodStart)
        let periodEndExclusive = periodExclusiveEnd(periodEnd, calendar: calendar)
        let periodDays = daysCount(from: start, before: periodEndExclusive, calendar: calendar)
        guard periodDays > 0 else { return nil }
        let overlapStart = max(start, window.start)
        let overlapEnd = min(periodEndExclusive, window.end)
        let windowDays = daysCount(from: overlapStart, before: overlapEnd, calendar: calendar)
        guard windowDays > 0 else { return nil }
        return spend * Decimal(windowDays) / Decimal(periodDays)
    }

    // MARK: - 预充值

    /// 预充值这个月消耗了多少。
    ///
    /// **逐段做差再求和**，不是「月初余额 − 现在余额」。中途充一次值，
    /// 后者会把这个月已经花掉的钱一笔勾销——充到比月初还高就直接报 $0，
    /// 而 confidence 还写着 exact。那是「数字看起来完全正常」的那一类错。
    ///
    /// 每两次相邻观测之间：跌了就是花了，涨了就是充值、这一段计 0
    /// （不是负数——充值不是负消费）。
    ///
    /// 有月初（或更早）余额才是完整月份；否则只能报接入以来的消耗。
    /// `asOf` 限制「当前」读数，算上月同期时不能把本月余额当成上个月末。
    ///
    /// 见过充值就降为 `.partial`：两次观测之间「先花 $50 再充 $100」我们只看得见
    /// 净涨 $50，那 $50 的消耗永远补不回来。这时候的总数是**下限**，不是准数。
    private static func prepaidConsumption(
        snapshots: [Snapshot],
        monthStart: Date,
        asOf: Date
    ) -> (Money, Confidence) {
        let relevant = snapshots
            .filter { $0.fetchedAt <= asOf && $0.balanceUSD != nil }
            .sorted { $0.fetchedAt < $1.fetchedAt }
        guard !relevant.isEmpty else { return (.zero, .partial) }

        let anchor: Int
        var confidence: Confidence
        if let index = relevant.lastIndex(where: { $0.fetchedAt <= monthStart }) {
            anchor = index
            confidence = .exact
        } else {
            anchor = relevant.startIndex
            confidence = .partial
        }

        var consumed = Money.zero
        var previous = relevant[anchor].balanceUSD ?? .zero
        var sawTopUp = false
        for snapshot in relevant[relevant.index(after: anchor)...] {
            guard let balance = snapshot.balanceUSD else { continue }
            if balance > previous {
                sawTopUp = true
            } else {
                consumed += previous - balance
            }
            previous = balance
        }
        if sawTopUp {
            confidence = confidence.merging(.partial)
        }
        return (consumed, confidence)
    }

    // MARK: - 订阅

    /// Snapshot 只有日。缺省日按当月全额；1...31 的扣款日钳到月末后必落本月，全额计入；非法日记 0。
    private static func subscriptionAmount(_ amount: Money, chargeDayOfMonth: Int?) -> Money {
        guard let chargeDay = chargeDayOfMonth else { return amount }
        return (1...31).contains(chargeDay) ? amount : .zero
    }

    /// 月付只取年月：开始月及之后每个日历月全额计入，不问几号。
    /// 年付取月+日，只有周年月计入全额。
    ///
    /// 起点和终点两把闸必须对称，而且只能有一份实现——`MonthlySubscription.isActive(on:calendar:)`。
    /// 只有起点时，退掉的订阅会一直扣到世界末日，用户唯一能做的是删——
    /// 而删会把过去每个月里那笔钱一起改写掉。
    ///
    /// public：仪表盘详情页的子行要按订阅逐笔标金额，必须和这里算出同一个数，
    /// 否则子行加起来对不上段合计。这是「这笔订阅本月记多少」的唯一出处。
    public static func subscriptionAmount(
        _ subscription: MonthlySubscription,
        now: Date,
        calendar: Calendar
    ) -> Money {
        guard subscription.isActive(on: now, calendar: calendar) else { return .zero }
        switch subscription.period {
        case .monthly:
            let chargeDay = calendar.component(.day, from: subscription.anchorDate)
            return subscriptionAmount(subscription.amount, chargeDayOfMonth: chargeDay)
        case .annual:
            guard isAnniversaryMonth(anchorDate: subscription.anchorDate, now: now, calendar: calendar) else {
                return .zero
            }
            return subscription.amount
        }
    }

    /// 这份接入在本月之前就结束了吗。和 `MonthlySubscription.hasStarted(by:calendar:)` 对称：
    /// 结束月当月仍算数（那个月确实出了账单），下一个月起归零。
    private static func hasEndedBeforeCurrentMonth(
        endDate: Date,
        now: Date,
        calendar: Calendar
    ) -> Bool {
        guard
            let endMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: endDate)),
            let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        else {
            return false
        }
        return endMonth < currentMonth
    }

    /// 周年月用 anchor 的月份分量，不把日钳进「当前月」再反推。
    /// 1 月 31 日钳到 2 月 28 日会让每个 2 月都变成周年；2 月 29 日在平年仍是 2 月。
    private static func isAnniversaryMonth(
        anchorDate: Date,
        now: Date,
        calendar: Calendar
    ) -> Bool {
        calendar.component(.month, from: anchorDate) == calendar.component(.month, from: now)
    }

    // MARK: - 上月同期

    /// 先看窗口里的日粒度；没有日粒度再用上月那条周期累计摊。
    /// 当前月 snapshot 的周期对不上窗口时返回 nil，不能把本月 $21.40 当成上月。
    /// 日表走 `SnapshotDailyMap`：同一天多次刷新后取覆盖，不加总。
    private static func usageComparison(
        snapshots: [Snapshot],
        /// 已经合好的日表；nil 就现合。和 `appendUsage` 拿的是同一份。
        mergedDaily: [Date: Money]?,
        window: ComparisonWindow?,
        calendar: Calendar
    ) -> Money? {
        guard let window else { return nil }

        let daily = mergedDaily ?? SnapshotDailyMap.merged(from: snapshots, calendar: calendar)
        let hasWindowDays = daily.keys.contains { day in
            day >= window.start && day < window.end
        }
        if hasWindowDays {
            return sumDaily(daily, monthStart: window.start, now: window.end, calendar: calendar)
        }

        let overlapping = snapshots.filter { snapshot in
            snapshot.kind.contributesUsageComparison
                && snapshot.currentSpendUSD != nil
                && snapshot.periodStart < window.end
                && periodExclusiveEnd(snapshot.periodEnd, calendar: calendar) > window.start
        }
        // 窗口内取到的累计：金额就是「截至那天」的数。取数晚于窗口的本月累计
        // 不能走这条——那会把八月的 MTD 当成七月同期。
        if let source = overlapping.last(where: { $0.fetchedAt <= window.end }),
           let spend = source.currentSpendUSD {
            return proratePeriodSpend(
                spend,
                periodStart: source.periodStart,
                periodEnd: source.periodEnd,
                monthStart: window.start,
                now: window.end,
                calendar: calendar
            )
        }

        // 账期整个落在对比月、取数却晚于窗口：是上个月自己的账单
        // （七月发票八月才刷到）。筛选能看见上月，同期却不能拿整月当同期，
        // 按账期天数线性切到窗口。
        guard
            let comparisonMonthEnd = calendar.date(byAdding: .month, value: 1, to: window.start),
            let source = overlapping.last(where: { snapshot in
                periodExclusiveEnd(snapshot.periodEnd, calendar: calendar) <= comparisonMonthEnd
            }),
            let spend = source.currentSpendUSD
        else {
            return nil
        }
        return prorateCompletedPeriod(
            spend,
            periodStart: source.periodStart,
            periodEnd: source.periodEnd,
            window: window,
            calendar: calendar
        )
    }

    private static func prepaidComparison(
        snapshots: [Snapshot],
        window: ComparisonWindow?
    ) -> Money? {
        guard let window else { return nil }
        let prepaid = snapshots.filter { $0.kind == .prepaid && $0.balanceUSD != nil }
        guard
            prepaid.contains(where: { $0.fetchedAt <= window.start }),
            prepaid.contains(where: { $0.fetchedAt <= window.end })
        else {
            return nil
        }
        let (amount, _) = prepaidConsumption(
            snapshots: prepaid,
            monthStart: window.start,
            asOf: window.end
        )
        return amount
    }

    /// 同期的订阅和本月同一把尺：**账单口径**，扣款日落在那个月内就计全额。
    ///
    /// 以前这里按「扣款日 ≤ 上月的今天」现金口径记 0，而本月那边是账单口径
    /// 全额（见 `subscriptionAmount`）——分子账单、分母现金，25 号扣款的订阅
    /// 会让每月 1–24 号的「较上月同期」凭空多出一段涨幅，到扣款日才归位。
    private static func subscriptionComparisonAmount(
        _ amount: Money,
        chargeDayOfMonth: Int?,
        window: ComparisonWindow?
    ) -> Money? {
        guard window != nil else { return nil }
        return subscriptionAmount(amount, chargeDayOfMonth: chargeDayOfMonth)
    }

    private static func subscriptionComparison(
        _ subscription: MonthlySubscription,
        window: ComparisonWindow?,
        calendar: Calendar
    ) -> Money? {
        guard let window else { return nil }
        // 上个月还在付、这个月退了：同期要算出上个月那一笔，涨跌幅才说得出「少了 $20」。
        // 起点那把闸同样要按同期窗口判，不是按此刻。
        guard subscription.isActive(on: window.end, calendar: calendar) else { return .zero }
        switch subscription.period {
        case .monthly:
            let chargeDay = calendar.component(.day, from: subscription.anchorDate)
            return subscriptionComparisonAmount(
                subscription.amount,
                chargeDayOfMonth: chargeDay,
                window: window
            )
        case .annual:
            guard calendar.component(.month, from: subscription.anchorDate)
                == calendar.component(.month, from: window.start)
            else {
                return .zero
            }
            return subscription.amount
        }
    }

    /// 聚合规则在 `FactComparisonAggregate`：本月全进，上月只加能比的。
    private static func overallComparison(from facts: [Fact]) -> (Money?, Double?) {
        let kinds = Set(FactKind.allCases.filter(\.contributesToTotal))
        guard let totals = FactComparisonAggregate.totals(facts: facts, including: kinds) else {
            return (nil, nil)
        }
        return (totals.previous, ChangeRatio.compute(current: totals.current, previous: totals.previous))
    }

    private static func periodExclusiveEnd(_ periodEnd: Date, calendar: Calendar) -> Date {
        calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: periodEnd)
        ) ?? periodEnd
    }

    // MARK: - 预计月底

    /// 外推实现搬去了 `MonthProjection`——读物化账本那条路也要用同一份。
    private static func projectVariable(
        _ variableTotal: Money,
        now: Date,
        calendar: Calendar
    ) -> Money {
        MonthProjection.extrapolate(variableTotal, now: now, calendar: calendar)
    }

    private static func elapsedDays(now: Date, calendar: Calendar) -> Int {
        MonthProjection.elapsedDays(now: now, calendar: calendar)
    }

    // MARK: - 日历

    /// 数日历日：从 `startOfDay`（当日零点）起，每个落在 `end` 之前的零点算一天。
    private static func daysCount(from startOfDay: Date, before end: Date, calendar: Calendar) -> Int {
        guard end > startOfDay else { return 0 }
        let whole = calendar.dateComponents([.day], from: startOfDay, to: end).day ?? 0
        guard let boundary = calendar.date(byAdding: .day, value: whole, to: startOfDay) else {
            return whole
        }
        return end > boundary ? whole + 1 : whole
    }
}
