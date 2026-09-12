import Foundation
import MeterCore

/// 各家日期字段写法不统一，集中在这里试，失败就当这条没有日期。
///
/// ## 出来的是「哪一天」，不是「哪一刻」
///
/// 所有调用方要的都是日桶的钥匙或账期端点——**厂商说的那一天**，
/// 落在本机日历的那天零点。于是这里的规矩只有一条：
/// **先认字面上的年月日，认不出来才去把时间戳换算成天。**
///
/// 反过来（先把 `2026-08-01T00:00:00Z` 解成瞬间、再 `startOfDay`）会按**本机**
/// 时区落日：UTC 以西的用户每一个桶都会退到前一天，1 号那个桶还会退到上个月，
/// 于是本月合计凭空少一天、月初当天整月归零。而 UTC 以东的用户一切正常——
/// 这个 bug 只在西半球出现，也只在那儿能被发现。
enum BillingDateParser: Sendable {
    static func parse(_ raw: String, calendar: Calendar) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // 字面年月日优先。RFC3339 串的日期部分按定义就是它自己那个偏移里的日期，
        // 取前 10 个字符正好等于「厂商说的那一天」，不必先换算成瞬间。
        if let date = parseYearMonthDay(trimmed, calendar: calendar) {
            return date
        }
        if let date = parseYearMonthDayPrefix(trimmed, calendar: calendar) {
            return date
        }
        // 没有 `yyyy-MM-dd` 前缀的写法才走解析器，按 UTC 落日。
        if let date = iso8601Fractional().date(from: trimmed) {
            return utcDay(of: date, calendar: calendar)
        }
        if let date = iso8601().date(from: trimmed) {
            return utcDay(of: date, calendar: calendar)
        }
        // 兜底：形状不认得，但开头 10 个字符是个日期。宁可取那一天，也不当没有。
        return parseYearMonthDay(String(trimmed.prefix(10)), calendar: calendar)
    }

    /// Unix 秒同样按 **UTC** 落日：各家的日桶起点都是 UTC 零点，
    /// 按本机时区落会让西半球整体错开一天。
    static func parseUnixSeconds(_ raw: Int, calendar: Calendar) -> Date {
        utcDay(of: Date(timeIntervalSince1970: TimeInterval(raw)), calendar: calendar)
    }

    static func rfc3339(_ date: Date) -> String {
        iso8601().string(from: date)
    }

    /// 这一刻在 UTC 是哪年哪月哪日，再取本机日历上那一天的零点。
    private static func utcDay(of instant: Date, calendar: Calendar) -> Date {
        var utc = calendar
        guard let zero = TimeZone(secondsFromGMT: 0) else {
            return calendar.startOfDay(for: instant)
        }
        utc.timeZone = zero
        let parts = utc.dateComponents([.year, .month, .day], from: instant)
        guard
            let year = parts.year,
            let month = parts.month,
            let day = parts.day,
            let date = calendar.date(from: DateComponents(year: year, month: month, day: day))
        else {
            return calendar.startOfDay(for: instant)
        }
        return date
    }

    private static func iso8601() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }

    private static func iso8601Fractional() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }

    /// 严格 `yyyy-MM-dd`，落在本机日历那天的零点。
    ///
    /// 「这一天存不存在」由 `DayKey.date(in:)` 判——它验分量能原样翻回来，
    /// 于是 `2026-02-30` 是 nil。以前这里直接 `calendar.date(from:)`，
    /// 溢出成 3 月 2 日：厂商真回过这种日期，那笔钱会落进错的月。
    /// 判据只有一处，落盘和解析用的是同一条。
    private static func parseYearMonthDay(_ raw: String, calendar: Calendar) -> Date? {
        guard raw.count == 10, raw[raw.index(raw.startIndex, offsetBy: 4)] == "-",
              raw[raw.index(raw.startIndex, offsetBy: 7)] == "-" else {
            return nil
        }
        return DayKey(storageString: raw)?.date(in: calendar)
    }

    /// `2026-08-01T00:00:00Z` 这类串取前 10 个字符。**必须真的是那个形状**，
    /// 否则「日期后面跟着别的东西」会被当成日期。
    private static func parseYearMonthDayPrefix(_ raw: String, calendar: Calendar) -> Date? {
        guard raw.count >= 11 else { return nil }
        let separator = raw[raw.index(raw.startIndex, offsetBy: 10)]
        guard separator == "T" || separator == "t" || separator == " " else { return nil }
        return parseYearMonthDay(String(raw.prefix(10)), calendar: calendar)
    }
}
