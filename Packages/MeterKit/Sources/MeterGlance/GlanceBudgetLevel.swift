import Foundation

/// 预算条该是什么颜色。阈值在 `BudgetGauge`，这里只是结论。
public enum GlanceBudgetLevel: String, Codable, Equatable, Sendable {
    case normal
    case close
    case over
}
