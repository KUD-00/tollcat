import Foundation
import MeterCore
import MeterFormat

public enum HeatmapBuilder {
    /// 收**现成的按天合计**，自己不去扫日志。
    ///
    /// 格子怎么排（哪个月、每格多少、1 号从周几起、峰值在哪天）在
    /// `MeterCore/HeatmapMonths` 里；这一层只把值写成字。分成两层是因为
    /// Android 桥也要同一批格子，而它链不了这个 target。
    public static func make(
        dailyTotals totals: [Date: Money],
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation
    ) -> HeatmapModuleContent? {
        let months = HeatmapMonths.make(dailyTotals: totals, now: now, calendar: calendar)
            .map { month in
                HeatmapMonth(
                    monthStart: month.monthStart,
                    // `Date.formatted` 走的是**系统**日历和时区，不是这里注入的这本。
                    // 两者不一致时月末那一瞬会印成下个月——`MeterDateFormat` 存在就是为了这个。
                    title: MeterDateFormat.yearMonth(month.monthStart, calendar: calendar),
                    monthTitle: MeterDateFormat.monthName(now: month.monthStart, calendar: calendar),
                    values: month.plottedValues,
                    leadingEmptyDays: month.leadingEmptyDays,
                    totalText: month.total.formatted(using: presentation),
                    spokenTotal: SpokenMoney.label(for: month.total, presentation: presentation),
                    peakCaption: peakCaption(month, calendar: calendar, presentation: presentation),
                    // 日期的写法在这儿排好：这里才有注入的日历。追查页拿到的是字符串。
                    dayLabels: month.days.map { MeterDateFormat.monthAndDay($0, calendar: calendar) }
                )
            }
        return months.isEmpty ? nil : HeatmapModuleContent(months: months)
    }

    private static func peakCaption(
        _ month: HeatmapMonthValues,
        calendar: Calendar,
        presentation: MoneyPresentation
    ) -> String? {
        guard let day = month.peakDay, let amount = month.peakAmount else { return nil }
        return String(
            localized: L(
                "花得最多：\(MeterDateFormat.monthAndDay(day, calendar: calendar))，\(amount.formatted(using: presentation))"
            )
        )
    }
}
