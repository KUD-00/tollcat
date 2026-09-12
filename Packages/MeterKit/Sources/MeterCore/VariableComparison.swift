import Foundation

/// 上月同期对比。默认只看从量；页面口径算进订阅时把订阅一并带上——
/// 仪表方卡要和大数字、饼图说同一件事。
///
/// `current` 是本月全部（含还不能比的）。`previous` 只含能比的那几家，
/// 缺同期的家数和金额在 `skippedCount` / `skippedCurrent`，行上不编百分比。
public struct VariableComparison: Hashable, Sendable {
    public var current: Money
    public var previous: Money
    public var ratio: Double?
    public var comparedCount: Int
    public var skippedCount: Int
    public var skippedCurrent: Money

    public init(
        current: Money,
        previous: Money,
        ratio: Double?,
        comparedCount: Int = 1,
        skippedCount: Int = 0,
        skippedCurrent: Money = .zero
    ) {
        self.current = current
        self.previous = previous
        self.ratio = ratio
        self.comparedCount = comparedCount
        self.skippedCount = skippedCount
        self.skippedCurrent = skippedCurrent
    }

    /// 本月全进；上月只加两边都有数的。一家缺同期，其余家照比。
    ///
    /// `includingSubscriptions` 由取景框的口径决定：页面算进订阅时，
    /// 对比也把订阅带上（订阅两边同额，涨跌幅仍由从量驱动，但量级和
    /// 大数字说的是同一笔钱）；只看从量时保持原样。
    public static func make(
        from monthToDate: MonthToDate,
        includingSubscriptions: Bool = false
    ) -> VariableComparison? {
        var kinds: Set<FactKind> = [.monthToDateUsage, .prepaidConsumption]
        if includingSubscriptions {
            kinds.insert(.subscriptionIncluded)
        }
        guard let totals = FactComparisonAggregate.totals(
            facts: monthToDate.facts,
            including: kinds
        ) else {
            return nil
        }
        return VariableComparison(
            current: totals.current,
            previous: totals.previous,
            ratio: ChangeRatio.compute(current: totals.current, previous: totals.previous),
            comparedCount: totals.comparedCount,
            skippedCount: totals.skippedCount,
            skippedCurrent: totals.skippedCurrent
        )
    }
}
