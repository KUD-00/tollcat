import Foundation
import MeterCore

/// 明细按 (category, label, scope) 归格。厂商一天一行、一个 sku 一行地给，
/// 直接堆进快照会是几百条；这里先合成本账期的样子。
///
/// 顺序按金额从大到小，同额按名字——界面不必再排一次，也保证同一份数据
/// 每次渲染顺序一致（字典遍历顺序不稳，图例颜色会跟着跳）。
struct SpendLineAccumulator: Sendable {
    private struct Key: Hashable {
        var category: String
        var label: String
        var scope: String?
    }

    private var lines: [Key: SpendLine] = [:]

    mutating func add(_ line: SpendLine) {
        let key = Key(category: line.category, label: line.label, scope: line.scope)
        if let existing = lines[key] {
            lines[key] = existing.merging(line)
        } else {
            lines[key] = line
        }
    }

    var isEmpty: Bool { lines.isEmpty }

    /// 全零的明细也保留：`amountUSD` 是 0 但 `listUSD` 有值，正是"免费额度替你
    /// 挡了多少"那一屏的数据。真的一条都没有才给 nil，让快照维持"没有明细"的语义。
    var snapshot: [SpendLine]? {
        guard !lines.isEmpty else { return nil }
        return lines.values.sorted { lhs, rhs in
            if lhs.amountUSD != rhs.amountUSD { return lhs.amountUSD > rhs.amountUSD }
            if lhs.category != rhs.category { return lhs.category < rhs.category }
            if lhs.label != rhs.label { return lhs.label < rhs.label }
            return (lhs.scope ?? "") < (rhs.scope ?? "")
        }
    }
}
