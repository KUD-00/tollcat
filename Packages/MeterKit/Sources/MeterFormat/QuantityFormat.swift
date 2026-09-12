import Foundation

/// 用量数字写成人看的样子。**不带单位**——单位是厂商原文，由调用方拼。
///
/// 厂商给的是原始精度（`0.46822993099999999`、`1061.6500000000001`），
/// 直接印出来像 bug。这里按量级收敛：大数不要小数点，小数留够看得出差别的位数，
/// 但绝不四舍五入到 0——`0.0004557710222222222 GB-months` 写成 `0` 会让人以为没用。
public enum QuantityFormat: Sendable {
    /// 配置只有（小数位数 × 是否千分组）十几种，全部缓存住。
    private static let formatters = FormatterCache<NumberFormatter>()

    public static func string(_ value: Decimal) -> String {
        let magnitude = abs(value)
        if magnitude == 0 { return "0" }

        let digits: Int
        switch magnitude {
        case 1000...:
            digits = 0
        case 1..<1000:
            digits = 2
        case 0.01..<1:
            digits = 3
        default:
            // 比 0.01 还小：留到第一个有效数字后面两位，最多 8 位。
            digits = min(leadingZeros(magnitude) + 3, 8)
        }

        let usesGrouping = magnitude >= 1000
        return formatters.use(key: "\(digits)|\(usesGrouping)", make: {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.usesGroupingSeparator = usesGrouping
            formatter.groupingSeparator = ","
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = digits
            return formatter
        }) { $0.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)" }
    }

    /// 小数点后有几个前导零。`0.00045` → 3。
    private static func leadingZeros(_ magnitude: Decimal) -> Int {
        var zeros = 0
        var probe = magnitude
        while probe < 1, zeros < 8 {
            probe *= 10
            zeros += 1
        }
        return max(zeros - 1, 0)
    }
}
