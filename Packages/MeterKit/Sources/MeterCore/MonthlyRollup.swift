import Foundation

/// 一个账号在一个整月里的账。**物化账本的一行。**
///
/// ## 为什么要有这一层
///
/// `Snapshot` 是**观测记录**：每次刷新每家写一条，装的是那个账期累计花了多少。
/// 刷 200 次就有 200 行都在描述同一个八月——信息量没变，行数涨了 200 倍。
/// 于是「八月花了多少」的成本正比于**你在八月刷新了多少次**，而那两件事本来
/// 毫无关系。
///
/// 这一行是那 200 条压平之后的结果。压平只在**写入时**做一次，读的时候
/// 「近 3 个月」就是把 3 行加起来，和刷新次数彻底脱钩。
///
/// ## 它是缓存，不是真相
///
/// 唯一真相仍然是快照日志。这张表任何时候都能整份删掉、从日志重建，
/// 而且重建结果**必须**和全量重算逐项相同——`LedgerSelfCheck` 守这条。
/// 一旦两者能不一致，这个 App 最重要的那条价值观（宁可没有，不要半对）
/// 就在最不容易被发现的地方破了。
///
/// ## 为什么按 fact 类型分开存
///
/// 用量和预充值消耗都是「从量」，但构成条按类型分段、猫的台词也按类型措辞。
/// 并成一个 `variableUSD` 存下来省不了多少空间，却把段给弄丢了。
public struct MonthlyRollup: Hashable, Sendable {
    public var accountID: AccountID
    public var providerID: ProviderID
    /// 该月 1 号零点（按折叠时用的日历和时区）。行的主键之一。
    public var monthStart: Date

    /// `.monthToDateUsage`：按量计费那部分。
    public var usageUSD: Money
    /// `.prepaidConsumption`：预充值余额在这个月掉了多少。
    public var prepaidUSD: Money
    /// `.subscriptionIncluded` 里**来自 API** 的那部分（`committedMonthlyUSD`）。
    ///
    /// 手动录的订阅不在这里——那是规则不是观测，读的时候现算（见 `LedgerProjection`）。
    /// 「同账号有手动订阅时 API 那笔要让位」这条规则也留到读取时判：手动订阅随时
    /// 可以被编辑，折进账本就等于让一条**规则**的改动去失效一批**观测**的行。
    public var subscriptionUSD: Money
    /// 这个月这个账号的精度。合计取全部行的最差档。
    public var confidence: Confidence
    /// 进不进 `estimatedAccounts`（首屏那句「含估算」点谁的名）。
    public var isEstimated: Bool
    /// 这个月有没有过取数失败。
    public var didFailFetch: Bool

    /// **这个月有没有读数。**「没数据」和「$0」在这个 App 里是两件事，
    /// 所以没读数的月份也出一行，靠这个位分辨，而不是靠"查不到行"。
    public var hasReading: Bool

    /// 该月的日粒度花费，已经按「同一天后取覆盖先取」压平。
    ///
    /// 压平放在写入时做，正是这次改动最大的那笔收益：以前每次读都要把该账号
    /// 全部快照的日表合并一遍（实测占单月折算一半以上的时间），现在读的时候
    /// 这张表已经是最终形态，至多 31 条。
    ///
    /// 「上月同期」要按日截断，热力图要按日铺格——两处都从这里取，不再碰快照。
    public var dailyUSD: [Date: Money]

    /// 「上月同期」——这个月对上一个月**同一天为止**的那个数，按 fact 类型分开。
    ///
    /// 折叠时一并折出来，而不是读的时候从上一个月的行现推。理由和整套设计一样：
    /// 折叠跑的就是真正的折算器，同期的规则（用量按日截断、预充值按余额差、
    /// 订阅按账单口径全额）于是一个字都不用抄第二遍。
    ///
    /// 代价是**当月那一行跟着日期变**：今天是 17 号，它比的就是上个月 1–17 号。
    /// 所以 `foldedAsOf` 要一起存，隔天再打开时那一行得重折——`MonthlyLedgerStore`
    /// 的同步判据认这一条。过去的月份没有这个问题：它们的锚点是月末，比的是整月。
    public var comparisonUsageUSD: Money?
    public var comparisonPrepaidUSD: Money?
    public var comparisonSubscriptionUSD: Money?

    /// 折这一行时当作「此刻」的那个时间点。当月那一行靠它判要不要重折。
    public var foldedAsOf: Date

    /// 该月**每天最后一次观测到的预充值余额**。至多 31 条。
    ///
    /// 余额消耗不是日粒度的（它是两端余额之差，还要防充值把差压成负数），
    /// 所以存的是余额本身而不是消耗。「余额还能撑几天」要拿今天和 7 天前的两个
    /// 余额比，跨月时从相邻两行各取一段——这是它必须按日存、不能只存月末的原因。
    public var dailyBalanceUSD: [Date: Money]

    /// 该月的明细行（钱去了哪个类别）。
    ///
    /// 取的是**截止该月最后一瞬、最近一条带明细的读数**，和构成页原来的选法同一条。
    /// 明细天然不可加（它是"某一刻的构成"），所以不折不并，原样搬一份进来——
    /// 于是构成子行也不必再回头去翻快照。
    public var lines: [SpendLine]?
    /// 这份明细取自哪一刻。
    ///
    /// 「较上月同期」那一页要的是**落在同期窗口里**的明细，而 `lines` 本身是
    /// 「截止月末最近的一条」——可能来自更早的月份。多存这一个时刻，两种判据
    /// 才都说得出来，而不用为同期再存第二份明细。
    public var linesAt: Date?

    /// 折这一行时**产出过哪几类事实**。
    ///
    /// 存这个集合是因为「有没有这一条」和「金额是多少」是两件事：一条 $0 的
    /// 预充值消耗，说的是"这家有数、这个月没花"；没有那一条，说的是"这家没数"。
    /// 详情页正是靠这个分辨要不要显示「—」。
    ///
    /// 只按金额投影会把前者悄悄变成后者——数字全对，一整块界面消失。
    /// 这个坑踩过两次（免费额度、预充值），所以现在把它记进账本，而不是靠猜。
    public var producedFactKinds: Set<FactKind>

    /// 免费额度已用比例。**不是可加的历史**，是那个月代表读数上的一个瞬时值——
    /// 加起来会超过 100%。展示层只在窗口压着今天时才读它（现在时模块那条闸）。
    public var freeQuotaUsedRatio: Double?

    /// 该账号最新那条快照的 `kind`。取数失败的 fact 要按它措辞，
    /// 而账本行本身按 fact 类型分钱，两者不是一回事。
    public var latestKind: ProviderKind?

    /// 折这一行时，这个账号手上最新那条快照的 `fetchedAt`。
    /// 增量重折的判据：来了更新的快照，只有被它触及的月份需要重折。
    public var foldedThrough: Date

    public init(
        accountID: AccountID,
        providerID: ProviderID,
        monthStart: Date,
        usageUSD: Money = .zero,
        prepaidUSD: Money = .zero,
        subscriptionUSD: Money = .zero,
        confidence: Confidence = .exact,
        isEstimated: Bool = false,
        didFailFetch: Bool = false,
        hasReading: Bool = false,
        dailyUSD: [Date: Money] = [:],
        dailyBalanceUSD: [Date: Money] = [:],
        lines: [SpendLine]? = nil,
        linesAt: Date? = nil,
        producedFactKinds: Set<FactKind> = [],
        freeQuotaUsedRatio: Double? = nil,
        comparisonUsageUSD: Money? = nil,
        comparisonPrepaidUSD: Money? = nil,
        comparisonSubscriptionUSD: Money? = nil,
        foldedAsOf: Date = .distantPast,
        latestKind: ProviderKind? = nil,
        foldedThrough: Date = .distantPast
    ) {
        self.accountID = accountID
        self.providerID = providerID
        self.monthStart = monthStart
        self.usageUSD = usageUSD
        self.prepaidUSD = prepaidUSD
        self.subscriptionUSD = subscriptionUSD
        self.confidence = confidence
        self.isEstimated = isEstimated
        self.didFailFetch = didFailFetch
        self.hasReading = hasReading
        self.dailyUSD = dailyUSD
        self.dailyBalanceUSD = dailyBalanceUSD
        self.lines = lines
        self.linesAt = linesAt
        self.producedFactKinds = producedFactKinds
        self.freeQuotaUsedRatio = freeQuotaUsedRatio
        self.comparisonUsageUSD = comparisonUsageUSD
        self.comparisonPrepaidUSD = comparisonPrepaidUSD
        self.comparisonSubscriptionUSD = comparisonSubscriptionUSD
        self.foldedAsOf = foldedAsOf
        self.latestKind = latestKind
        self.foldedThrough = foldedThrough
    }

    /// 从量合计。和 `MonthToDate.variableUSD` 同一个口径。
    public var variableUSD: Money { usageUSD + prepaidUSD }

    /// 这一行有没有钱。空月份的行是有意义的（说明"折过了，那个月是 $0"），
    /// 但展示层多数时候只关心有钱的那些。
    public var isEmpty: Bool {
        usageUSD == .zero && prepaidUSD == .zero && subscriptionUSD == .zero
    }

    /// 行的身份：同一个账号同一个月只能有一行。
    public struct Key: Hashable, Sendable {
        public var accountID: AccountID
        public var monthStart: Date

        public init(accountID: AccountID, monthStart: Date) {
            self.accountID = accountID
            self.monthStart = monthStart
        }
    }

    public var key: Key { Key(accountID: accountID, monthStart: monthStart) }
}
