import Foundation

/// 「预算线」那根条：花了多少、还剩多少、超没超、快到了没有。
///
/// 「快到了」的阈值只有这一处。它以前在 `BudgetBuilder` 里是个 0.85 的字面量，
/// Android 桥里又抄了一个——同一根条在两端会在不同的时刻变色。
public struct BudgetGauge: Equatable, Sendable {
    /// 超过这个比例就算「快到了」，条会变色。
    public static let closeThreshold = 0.85

    public var budget: Money
    public var spent: Money
    /// 花了预算的几成。**不钳到 1**：超支时条要能画出超出去的那一截。
    public var fraction: Double
    /// 还剩多少。超支时是 `.zero`。
    public var remaining: Money
    /// 超了多少。没超时是 `.zero`。
    public var overspend: Money

    public var isOver: Bool { fraction > 1 }
    public var isClose: Bool { fraction > Self.closeThreshold }

    /// 没设预算、或预算 <= 0 时返回 nil——模块自己不出现，而不是画一根 0 的条。
    public static func make(spent: Money, budgetUSD: Decimal?) -> BudgetGauge? {
        guard let budgetUSD, budgetUSD > 0 else { return nil }
        let budget = Money(usd: budgetUSD)
        let fraction = NSDecimalNumber(decimal: spent.usd / budgetUSD).doubleValue
        let over = spent.usd > budgetUSD
        return BudgetGauge(
            budget: budget,
            spent: spent,
            fraction: fraction,
            remaining: over ? .zero : budget - spent,
            overspend: over ? spent - budget : .zero
        )
    }
}
