import Foundation

/// **物化账本和全量重算的对账。**
///
/// 这是整个方案能不能信的唯一凭据，比任何一条单测都重要。
///
/// 预聚合最坏的失败方式不是慢，是「算出来的数和重算的不一样，而且看起来完全正常」。
/// 快照日志是唯一真相，账本只是它的一份压平——所以这两条路必须逐项相同，
/// 一旦能不同，这个 App 最在意的那条（宁可没有，不要半对）就在最不容易被发现的
/// 地方破了。
///
/// 用法：给一批快照和订阅，它自己折一遍账本、投影一遍、再全量重算一遍，
/// 把不一致列出来。开发页上有一个入口跑它；测试里跑随机账本。
public enum LedgerSelfCheck {
    public struct Discrepancy: Hashable, Sendable, CustomStringConvertible {
        public var field: String
        public var viaLedger: String
        public var viaRecompute: String

        public var description: String {
            "\(field): 账本 \(viaLedger) / 重算 \(viaRecompute)"
        }
    }

    /// 对一个取景框跑一次对账。**折和读用同一个 `now`**。
    public static func run(
        snapshots: [Snapshot],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        filter: DashboardFilter = .unfiltered,
        endedAccounts: [AccountID: Date] = [:]
    ) -> [Discrepancy] {
        run(
            snapshots: snapshots,
            subscriptions: subscriptions,
            foldNow: now,
            readNow: now,
            calendar: calendar,
            filter: filter,
            endedAccounts: endedAccounts
        )
    }

    /// **折叠时刻 ≠ 读取时刻**的那一版对账。
    ///
    /// 这才是生产上真实发生的事：账本行是某一刻折下来的，之后一直用到失效为止，
    /// 而失效的粒度是「天」。用同一个 `now` 折和读，永远抓不到「上午折的那一行，
    /// 下午读出来是错的」这一类漏——同期窗口就在这里分过一次家（见 `ComparisonWindow`）。
    ///
    /// 开发页那条对账用 `foldNow = 戳里那天的 09:00`、`readNow = 此刻`。
    public static func run(
        snapshots: [Snapshot],
        subscriptions: [MonthlySubscription],
        foldNow: Date,
        readNow: Date,
        calendar: Calendar,
        filter: DashboardFilter = .unfiltered,
        endedAccounts: [AccountID: Date] = [:]
    ) -> [Discrepancy] {
        let rollups = foldAll(
            snapshots: snapshots,
            now: foldNow,
            calendar: calendar,
            endedAccounts: endedAccounts
        )
        let viaLedger = LedgerProjection.compute(
            rollups: rollups,
            subscriptions: subscriptions,
            now: readNow,
            calendar: calendar,
            filter: filter
        )
        let viaRecompute = PeriodTotalCalculator.compute(
            snapshots: snapshots,
            subscriptions: subscriptions,
            now: readNow,
            calendar: calendar,
            filter: filter,
            endedAccounts: endedAccounts
        )
        return compare(ledger: viaLedger, recompute: viaRecompute)
    }

    /// 把全部账号折一遍。整库重建走它。
    public static func foldAll(
        snapshots: [Snapshot],
        now: Date,
        calendar: Calendar,
        endedAccounts: [AccountID: Date] = [:]
    ) -> [MonthlyRollup] {
        let accounts = OrderedAccountSet.ordered(from: snapshots.compactMap(\.accountID))
        return accounts.flatMap { accountID in
            LedgerFolder.fold(
                accountID: accountID,
                snapshots: snapshots,
                now: now,
                calendar: calendar,
                endedAccounts: endedAccounts
            )
        }
    }

    /// 逐项比。**同期也比**——它是账本最容易和重算悄悄分家的一处：
    /// 同期依赖"上个月到今天为止"，而账本里那一行是某一刻折出来的。
    public static func compare(ledger: MonthToDate, recompute: MonthToDate) -> [Discrepancy] {
        var out: [Discrepancy] = []
        func money(_ field: String, _ lhs: Money, _ rhs: Money) {
            guard lhs != rhs else { return }
            out.append(Discrepancy(field: field, viaLedger: "\(lhs.usd)", viaRecompute: "\(rhs.usd)"))
        }
        money("合计", ledger.totalUSD, recompute.totalUSD)
        money("从量", ledger.variableUSD, recompute.variableUSD)
        money("订阅", ledger.subscriptionUSD, recompute.subscriptionUSD)
        money("预计月底", ledger.projectedMonthEndUSD, recompute.projectedMonthEndUSD)
        money("外推从量", ledger.projectedVariableUSD, recompute.projectedVariableUSD)
        optionalMoney("整体同期", ledger.comparisonUSD, recompute.comparisonUSD, into: &out)
        if ledger.changeRatio != recompute.changeRatio {
            out.append(
                Discrepancy(
                    field: "涨跌幅",
                    viaLedger: ledger.changeRatio.map { "\($0)" } ?? "—",
                    viaRecompute: recompute.changeRatio.map { "\($0)" } ?? "—"
                )
            )
        }
        if ledger.comparisonWindow != recompute.comparisonWindow {
            out.append(
                Discrepancy(
                    field: "同期窗口",
                    viaLedger: ledger.comparisonWindow.map { "\($0.start)–\($0.end)" } ?? "—",
                    viaRecompute: recompute.comparisonWindow.map { "\($0.start)–\($0.end)" } ?? "—"
                )
            )
        }

        if ledger.confidence != recompute.confidence {
            out.append(
                Discrepancy(
                    field: "精度",
                    viaLedger: ledger.confidence.rawValue,
                    viaRecompute: recompute.confidence.rawValue
                )
            )
        }
        set("估算名单", Set(ledger.estimatedAccounts), Set(recompute.estimatedAccounts), into: &out)
        set(
            "订阅账号",
            Set(ledger.subscriptionAccountIDs),
            Set(recompute.subscriptionAccountIDs),
            into: &out
        )

        // 逐 (账号, 类型) 的金额。**缺一条和金额为 0 当成同一件事**：
        // 构成条上一段 $0 和没有那一段，画出来是一样的。
        // **先比「有哪几条」，再比金额。** 一条 $0 的事实和没有那一条，说的是
        // 「这家有数、这个月没花」和「这家没数」——数字一样，界面差一整块。
        let leftKeys = Set(ledger.facts.map { FactKey(accountID: $0.accountID, type: $0.type) })
        let rightKeys = Set(recompute.facts.map { FactKey(accountID: $0.accountID, type: $0.type) })
        for key in leftKeys.symmetricDifference(rightKeys).sorted(by: keyOrder) {
            out.append(
                Discrepancy(
                    field: "事实存在 \(label(key))",
                    viaLedger: leftKeys.contains(key) ? "有" : "无",
                    viaRecompute: rightKeys.contains(key) ? "有" : "无"
                )
            )
        }

        let left = amounts(ledger.facts)
        let right = amounts(recompute.facts)
        for key in Set(left.keys).union(right.keys).sorted(by: keyOrder) {
            let a = left[key] ?? .zero
            let b = right[key] ?? .zero
            guard a != b else { continue }
            out.append(
                Discrepancy(
                    field: "事实 \(label(key))",
                    viaLedger: "\(a.usd)",
                    viaRecompute: "\(b.usd)"
                )
            )
        }

        // 同期**不能把「没有」和「0」当成一回事**：nil 表示这一家还不能比，
        // 涨跌幅的分母里不该有它；0 表示上个月真的是 0。混起来涨幅会变成 +∞。
        let leftPrevious = comparisons(ledger.facts)
        let rightPrevious = comparisons(recompute.facts)
        for key in Set(leftPrevious.keys).union(rightPrevious.keys).sorted(by: keyOrder) {
            let a = leftPrevious[key] ?? nil
            let b = rightPrevious[key] ?? nil
            guard a != b else { continue }
            out.append(
                Discrepancy(
                    field: "同期 \(label(key))",
                    viaLedger: a.map { "\($0.usd)" } ?? "—",
                    viaRecompute: b.map { "\($0.usd)" } ?? "—"
                )
            )
        }
        // 免费额度那个比例。**必须单独比**：它的 `amountUSD` 是 0，
        // 上面按金额那一轮里「缺一条」和「金额为 0」是同一件事，
        // 于是整块免费额度模块消失也照样"对得上"。这条就是那么漏过一次的。
        let leftRatio = ratios(ledger.facts)
        let rightRatio = ratios(recompute.facts)
        for key in Set(leftRatio.keys).union(rightRatio.keys).sorted(by: keyOrder) {
            guard leftRatio[key] != rightRatio[key] else { continue }
            out.append(
                Discrepancy(
                    field: "免费额度 \(label(key))",
                    viaLedger: leftRatio[key].map { "\($0)" } ?? "—",
                    viaRecompute: rightRatio[key].map { "\($0)" } ?? "—"
                )
            )
        }
        return out
    }

    /// 余额跑道两条路对不对得上。判据是集合——两条路的账号顺序来源不同，
    /// 而顺序在这一块没有意义（展示层自己排）。
    public static func compareRunways(
        ledger: [PrepaidRunway],
        recompute: [PrepaidRunway]
    ) -> [Discrepancy] {
        guard Set(ledger) != Set(recompute) else { return [] }
        func render(_ runways: [PrepaidRunway]) -> String {
            runways
                .sorted { $0.accountID.rawValue.uuidString < $1.accountID.rawValue.uuidString }
                .map { "\($0.providerID.rawValue):\($0.balanceUSD.usd)/\($0.daysRemaining)天" }
                .joined(separator: " ")
        }
        return [
            Discrepancy(field: "余额跑道", viaLedger: render(ledger), viaRecompute: render(recompute))
        ]
    }

    /// 即将扣款两条路对不对得上。同样比集合。
    public static func compareCharges(
        ledger: [UpcomingCharge],
        recompute: [UpcomingCharge]
    ) -> [Discrepancy] {
        guard Set(ledger) != Set(recompute) else { return [] }
        func render(_ charges: [UpcomingCharge]) -> String {
            charges
                .map { "\($0.providerID?.rawValue ?? $0.name):\($0.amount.usd)@\($0.chargeDate)" }
                .sorted()
                .joined(separator: " ")
        }
        return [
            Discrepancy(field: "即将扣款", viaLedger: render(ledger), viaRecompute: render(recompute))
        ]
    }

    // MARK: -

    private struct FactKey: Hashable {
        var accountID: AccountID?
        var type: FactKind
    }

    private static func label(_ key: FactKey) -> String {
        "\(key.type.rawValue) @ \(key.accountID?.rawValue.uuidString.prefix(8) ?? "—")"
    }

    private static func optionalMoney(
        _ field: String,
        _ lhs: Money?,
        _ rhs: Money?,
        into out: inout [Discrepancy]
    ) {
        guard lhs != rhs else { return }
        out.append(
            Discrepancy(
                field: field,
                viaLedger: lhs.map { "\($0.usd)" } ?? "—",
                viaRecompute: rhs.map { "\($0.usd)" } ?? "—"
            )
        )
    }

    /// 同期按 (账号, 类型) 收。值是 `Money?`，外层那个 `?` 只表示"这一格出现过没有"。
    private static func comparisons(_ facts: [Fact]) -> [FactKey: Money?] {
        var out: [FactKey: Money?] = [:]
        for fact in facts {
            let key = FactKey(accountID: fact.accountID, type: fact.type)
            guard let previous = fact.comparisonUSD else {
                if out[key] == nil { out[key] = Money?.none }
                continue
            }
            out[key] = ((out[key] ?? nil) ?? .zero) + previous
        }
        return out
    }

    private static func ratios(_ facts: [Fact]) -> [FactKey: Double] {
        var out: [FactKey: Double] = [:]
        for fact in facts {
            guard let ratio = fact.freeQuotaUsedRatio else { continue }
            out[FactKey(accountID: fact.accountID, type: fact.type)] = ratio
        }
        return out
    }

    private static func amounts(_ facts: [Fact]) -> [FactKey: Money] {
        var out: [FactKey: Money] = [:]
        for fact in facts {
            guard let amount = fact.amountUSD else { continue }
            out[FactKey(accountID: fact.accountID, type: fact.type), default: .zero] += amount
        }
        return out
    }

    private static func keyOrder(_ lhs: FactKey, _ rhs: FactKey) -> Bool {
        let left = lhs.accountID?.rawValue.uuidString ?? ""
        let right = rhs.accountID?.rawValue.uuidString ?? ""
        if left != right { return left < right }
        return lhs.type.rawValue < rhs.type.rawValue
    }

    private static func set(
        _ field: String,
        _ lhs: Set<AccountID>,
        _ rhs: Set<AccountID>,
        into out: inout [Discrepancy]
    ) {
        guard lhs != rhs else { return }
        func render(_ ids: Set<AccountID>) -> String {
            ids.map { String($0.rawValue.uuidString.prefix(8)) }.sorted().joined(separator: ",")
        }
        out.append(Discrepancy(field: field, viaLedger: render(lhs), viaRecompute: render(rhs)))
    }
}

extension OrderedAccountSet {
    /// 保序去重成数组。
    static func ordered(from ids: [AccountID]) -> [AccountID] {
        var set = OrderedAccountSet()
        for id in ids { set.insert(id) }
        return set.ordered
    }
}
