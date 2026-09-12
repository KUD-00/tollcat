import Foundation
import MeterCore

public struct MonthToDateModuleContent: Equatable, Sendable {
    public var estimateCaption: String?
    public var amountText: String
    public var totalValue: Double
    public var spokenTotal: String
    /// 「预计月底 $87.70」。回看过去某个月时为 nil：那个月已经结束，没有可推的东西。
    ///
    /// **统计区间不在这里**，在 `periodCaption`。两半分开存，2×2 那一档才能
    /// 只留前半句——126pt 宽里「预计月底 $87.70 · 9月1日至6日」要折成三行。
    public var projectedCaption: String?
    /// 「9月1日至6日」；没有可推的月份时是自带前缀的「整月 · 七月」/「合计 · 五月–七月」。
    public var periodCaption: String?
    public var projectedValue: Double
    public var spokenProjected: String?
    public var estimatedNames: [String]
    public var staleCaption: String?
    /// 「七月 · 不含订阅 · 排除 AWS」。筛选没动过就是 nil。
    ///
    /// **这一行和数字绑在同一个模块里，不做成会滚走的横幅。**
    /// 横幅一滚走，屏幕上就只剩一个看起来完全正常、其实是筛过的数字。
    public var filterNote: String?
    /// 不是美元时挂一句「按人民币显示」。美元不写——那是默认，写了是噪音。
    public var currencyNote: String?
    /// 「本月订阅 $4 · 已计入」。没有订阅就是 nil。
    public var subscriptionCaption: String?
    public var spokenSubscription: String?
    /// 只有一个账号时首屏那一行可以推进详情。
    public var subscriptionAccountID: AccountID?
    /// 当前口径：大数字算没算订阅。驱动数字旁边那颗切换。
    public var includesSubscriptions: Bool
    /// 有观察到的订阅才摆切换——没有订阅可切时它是死重。
    public var showsSubscriptionScope: Bool

    public init(
        estimateCaption: String? = nil,
        amountText: String,
        totalValue: Double,
        spokenTotal: String,
        projectedCaption: String? = nil,
        periodCaption: String? = nil,
        projectedValue: Double,
        spokenProjected: String? = nil,
        estimatedNames: [String],
        staleCaption: String? = nil,
        filterNote: String? = nil,
        currencyNote: String? = nil,
        subscriptionCaption: String? = nil,
        spokenSubscription: String? = nil,
        subscriptionAccountID: AccountID? = nil,
        includesSubscriptions: Bool,
        showsSubscriptionScope: Bool
    ) {
        self.estimateCaption = estimateCaption
        self.amountText = amountText
        self.totalValue = totalValue
        self.spokenTotal = spokenTotal
        self.projectedCaption = projectedCaption
        self.periodCaption = periodCaption
        self.projectedValue = projectedValue
        self.spokenProjected = spokenProjected
        self.estimatedNames = estimatedNames
        self.staleCaption = staleCaption
        self.filterNote = filterNote
        self.currencyNote = currencyNote
        self.subscriptionCaption = subscriptionCaption
        self.spokenSubscription = spokenSubscription
        self.subscriptionAccountID = subscriptionAccountID
        self.includesSubscriptions = includesSubscriptions
        self.showsSubscriptionScope = showsSubscriptionScope
    }

    public var showsEstimateCaption: Bool { estimateCaption != nil }

    /// 两半接回一句。地方够宽的地方（首屏、菜单栏、分享卡）用它。
    public var fullProjectedCaption: String? {
        switch (projectedCaption, periodCaption) {
        case let (projection?, period?): "\(projection) · \(period)"
        case let (projection?, nil): projection
        case let (nil, period?): period
        case (nil, nil): nil
        }
    }
}
