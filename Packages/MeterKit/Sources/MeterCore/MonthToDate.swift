import Foundation

/// 首页大数字：本月 1 号到此刻的合计，以及它有多可信。
public struct MonthToDate: Hashable, Sendable {
    public var totalUSD: Money
    public var projectedMonthEndUSD: Money
    /// 从量：用量 + 预充值消耗 + 超额。仪表主角数字只看这个。
    public var variableUSD: Money
    /// 本月订阅（手动档位 + API 月费）。筛掉订阅时这里仍有数，方便单独那一行。
    public var subscriptionUSD: Money
    /// 从量外推到月底。订阅不进这里——订阅按扣款日全额，没有可推的。
    public var projectedVariableUSD: Money
    /// 本月订阅挂到的账号。0 或 2 个以上时首屏那一行不给跳转。
    public var subscriptionAccountIDs: [AccountID]
    public var confidence: Confidence
    public var estimatedAccounts: [AccountID]
    public var facts: [Fact]
    public var comparisonUSD: Money?
    public var changeRatio: Double?
    public var comparisonWindow: ComparisonWindow?
    /// 算出这个数时用的取景框。
    ///
    /// 结果**自带**它，而不是让展示层各自记住自己传了什么：筛选过的数字
    /// 不再是「本月账单」，任何要把它画出来的地方都必须能拿到限定语。
    /// 放在这里，「忘了标注」就从一类 bug 变成了不可能。
    public var filter: DashboardFilter
    /// 取景框解析出来的那段整月窗口。
    ///
    /// `filter.period` 存的是**意图**（「有数据以来」「今年至今」），有多长要看数据和
    /// 日历才知道；标题、分享卡、限定语要的是**结果**。两者分开存，展示层才不必
    /// 各自再解析一遍——而只要有一处解析得不一样，屏幕上就会出现两个互相矛盾的期间。
    public var window: MonthWindow

    public init(
        totalUSD: Money,
        projectedMonthEndUSD: Money,
        confidence: Confidence,
        estimatedAccounts: [AccountID],
        facts: [Fact],
        comparisonUSD: Money? = nil,
        changeRatio: Double? = nil,
        comparisonWindow: ComparisonWindow? = nil,
        filter: DashboardFilter = .unfiltered,
        window: MonthWindow = .currentMonth,
        variableUSD: Money,
        subscriptionUSD: Money = .zero,
        projectedVariableUSD: Money,
        subscriptionAccountIDs: [AccountID] = []
    ) {
        self.totalUSD = totalUSD
        self.projectedMonthEndUSD = projectedMonthEndUSD
        self.variableUSD = variableUSD
        self.subscriptionUSD = subscriptionUSD
        self.projectedVariableUSD = projectedVariableUSD
        self.subscriptionAccountIDs = subscriptionAccountIDs
        self.confidence = confidence
        self.estimatedAccounts = estimatedAccounts
        self.facts = facts
        self.comparisonUSD = comparisonUSD
        self.changeRatio = changeRatio
        self.comparisonWindow = comparisonWindow
        self.filter = filter
        self.window = window
    }

    public var formattedTotal: String {
        formattedTotal(using: .usd)
    }

    public func formattedTotal(using presentation: MoneyPresentation) -> String {
        totalUSD.formatted(using: presentation)
    }
}
