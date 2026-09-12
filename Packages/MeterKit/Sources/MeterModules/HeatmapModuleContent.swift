import Foundation
import MeterCore
import MeterFormat

/// 「日历热力图」：有按天读数的每个月一张格子图。
public struct HeatmapModuleContent: Equatable, Sendable {
    public var months: [HeatmapMonth]

    public init(months: [HeatmapMonth]) {
        self.months = months
    }

    public var animationSignature: [Double] { months.flatMap(\.values).map { $0 ?? -1 } }
}

public struct HeatmapMonth: Identifiable, Equatable, Sendable {
    public var monthStart: Date
    /// 带年的写法。只给读屏用——卡上翻月是相邻的几个月，年份是噪音。
    public var title: String
    /// 卡上显示的写法：只有月份。
    public var monthTitle: String
    /// 每天的花费（美元），下标 = 日 - 1。nil = 那天没有读数（含未来）。
    public var values: [Double?]
    /// 1 号是一周里的第几格（按日历首日算），格子图从这一格开始画。
    public var leadingEmptyDays: Int
    /// 这个月的合计，屏幕上的写法。详情页一页列完每个月时要它。
    public var totalText: String
    public var spokenTotal: String
    public var peakCaption: String?
    /// 每天的写法（「8月17日」），下标和 `values` 对齐。
    ///
    /// **在折算侧排好，不留给视图自己算。**追查页原来拿 `Calendar.current` 从
    /// `monthStart` 往后数天再 `Date.formatted`，两处都绕开了注入的日历：
    /// 折算按注入日历切的月，展示按系统时区排的字，月末那一天会印成下个月 1 号。
    public var dayLabels: [String]

    public init(
        monthStart: Date,
        title: String,
        monthTitle: String,
        values: [Double?],
        leadingEmptyDays: Int,
        totalText: String,
        spokenTotal: String,
        peakCaption: String? = nil,
        dayLabels: [String] = []
    ) {
        self.monthStart = monthStart
        self.title = title
        self.monthTitle = monthTitle
        self.values = values
        self.leadingEmptyDays = leadingEmptyDays
        self.totalText = totalText
        self.spokenTotal = spokenTotal
        self.peakCaption = peakCaption
        self.dayLabels = dayLabels
    }

    /// 第 `index` 天（下标从 0 起）的写法。缺就回空串——视图不该为了一行字去算日期。
    public func dayLabel(at index: Int) -> String {
        dayLabels.indices.contains(index) ? dayLabels[index] : ""
    }

    public var id: Date { monthStart }
    public var maxValue: Double { values.compactMap { $0 }.max() ?? 0 }
}
