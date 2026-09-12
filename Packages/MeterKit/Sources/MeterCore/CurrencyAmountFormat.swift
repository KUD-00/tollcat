import Foundation

/// 展示金额的符号和分位。账本仍是美元，这里只决定怎么写成字。
///
/// 不用系统 `NumberFormatter`：中文 locale 会把美元写成 `US$`，和设计稿的 `$` 对不上。
/// 符号按币种写死，不跟系统区域。
///
/// ## 为什么这个文件在 MeterCore，而不是 MeterFormat
///
/// 因为它**跟语言和系统区域都没有关系**。同一个 `Money` 在简体中文、English、
/// 日本語下写出来一模一样——这正是它存在的理由。这是 `Money` 这个领域类型自己
/// 的写法，不是本地化。
///
/// MeterCore 的那条线不是「不出任何字符串」，是**出数，不出话**：
/// `String(localized:)` / `NumberFormatter` / `DateFormatter` / `Locale.current`
/// 在这一层一个都不许出现（提交闸扫这几个词）。凡是跟语言、跟系统区域有关的，
/// 包括「较上月同期」这种句子和日期的写法，都在 `MeterFormat`。
///
/// 另一个硬约束：MeterCore 要在 Android / Windows 上同源编译，
/// 而那边根本没有可靠的 `Locale.current`。
public enum CurrencyAmountFormat: Sendable {
    public static func fractionDigits(for code: String) -> Int {
        switch ExchangeRates.normalized(code) {
        case "JPY", "KRW":
            return 0
        default:
            return 2
        }
    }

    public static func prefix(for code: String) -> String {
        switch ExchangeRates.normalized(code) {
        case ExchangeRates.usdCode: return "$"
        case "CNY", "JPY": return "¥"
        case "EUR": return "€"
        case "GBP": return "£"
        case "AUD": return "A$"
        case "CAD": return "CA$"
        case "SGD": return "S$"
        case "INR": return "₹"
        case "BRL": return "R$"
        case "KRW": return "₩"
        case "TWD": return "NT$"
        case "HKD": return "HK$"
        default: return "\(ExchangeRates.normalized(code)) "
        }
    }

    public static func string(amount: Decimal, code: String) -> String {
        let places = fractionDigits(for: code)
        var value = amount
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, places, .plain)
        let negative = rounded < 0
        let absolute = negative ? -rounded : rounded
        let body = digits(absolute, fractionDigits: places)
        let prefixed = "\(prefix(for: code))\(body)"
        return negative ? "-\(prefixed)" : prefixed
    }

    /// 不带符号，给 VoiceOver 拼「336.18 人民币」。
    public static func digits(amount: Decimal, code: String) -> String {
        let places = fractionDigits(for: code)
        var value = amount
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, places, .plain)
        let negative = rounded < 0
        let absolute = negative ? -rounded : rounded
        let body = digits(absolute, fractionDigits: places)
        return negative ? "-\(body)" : body
    }

    private static func digits(_ amount: Decimal, fractionDigits: Int) -> String {
        if fractionDigits == 0 {
            var whole = amount
            var rounded = Decimal()
            NSDecimalRound(&rounded, &whole, 0, .plain)
            return thousandsSeparated(NSDecimalNumber(decimal: rounded).intValue)
        }
        var scaled = amount
        for _ in 0..<fractionDigits {
            scaled *= 10
        }
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        let units = NSDecimalNumber(decimal: rounded).intValue
        let base = Int(pow(10.0, Double(fractionDigits)))
        let fraction = String(format: "%0\(fractionDigits)d", abs(units) % base)
        return "\(thousandsSeparated(abs(units) / base)).\(fraction)"
    }

    /// 自己插逗号，不跟系统 locale。
    private static func thousandsSeparated(_ value: Int) -> String {
        let digits = String(value)
        var grouped = ""
        grouped.reserveCapacity(digits.count + digits.count / 3)
        for (offset, character) in digits.enumerated() {
            if offset > 0, (digits.count - offset).isMultiple(of: 3) {
                grouped.append(",")
            }
            grouped.append(character)
        }
        return grouped
    }
}
