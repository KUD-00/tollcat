import Foundation

/// 日期、相对时间一律跟当前 locale，不要钉死中文模板。
///
/// **收 `Calendar` 的地方必须把它的时区也交给 formatter。**
/// `DateFormatter` 不会从 `calendar` 继承时区，它默认用系统时区——两者不一致时
/// 结果会整体偏移。平时看不出来（注入的多半就是 `.current`），但一旦格式化的是
/// 月末最后一瞬这种边界值，偏移几小时就会把「七月」印成「八月」。
/// 筛选功能里回看过去某个月的锚点正好是那种值，这个坑是在那里被踩出来的。
///
/// Formatter 实例按（模板 · locale · 历法 · 时区）缓存在 `FormatterCache` 里，
/// 这四样共同决定输出；系统语言切换后 locale 变了，钥匙跟着变，旧条目自然闲置。
public enum MeterDateFormat {
    private static let dateFormatters = FormatterCache<DateFormatter>()
    private static let intervalFormatters = FormatterCache<DateIntervalFormatter>()

    public static func monthName(now: Date, calendar: Calendar, locale: Locale = .current) -> String {
        templated(now, template: "MMMM", calendar: calendar, locale: locale)
    }

    /// 「几月」，只给月序号（1...12），不需要年也不需要日历。
    ///
    /// 同期比较里只剩下一个月序号可用（`ComparisonWindow.month`）。以前是在调用点
    /// 拼一个 `DateComponents(year: 2026, month: ...)` 再用 `Calendar.current` 去解——
    /// 一个写死的年份，加一个从环境里捡来的日历：用户把系统历法设成和历或佛历时，
    /// 那个月序号会被当成另一套历法的月份，印出来根本不是那个月。
    ///
    /// 月序号本来就是公历的，所以这里用公历解，年份取哪一年都一样（月份名与年无关）。
    public static func monthName(monthOfYear: Int, locale: Locale = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        guard
            let date = calendar.date(
                from: DateComponents(year: 2000, month: monthOfYear, day: 1)
            )
        else {
            return ""
        }
        return templated(date, template: "MMMM", calendar: calendar, locale: locale)
    }

    public static func yearMonth(_ date: Date, calendar: Calendar, locale: Locale = .current) -> String {
        templated(date, template: "yMMMM", calendar: calendar, locale: locale)
    }

    /// Android 的 JNI 出口没有可靠的 `Locale.current`，locale 从参数进来。
    public static func monthAndDay(_ date: Date, calendar: Calendar, locale: Locale = .current) -> String {
        templated(date, template: "MMMMd", calendar: calendar, locale: locale)
    }

    public static func monthDayTime(_ date: Date, calendar: Calendar) -> String {
        templated(date, template: "MMMMdjjmm", calendar: calendar, locale: .current)
    }

    public static func monthDayNumeric(_ date: Date, calendar: Calendar) -> String {
        templated(date, template: "Md", calendar: calendar, locale: .current)
    }

    /// 「五月–七月」。跨年时两端都带上年份，否则「十二月–二月」读起来像倒着的。
    ///
    /// 不走 `DateIntervalFormatter`：它按天排版，会把整月区间印成
    /// 「5月1日 – 7月31日」——那正是这个 App 刻意不提供的按日口径。
    public static func monthRange(
        from start: Date,
        to end: Date,
        calendar: Calendar,
        locale: Locale = .current
    ) -> String {
        let sameYear = calendar.component(.year, from: start) == calendar.component(.year, from: end)
        let left = sameYear
            ? monthName(now: start, calendar: calendar, locale: locale)
            : yearMonth(start, calendar: calendar, locale: locale)
        let right = sameYear
            ? monthName(now: end, calendar: calendar, locale: locale)
            : yearMonth(end, calendar: calendar, locale: locale)
        return "\(left)–\(right)"
    }

    public static func period(from start: Date, to end: Date, calendar: Calendar) -> String {
        interval(from: start, to: end, calendar: calendar, kind: "template:MMMd") {
            $0.dateTemplate = "MMMd"
        }
    }

    public static func spokenPeriod(from start: Date, to end: Date, calendar: Calendar) -> String {
        interval(from: start, to: end, calendar: calendar, kind: "style:long") {
            $0.dateStyle = .long
            $0.timeStyle = .none
        }
    }

    private static func templated(
        _ date: Date,
        template: String,
        calendar: Calendar,
        locale: Locale
    ) -> String {
        dateFormatters.use(key: cacheKey(template, calendar: calendar, locale: locale), make: {
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.locale = locale
            formatter.setLocalizedDateFormatFromTemplate(template)
            return formatter
        }) { $0.string(from: date) }
    }

    private static func interval(
        from start: Date,
        to end: Date,
        calendar: Calendar,
        kind: String,
        configure: (DateIntervalFormatter) -> Void
    ) -> String {
        intervalFormatters.use(key: cacheKey(kind, calendar: calendar, locale: .current), make: {
            let formatter = DateIntervalFormatter()
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.locale = .current
            configure(formatter)
            return formatter
        }) { $0.string(from: start, to: end) }
    }

    private static func cacheKey(_ what: String, calendar: Calendar, locale: Locale) -> String {
        "\(what)|\(locale.identifier)|\(calendar.identifier)|\(calendar.timeZone.identifier)"
    }

    // RelativeDateTimeFormatter 和 L() 在 Android 的 swift-foundation 里没有；
    // Android 侧相对时间由 Kotlin 用 DateUtils 做（locale 由系统给）。
    #if !os(Android)
    private static let relativeFormatters = FormatterCache<RelativeDateTimeFormatter>()

    public static func relative(from date: Date, now: Date, calendar: Calendar) -> String {
        if abs(now.timeIntervalSince(date)) < 60 {
            return String(localized: L("刚刚"))
        }
        return relativeFormatters.use(key: cacheKey("relative", calendar: calendar, locale: .current), make: {
            let formatter = RelativeDateTimeFormatter()
            formatter.calendar = calendar
            formatter.locale = .current
            formatter.unitsStyle = .full
            return formatter
        }) { $0.localizedString(for: date, relativeTo: now) }
    }

    public static func todayOrTomorrow(_ date: Date, now: Date, calendar: Calendar) -> String? {
        if calendar.isDate(date, inSameDayAs: now) {
            return String(localized: L("今天"))
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return String(localized: L("明天"))
        }
        return nil
    }
    #endif
}
