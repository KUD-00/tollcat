import Foundation

/// 最大余数法，让整数百分比加起来是 100，对得上设计稿那组 45/23/16/9/7。
public enum IntegerPercents {
    public static func from(weights: [Decimal]) -> [Int] {
        let total = weights.reduce(0, +)
        guard total > 0 else { return weights.map { _ in 0 } }

        var floors: [Int] = []
        var remainders: [Decimal] = []
        floors.reserveCapacity(weights.count)
        remainders.reserveCapacity(weights.count)

        for weight in weights {
            let exact = weight / total * 100
            var floored = Decimal()
            var mutable = exact
            NSDecimalRound(&floored, &mutable, 0, .down)
            let floor = NSDecimalNumber(decimal: floored).intValue
            floors.append(floor)
            remainders.append(exact - floored)
        }

        var leftover = 100 - floors.reduce(0, +)
        let ranked = remainders.enumerated()
            .sorted { lhs, rhs in
                if lhs.element == rhs.element { return lhs.offset < rhs.offset }
                return lhs.element > rhs.element
            }
            .map(\.offset)

        var index = 0
        while leftover > 0, !ranked.isEmpty {
            floors[ranked[index % ranked.count]] += 1
            leftover -= 1
            index += 1
        }
        return floors
    }
}
