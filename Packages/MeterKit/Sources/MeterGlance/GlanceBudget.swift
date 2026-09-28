import Foundation

/// 本月预算用了几成。字和仪表盘上那块「预算线」是同一次排的。
public struct GlanceBudget: Codable, Equatable, Sendable {
    /// 花掉的比例，可以超过 1。
    public var fraction: Double
    /// 「59%」
    public var percentText: String
    /// 「$80.00」
    public var limitText: String
    /// 「还剩 $32.80，用了 59%」/「超出 $4.20」
    public var caption: String
    public var level: GlanceBudgetLevel
    /// 「预计超预算 $13.10」。现在还没超、但按当前速度月底会超时才有。
    public var projectedOverspendText: String?
    public var spokenLabel: String

    public init(
        fraction: Double,
        percentText: String,
        limitText: String,
        caption: String,
        level: GlanceBudgetLevel,
        projectedOverspendText: String? = nil,
        spokenLabel: String
    ) {
        self.fraction = fraction
        self.percentText = percentText
        self.limitText = limitText
        self.caption = caption
        self.level = level
        self.projectedOverspendText = projectedOverspendText
        self.spokenLabel = spokenLabel
    }
}
