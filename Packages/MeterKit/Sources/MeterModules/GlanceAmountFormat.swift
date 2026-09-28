import Foundation
import MeterCore

/// 圆形位和角落位的金额：「$47」「$1.2K」。只有两三个字的地方，分就不写了。
///
/// 符号跟 `CurrencyAmountFormat` 同一张表，所以和 App 里的大数字是同一个币种写法。
public enum GlanceAmountFormat {
    public static func compact(_ amount: Decimal, code: String) -> String {
        let value = NSDecimalNumber(decimal: amount).doubleValue
        let magnitude = abs(value)
        let body: String
        if magnitude < 999.5 {
            body = String(Int(magnitude.rounded()))
        } else if magnitude < 999_500 {
            body = scaled(magnitude / 1_000) + "K"
        } else {
            body = scaled(magnitude / 1_000_000) + "M"
        }
        let prefixed = CurrencyAmountFormat.prefix(for: code) + body
        return value < 0 ? "-" + prefixed : prefixed
    }

    /// 两位数以下留一位小数（1.2K），再大就只留整数（12K）；「10.0K」这种写成「10K」。
    private static func scaled(_ value: Double) -> String {
        let tenths = (value * 10).rounded() / 10
        if tenths >= 10 || tenths == tenths.rounded() {
            return String(Int(tenths.rounded()))
        }
        return String(format: "%.1f", tenths)
    }
}
