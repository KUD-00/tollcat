import Foundation

/// RevenueCat 的收费表。写死在 App 里，跟 `NeonPlanPricing` 一个路子。
///
/// 官方口径：月追踪收入（MTR）在门槛以内免费，超出部分按比例抽。
/// 抽成算在**应用商店抽佣之前**的毛收入上，所以这里不要先扣 30%。
enum RevenueCatFeeSchedule: Sendable {
    /// 免费额度：MTR 在这个数以内不收钱。
    static let freeThresholdUSD = Decimal(2_500)
    /// 超出部分的费率。
    static let rate = Decimal(string: "0.01")!

    static func feeUSD(monthlyTrackedRevenueUSD revenue: Decimal) -> Decimal {
        let billable = revenue - freeThresholdUSD
        guard billable > 0 else { return 0 }
        var raw = billable * rate
        var rounded = Decimal()
        NSDecimalRound(&rounded, &raw, 2, .plain)
        return rounded
    }
}
