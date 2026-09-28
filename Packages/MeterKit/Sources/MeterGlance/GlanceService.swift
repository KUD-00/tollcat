import Foundation

/// 手表 App 列表里的一行。
public struct GlanceService: Codable, Equatable, Sendable, Identifiable {
    /// 在列表里的名次，从 0 起。颜色按名次取，和 App 构成图同一套。
    public var rank: Int
    public var name: String
    public var amountText: String
    public var spokenAmount: String
    /// 「其他」那一行：前几名之外的并在一起，颜色用灰。
    public var isRemainder: Bool

    public init(rank: Int, name: String, amountText: String, spokenAmount: String, isRemainder: Bool = false) {
        self.rank = rank
        self.name = name
        self.amountText = amountText
        self.spokenAmount = spokenAmount
        self.isRemainder = isRemainder
    }

    public var id: Int { rank }
}
