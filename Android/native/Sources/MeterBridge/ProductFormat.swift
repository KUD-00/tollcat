import Foundation
import MeterCore
import MeterFormat

/// 「说钱」的出口。Kotlin 不再自己格式化金额和相对时间——
/// 币种符号、位数、千分位、locale 语序全部走这里，和 iOS 同一份实现。
package enum ProductFormat {
    /// USD 十进制字符串 → 显示币种字符串。解析不了就原样退回（可能已经是格式化文本）。
    package static func usd(_ raw: String, currency: String, localeTag: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")),
              trimmed.rangeOfCharacter(from: CharacterSet.letters) == nil,
              !trimmed.isEmpty
        else {
            return raw
        }
        return Money(usd: value).formatted(using: ProductRates.presentation(currency))
    }

    /// 「上次刷新」的月日档。刚刚 / <24h 相对时间由 Kotlin 用 DateUtils 做
    /// （swift-foundation 在 Android 上没有 RelativeDateTimeFormatter），
    /// 档位划分的口径以 iOS `ServiceRelativeTime` 为准。
    package static func monthAndDay(millis: Int64, localeTag: String) -> String {
        MeterDateFormat.monthAndDay(
            ProductClock.date(millis: millis),
            calendar: ProductClock.calendar(),
            locale: ProductDashboard.locale(localeTag)
        )
    }
}
