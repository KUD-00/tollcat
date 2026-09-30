import Foundation

/// 点进一家服务看到的那一页。和 `GlanceService` 其余字段一样，字全是 iPhone 排好的。
///
/// 只有手表 App 要它：锁屏那几格从不点进去，iPhone 折锁屏那份时不建这一块。
public struct GlanceServiceDetail: Codable, Equatable, Sendable {
    /// 「占本月 45%」
    public var shareText: String?
    /// 较上月同期。还不能比就是 nil。
    public var change: GlanceChange?
    /// 近 30 天每天按量花了多少，旧到新，缺的天记 0。
    /// 这家报不出按天的数就是空数组——详情页只摆数字，不画一条假的平线。
    public var days: [GlanceDay]
    /// 「订阅 $20.00 按月扣，不在柱上」。这家本月有订阅、又画了柱时才有。
    public var subscriptionNote: String?
    /// 花在哪了：最新一条明细的前几类，或者一笔笔订阅。
    public var sublines: [GlanceSubline]
    /// 预充值的家才有。
    public var balance: GlanceBalance?

    public init(
        shareText: String? = nil,
        change: GlanceChange? = nil,
        days: [GlanceDay] = [],
        subscriptionNote: String? = nil,
        sublines: [GlanceSubline] = [],
        balance: GlanceBalance? = nil
    ) {
        self.shareText = shareText
        self.change = change
        self.days = days
        self.subscriptionNote = subscriptionNote
        self.sublines = sublines
        self.balance = balance
    }
}

/// 较上月同期那一句。
public struct GlanceChange: Codable, Equatable, Sendable {
    public enum Direction: String, Codable, Sendable {
        case up
        case down
        case flat
    }

    /// 「较上月同期 +12%」
    public var text: String
    /// 「本月 $21.40 · 8月同期 $19.10」
    public var detailText: String
    public var direction: Direction

    public init(text: String, detailText: String, direction: Direction) {
        self.text = text
        self.detailText = detailText
        self.direction = direction
    }
}

/// 柱图的一天。
public struct GlanceDay: Codable, Equatable, Sendable, Identifiable {
    /// 那天零点（按 iPhone 的日历）。
    public var date: Date
    /// 按显示币种的金额，只用来定柱高。
    public var value: Double
    /// 「$1.20」。表冠点到这一天时上屏。
    public var amountText: String

    public init(date: Date, value: Double, amountText: String) {
        self.date = date
        self.value = value
        self.amountText = amountText
    }

    public var id: Date { date }
}

/// 花在哪了的一行。
public struct GlanceSubline: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var title: String
    public var amountText: String

    public init(id: String, title: String, amountText: String) {
        self.id = id
        self.title = title
        self.amountText = amountText
    }
}

/// 预充值余额。
public struct GlanceBalance: Codable, Equatable, Sendable {
    /// 「余额 $32.10」
    public var balanceText: String
    /// 「还能用 18 天」
    public var runwayText: String?
    /// 一周内见底：按危险色画。
    public var isLow: Bool

    public init(balanceText: String, runwayText: String?, isLow: Bool) {
        self.balanceText = balanceText
        self.runwayText = runwayText
        self.isLow = isLow
    }
}
