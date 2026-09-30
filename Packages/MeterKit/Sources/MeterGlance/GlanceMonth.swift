import Foundation

/// 本月那一份。字都是 iPhone 按用户的显示货币排好的——和 App 首屏同一次折算。
public struct GlanceMonth: Codable, Equatable, Sendable {
    /// 「$47.20」
    public var amountText: String
    /// 「$47」。圆形位和角落位只放得下这么多。
    public var compactAmountText: String
    public var spokenAmount: String
    /// 「预计月底 $61.60」。外推不成立时为 nil。
    public var projectionText: String?
    public var spokenProjection: String?
    /// 「9月1日至23日」
    public var periodText: String?
    /// 没设预算就是 nil。
    public var budget: GlanceBudget?
    /// 花得最多的几家，多出来的并成最后一行「其他」。
    public var services: [GlanceService]

    public init(
        amountText: String,
        compactAmountText: String,
        spokenAmount: String,
        projectionText: String? = nil,
        spokenProjection: String? = nil,
        periodText: String? = nil,
        budget: GlanceBudget? = nil,
        services: [GlanceService] = []
    ) {
        self.amountText = amountText
        self.compactAmountText = compactAmountText
        self.spokenAmount = spokenAmount
        self.projectionText = projectionText
        self.spokenProjection = spokenProjection
        self.periodText = periodText
        self.budget = budget
        self.services = services
    }
}
