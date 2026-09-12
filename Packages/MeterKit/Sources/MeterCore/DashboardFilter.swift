import Foundation

/// 仪表盘的取景框：**决定「看哪一部分」，不决定「数字准不准」。**
///
/// 这个区分是整个设计的支点。`Confidence` 说的是「这个数有多可信」——
/// 读数失败、按汇率折算过、只能按天摊，都会让它降级。筛选不是缺陷，是用户
/// 主动的选择，所以**筛选永远不改 `Confidence`**：把 AWS 排掉不该让总数
/// 降级成估算，那会把「我不想看它」和「它坏了」混成一件事。
///
/// 代价是筛选后的数字不再是「本月账单」，所以它必须**自己带着说明**：
/// `MonthToDate.filter` 把这份取景框原样带回结果里，展示层和分享卡都从
/// 那里读，没有哪一处能「忘了」加上限定语。
///
/// ## 时间区间为什么只有整月
///
/// 「近 7 天」这种窗口在这个数据模型里算不出诚实的数：
/// - 有日粒度的几家可以精确切（`dailyUSD`）；
/// - 只有周期累计的几家只能按天摊，本来就已经是 `.estimated`；
/// - 固定订阅**按月计费**，切成 7/30 是凭空编的数——月费不是日费。
///
/// 第三条是决定性的：只要窗口不是整月，订阅那部分就必须编。所以时间维度
/// 只提供整月（见 `DashboardPeriod`），而「不含订阅」单独做成一个开关——
/// 想只看从量的人按那个。
///
/// 守住整月还有一个不那么显眼的好处：**多月区间只是若干个单月结果的和**，
/// 每一项仍然走 `MonthToDateCalculator` 那条被测过的路（`PeriodTotalCalculator`），
/// 没有一处需要为「一段时间」重写折算，上面那条「筛选不改 Confidence」也
/// 因此在多月区间下自动继续成立。
public struct DashboardFilter: Hashable, Sendable {
    /// 往前最多翻 11 个月。定义在 `DashboardPeriod`——那才是它约束的东西。
    public static var maxMonthsBack: Int { DashboardPeriod.maxMonthsBack }

    /// 时间那一维。默认 `.months(back: 0, count: 1)` = 本月至今。
    public var period: DashboardPeriod
    /// 关掉之后，手动录的档位**和 API 报回来的 `committedMonthlyUSD` 一起**不计。
    /// 只关掉一边会让这个开关对 GitHub 这类「档位来自 API」的服务说谎。
    public var includesSubscriptions: Bool
    /// 用户显式排掉的账号。**新接入的账号默认在内**——
    /// 存「排除谁」而不是「包含谁」，就是为了让第 N 份不会悄悄看不见。
    public var excludedAccounts: Set<AccountID>

    public init(
        period: DashboardPeriod = .currentMonth,
        includesSubscriptions: Bool = true,
        excludedAccounts: Set<AccountID> = []
    ) {
        self.period = period.normalized
        self.includesSubscriptions = includesSubscriptions
        self.excludedAccounts = excludedAccounts
    }

    /// 单月的写法。调用点极多（测试、JNI 解码、旧偏好读盘），留着比全改一遍划算，
    /// 而且它读起来也确实是一句人话：「往前第 n 个月」。
    public init(
        monthsBack: Int,
        includesSubscriptions: Bool = true,
        excludedAccounts: Set<AccountID> = []
    ) {
        self.init(
            period: .months(back: monthsBack, count: 1),
            includesSubscriptions: includesSubscriptions,
            excludedAccounts: excludedAccounts
        )
    }

    public static let unfiltered = DashboardFilter()

    /// 窗口里最新的那个月往前几个月。折算锚点只由它决定。
    ///
    /// **写进去会把区间压成单月。** 只在「就是要换到某一个月」时用；
    /// 要改区间长度请直接给 `period`。
    public var monthsBack: Int {
        get { period.newestMonthsBack }
        set { period = .months(back: newValue, count: 1) }
    }

    /// 「筛选中」只看时间和排除名单。订阅口径**不算筛选**：它是首屏大数字旁
    /// 那颗一等公民切换，自己带着说明（算进时日期上面「（订阅 $X）」），
    /// 不该点亮工具栏的筛选图标、也不进限定语。
    public var isActive: Bool { !period.isCurrentMonth || !excludedAccounts.isEmpty }

    public var isCurrentMonth: Bool { period.isCurrentMonth }

    /// 只有当月才有「预计月底」可言：过去的月份已经结束，总数就是终值；
    /// 多月区间没有可推的东西。
    public var allowsProjection: Bool { period.allowsProjection }

    /// 余额告急、即将扣款这类「此刻」的模块，看的是窗口压不压着今天。
    ///
    /// 这里刻意**不是** `isCurrentMonth`：看「近 3 个月」时账户余额照样告急，
    /// 把它们藏起来是把「区间多长」和「说的是哪个时态」搞混了。
    public var showsPresentTenseModules: Bool { period.containsNow }

    /// 月度预算只在单个当月成立。拿一个月的预算去比三个月的花费没有意义。
    public var allowsMonthlyBudget: Bool { period.isCurrentMonth }

    /// 解析后的整月窗口。
    public func window(
        now: Date,
        calendar: Calendar,
        earliestMonthsBack: Int? = nil
    ) -> MonthWindow {
        period.window(now: now, calendar: calendar, earliestMonthsBack: earliestMonthsBack)
    }

    /// 把区间压成窗口里的某一个月。多月区间求和时逐月调它。
    public func singleMonth(back: Int) -> DashboardFilter {
        DashboardFilter(
            period: .months(back: back, count: 1),
            includesSubscriptions: includesSubscriptions,
            excludedAccounts: excludedAccounts
        )
    }

    // MARK: - 应用

    public func scope(_ snapshots: [Snapshot]) -> [Snapshot] {
        guard !excludedAccounts.isEmpty else { return snapshots }
        return snapshots.filter { snapshot in
            guard let id = snapshot.accountID else { return true }
            return !excludedAccounts.contains(id)
        }
    }

    /// 没挂到任何账号的手动订阅（`accountID == nil`）排不掉——
    /// 排除是按账号排的，无主的那笔没有可排的对象，留着。
    public func scope(_ subscriptions: [MonthlySubscription]) -> [MonthlySubscription] {
        guard !excludedAccounts.isEmpty else { return subscriptions }
        return subscriptions.filter { subscription in
            guard let id = subscription.accountID else { return true }
            return !excludedAccounts.contains(id)
        }
    }

    /// 折算时当作「此刻」的那个时间点，也就是**窗口的最后一瞬**。
    /// 实现在 `DashboardPeriod.anchor`：锚点只由时间那一维决定。
    public func anchor(now: Date, calendar: Calendar) -> Date {
        period.anchor(now: now, calendar: calendar)
    }

    // MARK: - 编辑

    public func excluding(_ id: AccountID) -> DashboardFilter {
        var copy = self
        copy.excludedAccounts.insert(id)
        return copy
    }

    public func including(_ id: AccountID) -> DashboardFilter {
        var copy = self
        copy.excludedAccounts.remove(id)
        return copy
    }

    public func includes(_ id: AccountID) -> Bool {
        !excludedAccounts.contains(id)
    }

    /// 已经不在接入列表里的账号从排除名单里清掉。
    ///
    /// 不清会留下一颗哑弹：删掉一份又重新接入，新 UUID 不在排除集里才对；
    /// 但旧 UUID 留着会让筛选摘要出现幽灵行。
    public func pruned(to connected: Set<AccountID>) -> DashboardFilter {
        var copy = self
        copy.excludedAccounts = excludedAccounts.intersection(connected)
        return copy
    }
}
