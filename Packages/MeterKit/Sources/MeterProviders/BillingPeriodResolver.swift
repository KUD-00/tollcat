import Foundation

/// 各家发票/账期字段解析成闭区间。解析不出来（或顺序不对）就退回日历月。
/// 各家对 `end` 的口径不一样，用 `EndConvention` 点名，别再各写一份。
enum BillingPeriodResolver: Sendable {
    enum EndConvention: Sendable {
        /// `end` 就是最后一天（Fastly）。要求 `end >= start`。
        case inclusive
        /// `end` 是下期开始那天，无条件退一天（Atlas）。要求 `end > start`。
        case exclusive
        /// `end` 通常是最后一天，但落在 1 号说明是下期开始，退一天（Railway / PostHog）。
        case exclusiveWhenMonthStart
    }

    static func resolve(
        startRaw: String?,
        endRaw: String?,
        endConvention: EndConvention,
        fallback: CalendarMonthWindow,
        calendar: Calendar
    ) -> (start: Date, end: Date) {
        guard
            let startRaw,
            let endRaw,
            let start = BillingDateParser.parse(startRaw, calendar: calendar),
            let end = BillingDateParser.parse(endRaw, calendar: calendar)
        else {
            return (fallback.start, fallback.endInclusive)
        }
        switch endConvention {
        case .inclusive:
            guard end >= start else { return (fallback.start, fallback.endInclusive) }
            return (start, end)
        case .exclusive:
            guard end > start else { return (fallback.start, fallback.endInclusive) }
            return (start, calendar.date(byAdding: .day, value: -1, to: end) ?? end)
        case .exclusiveWhenMonthStart:
            if calendar.component(.day, from: end) == 1, end > start {
                let inclusive = calendar.date(byAdding: .day, value: -1, to: end)
                return (start, inclusive ?? fallback.endInclusive)
            }
            return (start, end)
        }
    }
}
