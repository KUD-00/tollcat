import Foundation
import MeterCore

/// 「预算线」：本月合计对着用户设的月预算。
public struct BudgetModuleContent: Equatable, Sendable {
    public var spentText: String
    public var budgetText: String
    /// 还剩多少、超了多少。没超时 `overText` 是零，超了时 `remainingText` 是零。
    /// 苹果这边的卡把它们揉进 `caption`；Android 的预算条把两截分开标，要单独的数。
    public var remainingText: String
    public var overText: String
    /// 花掉的比例，可以超过 1。
    public var fraction: Double
    public var caption: String
    public var spokenLabel: String
    public var isOver: Bool
    public var isClose: Bool

    public init(
        spentText: String,
        budgetText: String,
        remainingText: String,
        overText: String,
        fraction: Double,
        caption: String,
        spokenLabel: String,
        isOver: Bool,
        isClose: Bool
    ) {
        self.spentText = spentText
        self.budgetText = budgetText
        self.remainingText = remainingText
        self.overText = overText
        self.fraction = fraction
        self.caption = caption
        self.spokenLabel = spokenLabel
        self.isOver = isOver
        self.isClose = isClose
    }

    /// 整数百分比，可以超过 100。四舍五入在这里定一次——各端自己取整会差一个百分点。
    public var usedPercent: Int { Int((fraction * 100).rounded()) }

    /// 卡上那个大数字。
    public var percentText: String { "\(usedPercent)%" }

    public var animationSignature: [Double] { [fraction] }
}
