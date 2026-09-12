import Foundation

/// **读模型整份。** 仪表盘那一屏要的全部输入。
///
/// 这个类型存在的理由只有一个：让展示路径的签名里**说不出** `[Snapshot]`。
///
/// 闸能拦住手滑（文件名白名单扫到 `[Snapshot]` 就报），但拦不住设计上的偷懒——
/// 有人在门里加一个「把整条日志递出去」的方法，闸看不见。类型能：
/// `DashboardContentsBuilder.make(view:...)` 收的是这个，它没有一条路通到快照日志。
///
/// 三样东西对应三种时态，缺一不可：
/// - `rollups` —— 可加的历史（账号 × 月）。合计、趋势、构成、对比、热力图。
/// - `latest` —— 此刻的状态（账号一行）。余额跑道、免费额度、即将扣款。
/// - `subscriptions` —— **规则**，不是观测。可以被编辑，所以不折进账本，读时现算。
///
/// 要原始读数的地方（详情页那几张按日的图）不走这里，走门上另外那个明确开的口——
/// 开口和漏洞的区别在于：开口有名字、有测试、有理由写在注释里。
public struct LedgerView: Hashable, Sendable {
    public var rollups: [MonthlyRollup]
    public var latest: [AccountLatest]
    public var subscriptions: [MonthlySubscription]

    public init(
        rollups: [MonthlyRollup] = [],
        latest: [AccountLatest] = [],
        subscriptions: [MonthlySubscription] = []
    ) {
        self.rollups = rollups
        self.latest = latest
        self.subscriptions = subscriptions
    }

    public var isEmpty: Bool {
        rollups.isEmpty && latest.isEmpty && subscriptions.isEmpty
    }

    // MARK: - 派生查询
    //
    // 这几个是**问题的名字**。展示层问「按天的合计是多少」，而不是拿到日志自己去扫——
    // 那正是这一层要买的东西：谁都能加一块新模块，但加不出第二种"哪条读数算数"的规则。

    /// 按天的跨账号合计。热力图要这个。
    ///
    /// 账本行里的日表在折叠时已经按「同一天后取覆盖先取」压平过，所以这里
    /// 跨账号直接相加就对——不需要也不能再去重一次。
    ///
    /// **不按窗口筛**：这里假定表里的行本来就都在能回看的 12 个月内。合计那条路
    /// （`LedgerProjection.compute`）会自己按月首筛一遍，所以多几行不影响钱；
    /// 而这里多几行会直接多出一张月卡片。写侧负责不留掉出窗口的行，见
    /// `MonthlyLedgerStore.purgeRowsOutOfWindow`。
    public func dailyTotals() -> [Date: Money] {
        var totals: [Date: Money] = [:]
        for rollup in rollups {
            for (day, amount) in rollup.dailyUSD {
                totals[day, default: .zero] += amount
            }
        }
        return totals
    }

    /// 某个账号的按天花费。「我的服务」那条小折线要这个。
    public func dailySpend(for accountID: AccountID) -> [Date: Money] {
        var out: [Date: Money] = [:]
        for rollup in rollups where rollup.accountID == accountID {
            out.merge(rollup.dailyUSD) { _, new in new }
        }
        return out
    }

    /// 截止某一刻、每个账号最近的一份明细。
    ///
    /// - Parameter notBefore: 给了就要求明细**落在这段窗口里**。
    ///   「较上月同期」那一页要的是同期窗口内观测到的明细，不是"截止那时最近的一份"——
    ///   后者可能来自更早的月份，挂到同期那一栏就是张冠李戴。
    public func lines(
        onOrBefore deadline: Date,
        notBefore: Date? = nil
    ) -> [AccountID: [SpendLine]] {
        var best: [AccountID: (at: Date, lines: [SpendLine])] = [:]
        for rollup in rollups {
            guard let lines = rollup.lines, !lines.isEmpty, let at = rollup.linesAt else { continue }
            guard at <= deadline else { continue }
            if let notBefore, at < notBefore { continue }
            if let existing = best[rollup.accountID], existing.at >= at { continue }
            best[rollup.accountID] = (at, lines)
        }
        return best.mapValues(\.lines)
    }

    /// 手上这批读数里最近的一次是什么时候。设置页那行「上次刷新」看它。
    public var lastRefreshAt: Date? { latest.map(\.fetchedAt).max() }

    /// 按账号索引的此刻状态。服务列表逐行要它。
    public func latestByAccount() -> [AccountID: AccountLatest] {
        Dictionary(latest.map { ($0.accountID, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// 取景框筛过的一份。**在入口一次性折进去**，下游各 builder 一律只看筛过的。
    ///
    /// 和 `MonthToDateCalculator` 开头那三行遮蔽是同一个道理：让 body 里再也拿不到
    /// 没筛过的版本，"某一条分支漏判"就从一类 bug 变成不可能。
    public func scoped(to filter: DashboardFilter) -> LedgerView {
        guard !filter.excludedAccounts.isEmpty else { return self }
        return LedgerView(
            rollups: rollups.filter { filter.includes($0.accountID) },
            latest: latest.filter { filter.includes($0.accountID) },
            subscriptions: filter.scope(subscriptions)
        )
    }
}
