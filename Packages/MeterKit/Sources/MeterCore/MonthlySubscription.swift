import Foundation

/// 漏记订阅会让「本月总计」变成错的，所以它必须能进同一套折算。
///
/// `anchorDate` 对年付是首次或上次扣款日（取月+日）。月付只用来判断哪个月开始，不问几号。
/// 周年月看 anchor 自己的月份，不先按当月天数钳日再反推——否则 1 月 31 日
/// 的年付会在 2 月被当成周年，一年记十二次。
public struct MonthlySubscription: Hashable, Sendable {
    public var name: String
    public var amount: Money
    public var period: SubscriptionPeriod
    public var anchorDate: Date
    /// 退订那个月。**nil = 还在付**。
    ///
    /// 没有这个字段的时候，停掉的订阅只能删，而历史月份是拿当前订阅表现算的
    /// （`MonthSpendHistoryCalculator`），删一行等于把过去每个月里那笔钱一起抹掉——
    /// 真付过的钱在 App 里消失。所以「结束」和「删除」必须是两件事：
    /// 结束留住历史，删除才是「我根本录错了」。
    ///
    /// 和 `anchorDate` 一样只看年月，**结束月当月仍全额计入**：那个月的账单确实付了。
    public var endDate: Date?
    /// 归属 / 撞车。nil = 无主。删账号时置 nil。
    public var accountID: AccountID?
    /// 展示 / 目录。删账号时保留，glyph 还认得这家。
    public var providerID: ProviderID?
    /// 买了几份。**`amount` 始终是实际扣款总额**，不是单价——折算和扣款预测
    /// 只看 `amount`，所以加这个字段不影响任何计算。
    ///
    /// 它只服务展示和编辑：界面要说得出「Copilot Business ×3」，
    /// 用户改数量时也得知道单价是多少。
    public var quantity: Int

    public init(
        name: String,
        amount: Money,
        period: SubscriptionPeriod,
        anchorDate: Date,
        endDate: Date? = nil,
        accountID: AccountID? = nil,
        providerID: ProviderID? = nil,
        quantity: Int = 1
    ) {
        self.name = name
        self.amount = amount
        self.period = period
        self.anchorDate = anchorDate
        self.endDate = endDate
        self.accountID = accountID
        self.providerID = providerID
        self.quantity = max(1, quantity)
    }

    /// 单价。数量为 1 时就等于 `amount`。
    public var unitAmount: Money {
        guard quantity > 1 else { return amount }
        return Money(usd: amount.usd / Decimal(quantity))
    }

    /// 到 `date` 那个月为止，这笔订阅已经结束了吗。
    ///
    /// 结束月本身**不算结束**——那个月照样扣了钱。按日历月比，不比瞬时：
    /// 「8 月结束」在 8 月 1 日读也仍然是「还在付」。
    public func hasEnded(by date: Date, calendar: Calendar) -> Bool {
        guard let endDate else { return false }
        guard
            let endMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: endDate)),
            let month = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else {
            return false
        }
        return endMonth < month
    }

    /// 到 `date` 那个月为止，这笔订阅已经开始了吗。
    ///
    /// 必须按日历月比，不能写成 `date >= anchorDate`。总计是「本月这张账单」：
    /// 扣款日落在本月内就计全额，8 月 31 日才首扣的月付在 8 月 1 日仍应计入。
    /// 用瞬时比较会把它漏掉，账单口径就被改成现金口径。
    public func hasStarted(by date: Date, calendar: Calendar) -> Bool {
        guard
            let anchorMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: anchorDate)),
            let month = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else {
            return false
        }
        return anchorMonth <= month
    }

    /// `date` 那个月，这笔订阅算不算「在付」。**起点和终点两把闸都在这里。**
    ///
    /// 「这笔订阅这个月记多少钱」由 `MonthToDateCalculator.subscriptionAmount` 回答，
    /// 它自己就是照这两把闸判的；这个谓词服务的是另一类问题——**列不列、算不算数**：
    /// 仪表盘的固定订阅卡列哪几笔、手动录入该不该压住同一账号的 API 档位、
    /// 筛选面板里那个月份点不点得动。
    ///
    /// 它和金额分开是有意的：年付在非周年月金额是 $0，但那笔订阅**仍然在付**，
    /// 卡片上必须还在。拿 `amount > 0` 当「在不在」用会让年付每年只出现一个月。
    public func isActive(on date: Date, calendar: Calendar) -> Bool {
        hasStarted(by: date, calendar: calendar) && !hasEnded(by: date, calendar: calendar)
    }
}

extension Collection where Element == MonthlySubscription {
    /// `date` 那个月，哪几个账号的 API 档位要给手动录入让位。
    ///
    /// 手动录入是用户断言过的金额，同一账号 API 报回来的 `committedMonthlyUSD`
    /// 必须让位，否则两笔都进总数。**但只有那个月还在付的才有资格让位**——
    /// 漏掉这把闸的表现最难发现：手动那笔退掉之后，API 那笔被永远压住，
    /// 总数上凭空少一笔钱，而页面上哪里都不会说「少了」。
    ///
    /// 这个名单有四个调用点（本月合计、账本投影、趋势柱、即将扣款），
    /// 以前是四份各写各的字面量。收敛到这里是因为它们分家过一次：
    /// 只改其中一处，`LedgerSelfCheck` 会当场报「账本 X / 重算 Y」。
    ///
    /// `date` 是**那个月的锚点**，不是「此刻」——逐月投影时每个月各判一次，
    /// 中途退掉的订阅于是前半段让位、后半段不让。
    public func accountsSupersedingAPISubscriptions(
        on date: Date,
        calendar: Calendar
    ) -> Set<AccountID> {
        Set(lazy.filter { $0.isActive(on: date, calendar: calendar) }.compactMap(\.accountID))
    }
}
