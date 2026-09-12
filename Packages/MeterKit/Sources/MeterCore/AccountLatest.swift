import Foundation

/// 一个账号**此刻**的状态。物化账本的第二种投影。
///
/// ## 为什么不能塞进月度账本
///
/// 「余额还剩多少」「免费额度用了几成」「下一笔什么时候扣」说的都是**现在**，
/// 不是八月。把它们折进按月的行，语义会当场变成谎——回看七月时那个余额是今天的。
/// 它们和 `MonthlyRollup` 的区别不是粒度，是**时态**。
///
/// ## 为什么它不是 Snapshot 的复制品
///
/// 两件事：
/// 1. **每账号只有一行。** 刷 200 次也是一行，这正是这一层要买的东西。
/// 2. **各字段各取各的最新。** 余额取最新一条 `.prepaid`，档位取最新一条
///    `.subscription` / `.planAndUsage`，免费额度取最新一条带比例的。
///    「哪一条算数」这条规则以前散在余额跑道、即将扣款、免费额度三处各写一遍，
///    现在只在折叠时判一次。
///
/// 所以它**窄于** `Snapshot`：不带账期、日粒度、多币种钱包——那些是历史，归 rollup；
/// 要原始读数的地方（详情页那几张图）走明确开的那个口，不走这里。
///
/// ## 准入准则（想加字段先过这三条）
///
/// 1. **是「此刻」的答案。**只要一个字段的正确性依赖「在看哪个月」，它就属于
///    `MonthlyRollup`，不属于这里。
/// 2. **不依赖 `now`。**这一行会**落盘**（`AccountLatestRecord`），而落盘的东西
///    一旦依赖「算它的时候几点」，它就会在某个说不清的时刻悄悄过期，
///    而屏幕上看不出来。判据是：`reduce` 的签名里不该出现 `now`——现在也确实没有。
/// 3. **是派生答案，不是原始字段。**`reportedAmountUSD` 是把「按 kind 该读哪个字段」
///    这条规则折成的一个数；把 `kind` / `currentSpendUSD` / `committedMonthlyUSD` /
///    账期五样都搬过来就是 `Snapshot` 的复制品，那条规则也会跟着多一个出处。
///    `kind` / `source` / `fetchedAt` 是**例外**：它们不是钱，是措辞和新鲜度的依据
///    （「取数失败」怎么说、「多久没刷了」）。
/// 4. **不许出现 `Snapshot` 里的结构体类型。**`ConvertedAmount` / `SpendLine` /
///    `[Date: Money]` 一进来，这一行就跟着 `Snapshot` 的形状走了——而它是**落盘**的，
///    形状定下来之后没人想动。只许标量：把结构体拆成用得上的那几个字段。
///    `balanceConverted` 曾经整个搬了过来，现在是 `balanceOriginalCurrency` +
///    `balanceUSDPerUnit` 两个标量。
///
/// 第 2 条是被 `reportedAmountUSD` 逼出来的：它曾经在这里就用 `now` 判过
/// 「手填的那笔算不算本月」，于是 8 月 31 日折出来的这一行，9 月 1 日起是错的。
/// 现在改成把**那笔钱记在哪个月**一起存下来，谁在看哪个月由读的人判。
public struct AccountLatest: Hashable, Sendable {
    public var accountID: AccountID
    public var providerID: ProviderID
    /// 最新那条读数的 kind。取数失败的措辞按它走。
    public var kind: ProviderKind
    /// 最新那条读数的时刻。「多久没刷了」看它。
    public var fetchedAt: Date
    /// 这条读数是怎么来的（API / 信箱 / 你自己填的）。列表副标题按它措辞。
    public var source: SnapshotSource

    /// 此刻的预充值余额。取自最新一条**带余额的** `.prepaid` 读数。
    public var balanceUSD: Money?
    /// 那笔余额的原币码。换算过的金额要能查——列表副标题在美元后面附原币。
    /// nil = 没换过币。**两个标量，不是 `ConvertedAmount`**：见准入准则第 4 条。
    public var balanceOriginalCurrency: String?
    /// 1 单位原币等于多少美元，厂商自己报的那个汇率。
    /// 原币金额由 `balanceUSD ÷ balanceUSDPerUnit` 还原——用厂商自己的汇率折回去，
    /// 而不是拿我们的汇率表折一遍（那才是会差一分的那条路）。
    public var balanceUSDPerUnit: Decimal?
    /// 免费额度已用比例。取自最新一条带比例的读数。
    public var freeQuotaUsedRatio: Double?
    /// 档位月费和扣款日。取自最新一条 `.subscription` / `.planAndUsage`。
    /// 「即将扣款」只认这两样都有的账号——不知道哪天扣就判断不了「即将」。
    public var committedMonthlyUSD: Money?
    public var chargeDayOfMonth: Int?

    /// 最新那条读数上**这家自己报的账单金额**。
    ///
    /// 服务列表的行首金额优先用折算出来的 fact；facts 给不出时用这个兜底。
    /// 折成一个字段而不是把 `kind` / `currentSpendUSD` / `committedMonthlyUSD` /
    /// `source` / 账期五样都搬过来——那样这一层就变成 `Snapshot` 的复制品了，
    /// 而"按 kind 该读哪个字段"这条规则也会跟着多一个出处。那条规则的唯一出处是
    /// `Snapshot.reportedBillingAmount`（就在 `hasBillableMetrics` 旁边），这里只存它的结果。
    ///
    /// 手填的读数记在哪个月。`nil` = 这笔金额没有月份归属（API 读数永远是「此刻」）。
    ///
    /// 手填花费可以是给上个月补的。以前这里直接拿 `now` 判「属不属于当月」，
    /// 判完只留一个 `Money?`——于是这一行落盘之后会在跨月那一刻悄悄变错。
    /// 现在把归属月一起存下来，「在看哪个月」由读的人（`ServiceRowBuilder`）判。
    public var reportedAmountMonth: MonthKey?
    public var reportedAmountUSD: Money?

    public init(
        accountID: AccountID,
        providerID: ProviderID,
        kind: ProviderKind,
        fetchedAt: Date,
        source: SnapshotSource = .api,
        balanceUSD: Money? = nil,
        balanceOriginalCurrency: String? = nil,
        balanceUSDPerUnit: Decimal? = nil,
        freeQuotaUsedRatio: Double? = nil,
        committedMonthlyUSD: Money? = nil,
        chargeDayOfMonth: Int? = nil,
        reportedAmountUSD: Money? = nil,
        reportedAmountMonth: MonthKey? = nil
    ) {
        self.accountID = accountID
        self.providerID = providerID
        self.kind = kind
        self.fetchedAt = fetchedAt
        self.source = source
        self.balanceUSD = balanceUSD
        self.balanceOriginalCurrency = balanceOriginalCurrency
        self.balanceUSDPerUnit = balanceUSDPerUnit
        self.freeQuotaUsedRatio = freeQuotaUsedRatio
        self.committedMonthlyUSD = committedMonthlyUSD
        self.chargeDayOfMonth = chargeDayOfMonth
        self.reportedAmountUSD = reportedAmountUSD
        self.reportedAmountMonth = reportedAmountMonth
    }

    /// 这笔「自己报的金额」在 `month` 那个月算不算数。
    ///
    /// 没有归属月（API 读数）就永远算数；有归属月（手填）只在那个月算数——
    /// 那笔钱记在别的月份上。
    public func reportedAmount(inMonth month: MonthKey) -> Money? {
        guard let reportedAmountMonth else { return reportedAmountUSD }
        return reportedAmountMonth == month ? reportedAmountUSD : nil
    }

    /// 把一个账号的全部读数归约成这一行。
    ///
    /// 每个字段各自挑「最新的那条**有这个字段**的读数」，而不是先挑一条读数再取字段：
    /// 一个账号可能同时报余额和档位，而它们未必来自同一次刷新。
    /// **签名里没有 `now`**，那是准入准则第 2 条的判据：这一行会落盘，
    /// 依赖「算它的时候几点」的东西会在某个说不清的时刻悄悄过期。
    public static func reduce(
        accountID: AccountID,
        snapshots: [Snapshot],
        calendar: Calendar
    ) -> AccountLatest? {
        let own = snapshots
            .filter { $0.accountID == accountID }
            .sorted { $0.fetchedAt < $1.fetchedAt }
        guard let newest = own.last, let oldest = own.first else { return nil }

        let balance = own.last { $0.kind == .prepaid && $0.balanceUSD != nil }
        // 档位取**最新一条 `.subscription` / `.planAndUsage`**，哪怕它没报档位。
        // 「最新一条带档位的」会让一个已经不报月费的账号继续预告扣款——
        // 那笔钱不会再扣了。余额那条相反：它本来就只在带余额的读数里出现。
        let plan = own.last { $0.kind == .subscription || $0.kind == .planAndUsage }
        let quota = own.last { $0.freeQuotaUsedRatio != nil }

        return AccountLatest(
            accountID: accountID,
            // **一个 accountID 只对一个厂商**（账号是按「厂商 + 凭据」建的），
            // 所以这里取哪一条都一样。取最老那条是为了和 `SnapshotGrouping.byAccount`
            // 的 `first.providerID` 完全一致——万一哪天不变量被破了，
            // 两条路至少还会给出同一个答案，而不是各说各话。
            providerID: oldest.providerID,
            kind: newest.kind,
            fetchedAt: newest.fetchedAt,
            source: newest.source,
            balanceUSD: balance?.balanceUSD,
            balanceOriginalCurrency: balance?.converted?.currency,
            balanceUSDPerUnit: balance?.converted?.usdPerUnit,
            freeQuotaUsedRatio: quota?.freeQuotaUsedRatio,
            committedMonthlyUSD: plan?.committedMonthlyUSD,
            chargeDayOfMonth: plan?.chargeDayOfMonth,
            reportedAmountUSD: newest.reportedBillingAmount,
            // 手填的读数才有归属月；API 读数永远是「此刻」。
            reportedAmountMonth: newest.source.isUserSupplied
                ? MonthKey(newest.periodStart, calendar: calendar)
                : nil
        )
    }

    /// 一批快照里每个账号各归约一行，按账号索引。
    ///
    /// 折叠、共享库、服务列表三处都要这一步；各写各的迟早会有一处漏掉
    /// 「各字段各取各的最新」那条规矩。
    public static func reduceAll(
        snapshots: [Snapshot],
        calendar: Calendar
    ) -> [AccountID: AccountLatest] {
        var out: [AccountID: AccountLatest] = [:]
        for accountID in Set(snapshots.compactMap(\.accountID)) {
            out[accountID] = reduce(
                accountID: accountID,
                snapshots: snapshots,
                calendar: calendar
            )
        }
        return out
    }
}
