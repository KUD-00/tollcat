import Foundation
import MeterCore

/// 「预算线」：本月合计对着用户设的月预算。
public struct BudgetModuleContent: Equatable, Sendable {
    public var spentText: String
    public var budgetText: String
    /// 花掉的比例，可以超过 1。
    public var fraction: Double
    public var caption: String
    public var spokenLabel: String
    public var isOver: Bool
    public var isClose: Bool

    public init(
        spentText: String,
        budgetText: String,
        fraction: Double,
        caption: String,
        spokenLabel: String,
        isOver: Bool,
        isClose: Bool
    ) {
        self.spentText = spentText
        self.budgetText = budgetText
        self.fraction = fraction
        self.caption = caption
        self.spokenLabel = spokenLabel
        self.isOver = isOver
        self.isClose = isClose
    }

    /// 卡上那个大数字。整数百分比，可以超过 100%。
    public var percentText: String { "\(Int((fraction * 100).rounded()))%" }

    public var animationSignature: [Double] { [fraction] }
}
