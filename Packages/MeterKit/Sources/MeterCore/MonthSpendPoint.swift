import Foundation

/// 一个整月的钱。趋势图的点：从量与合计（从量 + 计入的订阅）都带上，
/// 画哪条由展示层按取景框的口径挑，这里不替它决定。
public struct MonthSpendPoint: Hashable, Sendable {
    public var monthStart: Date
    public var variableUSD: Money
    /// 从量 + 计入的订阅。取景框关掉订阅时它就等于 `variableUSD`。
    public var totalUSD: Money

    public init(monthStart: Date, variableUSD: Money, totalUSD: Money? = nil) {
        self.monthStart = monthStart
        self.variableUSD = variableUSD
        self.totalUSD = totalUSD ?? variableUSD
    }
}
