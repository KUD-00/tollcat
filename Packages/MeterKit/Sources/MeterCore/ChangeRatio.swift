import Foundation

/// `(本月 − 上月同期) / 上月同期`。分母是 0 时没有有意义的百分比，返回 nil。
public enum ChangeRatio {
    public static func compute(current: Money, previous: Money?) -> Double? {
        guard let previous, previous > .zero else { return nil }
        let ratio = (current.usd - previous.usd) / previous.usd
        return NSDecimalNumber(decimal: ratio).doubleValue
    }
}
