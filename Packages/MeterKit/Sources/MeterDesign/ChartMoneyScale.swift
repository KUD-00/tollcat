import Foundation

/// 图表 Y 轴用整美元，不要把分位标上去。
public enum ChartMoneyScale: Sendable {
    public static func marks(max: Double) -> [Double] {
        let ceiling = Swift.max(max, 0)
        if ceiling == 0 {
            return [0, 1]
        }
        let raw = ceiling / 2
        let exponent = floor(log10(raw))
        let magnitude = pow(10, exponent)
        let residual = raw / magnitude
        let nice: Double
        if residual <= 1 {
            nice = 1
        } else if residual <= 2 {
            nice = 2
        } else if residual <= 5 {
            nice = 5
        } else {
            nice = 10
        }
        var step = nice * magnitude
        var top = step * 2
        if top < ceiling {
            step = nextNiceStep(step)
            top = step * 2
        }
        if top < ceiling {
            let count = ceil(ceiling / step)
            top = count * step
            return stride(from: 0.0, through: top, by: step).map { $0 }
        }
        return [0, step, top]
    }

    public static func label(_ value: Double) -> String {
        if value == 0 {
            return "$0"
        }
        if abs(value - value.rounded()) < 0.000_1 {
            return "$\(Int(value.rounded()))"
        }
        return String(format: "$%.0f", value)
    }

    /// 按住读数用。轴上是整美元，这里要看到分。
    public static func detailLabel(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private static func nextNiceStep(_ step: Double) -> Double {
        let exponent = floor(log10(step))
        let magnitude = pow(10, exponent)
        let residual = step / magnitude
        if residual <= 1 {
            return 2 * magnitude
        }
        if residual <= 2 {
            return 5 * magnitude
        }
        if residual <= 5 {
            return 10 * magnitude
        }
        return 20 * magnitude
    }
}
