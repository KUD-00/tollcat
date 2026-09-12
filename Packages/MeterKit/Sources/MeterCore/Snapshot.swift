import Foundation

/// 一次刷新的原始读数；折算只看这些字段，才能和各家后台对账。
public struct Snapshot: Hashable, Sendable {
    public var providerID: ProviderID
    /// 适配器默认 `nil`。Features 盖章之后才许 persist / 进折算主路径。
    public var accountID: AccountID?
    public var kind: ProviderKind
    /// 谁取的这条数。默认 `.api`——只有走读数信箱那条路才需要显式传。
    public var source: SnapshotSource = .api
    /// 取到这条数的**那一刻**。真正的瞬间，落盘也是瞬间。
    public var fetchedAt: Date
    /// 账期起点在日历上的**那一天的零点**。
    ///
    /// **它是算出来的，不是存下来的。**落盘存的是年月日三个分量
    /// （`SnapshotRecord.periodStartDay`），读的时候按当前这本日历还原成零点。
    /// 存瞬间的话，东京写下的「8 月 1 日 00:00」在纽约日历上是 7 月 31 日 11:00，
    /// 于是八月那条快照会被判成「和七月有重叠」，`proratePeriodSpend` 把
    /// 八月至今的钱整笔摊进七月——两条读取路径走的是同一段代码，对账还照样通过。
    /// 理由同 `DayKey`。
    public var periodStart: Date
    /// 账期终点在日历上的那一天的零点。**含当天**——折算一律走
    /// `periodExclusiveEnd`（当天零点 + 1 天），所以这里不需要 23:59:59。
    /// 存法同 `periodStart`。
    public var periodEnd: Date
    public var currentSpendUSD: Money?
    public var balanceUSD: Money?
    public var committedMonthlyUSD: Money?
    public var chargeDayOfMonth: Int?
    public var freeQuotaUsedRatio: Double?
    public var dailyUSD: [Date: Money]?
    /// 厂商用非美元结算时，这里留着原币原值和当时用的汇率。
    ///
    /// 金额字段里存的**已经是换算后的美元**——换算在 provider 适配器那一层做完，
    /// 折算和图表一律不用关心币种。这一条只服务展示：详情页要能在大数字
    /// 下面写出「（1 CNY = $0.1404）」，并让这家进「哪几家是估的」名单。
    ///
    /// 多钱包时 `converted` 只在「换算部分等于 `balanceUSD`」时才填——落库会把
    /// `converted.usd` 写成余额合计，两槽都有钱就不能再用这一条。
    public var converted: ConvertedAmount?
    /// 预充值多币种钱包。账本仍只认 `balanceUSD`（各槽折美元之和）。
    public var wallets: [ConvertedAmount]?
    /// 本账期的明细：钱花在哪几个东西上。**只服务展示，不进折算。**
    ///
    /// 折算主路径一个字都不看这里——总数永远由 `currentSpendUSD` / `dailyUSD` 定，
    /// 明细合计和总数对不上是常态（厂商的税、结转、未归类项都不在明细里）。
    /// 详情页要显示"占比"时按明细自身的合计算，不要拿它去除总数。
    public var lines: [SpendLine]?

    public init(
        providerID: ProviderID,
        accountID: AccountID? = nil,
        kind: ProviderKind,
        source: SnapshotSource = .api,
        fetchedAt: Date,
        periodStart: Date,
        periodEnd: Date,
        currentSpendUSD: Money? = nil,
        balanceUSD: Money? = nil,
        committedMonthlyUSD: Money? = nil,
        chargeDayOfMonth: Int? = nil,
        freeQuotaUsedRatio: Double? = nil,
        dailyUSD: [Date: Money]? = nil,
        converted: ConvertedAmount? = nil,
        wallets: [ConvertedAmount]? = nil,
        lines: [SpendLine]? = nil
    ) {
        self.providerID = providerID
        self.accountID = accountID
        self.kind = kind
        self.source = source
        self.fetchedAt = fetchedAt
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.currentSpendUSD = currentSpendUSD
        self.balanceUSD = balanceUSD
        self.committedMonthlyUSD = committedMonthlyUSD
        self.chargeDayOfMonth = chargeDayOfMonth
        self.freeQuotaUsedRatio = freeQuotaUsedRatio
        self.dailyUSD = dailyUSD
        self.converted = converted
        self.wallets = wallets
        self.lines = lines
    }

    /// 这条读数是换算来的，不能当精确账单信。
    ///
    /// 空着的非美元槽也会出现在 `wallets` 里，但 `usd == 0` 没进合计，
    /// 不能据此把整家标成估算。
    public var isCurrencyConverted: Bool {
        if let converted, converted.isConverted, converted.usd != 0 { return true }
        return wallets?.contains { $0.isConverted && $0.usd != 0 } == true
    }

    /// 用户提供的本月至今只对 `periodStart` 那个月有效。跨月不能拿上月的数来摊。
    public func belongsToCalendarMonth(monthStart: Date, calendar: Calendar) -> Bool {
        calendar.isDate(periodStart, equalTo: monthStart, toGranularity: .month)
    }

    /// 一条该 kind 该有的字段全空的 Snapshot 代表「这家接了但这次没读到数」，不能当成 $0。
    /// 其它 kind 的字段即使有值也忽略，避免历史串种或误填造成双计。
    ///
    /// 公开 API：展示层必须用这一份，不许再抄一套（SPEC 第 12.5 节）。
    ///
    /// 和下面的 `reportedBillingAmount` 是**同一张 kind → 字段表的两问**：
    /// 「这一格有没有」和「这一格是多少」。两个 switch 并排放，加一种 kind 时
    /// 编译器会逼着两处一起改，而且改的时候看得见对方填了什么。
    public var hasBillableMetrics: Bool {
        switch kind {
        case .usage:
            return dailyUSD != nil || currentSpendUSD != nil
        case .prepaid:
            return balanceUSD != nil
        case .subscription:
            return committedMonthlyUSD != nil
        case .freeTier:
            return freeQuotaUsedRatio != nil
        case .planAndUsage:
            return committedMonthlyUSD != nil || dailyUSD != nil || currentSpendUSD != nil
        }
    }

    /// **这家自己报的账单金额**。按 kind 只认该认的字段，和 `hasBillableMetrics` 同一条规矩。
    ///
    /// 服务列表的行首金额优先用折算出来的 fact，facts 给不出时用这个兜底。
    /// 它住在这里而不是 `AccountLatest` 上，是为了让「按 kind 该读哪个字段」
    /// 只有一个出处——`AccountLatest` 只存这个函数的结果（见它的准入准则第 3 条）。
    ///
    /// **不看 `now`**：这笔钱记在哪个月由 `AccountLatest.reportedAmountMonth` 带着。
    public var reportedBillingAmount: Money? {
        switch kind {
        case .usage:
            return currentSpendUSD
        case .prepaid:
            // 行首是本月消耗。余额只出现在副标题，OpenRouter 这种纯钱包不能把剩额塞进来。
            return currentSpendUSD
        case .subscription:
            return committedMonthlyUSD
        case .freeTier:
            return nil
        case .planAndUsage:
            guard committedMonthlyUSD != nil || currentSpendUSD != nil else { return nil }
            return (committedMonthlyUSD ?? .zero) + (currentSpendUSD ?? .zero)
        }
    }
}
