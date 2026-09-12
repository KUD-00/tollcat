import Foundation

/// 日历热力图的**格子本身**：哪个月、每格多少钱、1 号从周几开始、峰值在哪天。
///
/// 只有值，没有一个字。写成「8月17日」「花得最多：…」是 `MeterFormat` 那一层的事，
/// 各平台自己拼句子——但**格子怎么排**只有这一份。
///
/// 存在的理由是它曾经有两份：`MeterModules/HeatmapBuilder` 一份，Android 桥
/// `ProductDashboardModules.heatmap` 一份逐行拷贝。两份都对是巧合，不是保证。
public enum HeatmapMonths: Sendable {
    /// 收**现成的按天合计**，自己不去扫日志。
    ///
    /// 「同一天后取的覆盖先取的」这条去重规则已经在折叠时做过一次
    /// （`LedgerView.dailyTotals()`）——这里再做一遍不只是浪费，是给了它第二个出处。
    public static func make(
        dailyTotals totals: [Date: Money],
        now: Date,
        calendar: Calendar
    ) -> [HeatmapMonthValues] {
        guard !totals.isEmpty else { return [] }
        let today = calendar.startOfDay(for: now)
        let byMonth = Dictionary(grouping: totals.keys) { day in
            calendar.date(from: calendar.dateComponents([.year, .month], from: day)) ?? day
        }
        return byMonth.keys.sorted().compactMap { monthStart in
            month(start: monthStart, totals: totals, today: today, calendar: calendar)
        }
    }

    private static func month(
        start monthStart: Date,
        totals: [Date: Money],
        today: Date,
        calendar: Calendar
    ) -> HeatmapMonthValues? {
        guard let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count else {
            return nil
        }
        var days: [Date] = []
        var values: [Money?] = Array(repeating: nil, count: dayCount)
        var total = Money.zero
        var peakDay: Date?
        var peakAmount: Money?
        days.reserveCapacity(dayCount)
        for day in 1...dayCount {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else {
                continue
            }
            days.append(date)
            // 未来那几格留 nil：0 会被画成「那天没花钱」，而它其实还没到。
            guard date <= today else { continue }
            guard let amount = totals[calendar.startOfDay(for: date)] else {
                values[day - 1] = .zero
                continue
            }
            values[day - 1] = amount
            total += amount
            if peakAmount == nil || amount.usd > peakAmount!.usd {
                peakDay = date
                peakAmount = amount
            }
        }
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        return HeatmapMonthValues(
            monthStart: monthStart,
            days: days,
            values: values,
            leadingEmptyDays: (firstWeekday - calendar.firstWeekday + 7) % 7,
            total: total,
            peakDay: peakDay,
            peakAmount: peakAmount
        )
    }
}

public struct HeatmapMonthValues: Equatable, Sendable {
    public var monthStart: Date
    /// 每格对应的日期，下标 = 日 - 1。调用方拿它去写字，不要自己再从 `monthStart` 数天：
    /// 那样会绕开这里注入的日历，月末那一天会印成下个月 1 号。
    public var days: [Date]
    /// 每天的花费，下标和 `days` 对齐。nil = 那天没有读数（含未来）。
    public var values: [Money?]
    /// 1 号是一周里的第几格（按日历首日算），格子图从这一格开始画。
    public var leadingEmptyDays: Int
    public var total: Money
    public var peakDay: Date?
    public var peakAmount: Money?

    public init(
        monthStart: Date,
        days: [Date],
        values: [Money?],
        leadingEmptyDays: Int,
        total: Money,
        peakDay: Date? = nil,
        peakAmount: Money? = nil
    ) {
        self.monthStart = monthStart
        self.days = days
        self.values = values
        self.leadingEmptyDays = leadingEmptyDays
        self.total = total
        self.peakDay = peakDay
        self.peakAmount = peakAmount
    }

    /// 画图要的 `Double`，nil 原样保留。
    public var plottedValues: [Double?] {
        values.map { $0.map { NSDecimalNumber(decimal: $0.usd).doubleValue } }
    }
}
