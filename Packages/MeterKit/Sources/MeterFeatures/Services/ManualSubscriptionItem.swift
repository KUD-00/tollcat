import Foundation
import SwiftData
import MeterCore

/// 服务页底部那一行手动订阅。点进去改字段、保存、删除；不做续订提醒。
struct ManualSubscriptionItem: Identifiable, Equatable, Sendable {
    var id: PersistentIdentifier
    var name: String
    var amount: Money
    var period: SubscriptionPeriod
    var anchorDate: Date
    /// 退订那个月。nil = 还在付。
    ///
    /// 一笔订阅是**一段区间**：开始 → 结束。停掉之后又重新订，那是新的一段，
    /// 要新加一笔——不是把这一笔「恢复」。恢复会把中间没付钱的月份一起补上。
    var endDate: Date?
    /// 到「此刻」为止已经结束了。构造时就按当时的 now 判好，视图不再自己算。
    ///
    /// 和 `endDate != nil` 不是一回事：退订日期可以填在未来（这个月取消、
    /// 服务用到 11 月底），那种仍然在付，仍然算进本月。
    var hasEnded: Bool = false
    var accountID: AccountID?
    var providerID: ProviderID?
    /// 席位数之类。1 份时界面不显示这一段。
    var quantity: Int = 1

    /// 单价。数量为 1 时就等于 `amount`。
    var unitAmount: Money {
        guard quantity > 1 else { return amount }
        return Money(usd: amount.usd / Decimal(quantity))
    }
}
