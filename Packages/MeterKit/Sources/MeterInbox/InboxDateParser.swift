import Foundation

/// Worker 只发两种日期：`YYYY-MM-DD` 的周期起点，和 RFC3339 的投递时刻。
/// 不复用 `MeterProviders.BillingDateParser`——那是另一个模块，这里不能 import 它。
enum InboxDateParser: Sendable {
    static func day(_ raw: String, calendar: Calendar) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: "-")
        guard parts.count == 3, trimmed.count == 10,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else {
            return nil
        }
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    static func instant(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return formatter(fractional: true).date(from: trimmed)
            ?? formatter(fractional: false).date(from: trimmed)
    }

    /// 每次新建而不是 `static let`：`ISO8601DateFormatter` 不是 Sendable，
    /// 存成静态属性在严格并发下过不了。和 `BillingDateParser` 同一处理。
    private static func formatter(fractional: Bool) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = fractional
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
}
