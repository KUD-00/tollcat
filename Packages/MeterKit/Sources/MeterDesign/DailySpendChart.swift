import Charts
import SwiftUI

/// 柱状图每根柱子是一个独立事实。缺的那天不画柱，绝对不要补 0。
/// 0 的意思是「这天没花钱」，缺失的意思是「我不知道」；插值等于凭空发明支出。
///
/// `xEnd` 是窗里最后一格的起点（当天 / 当月 1 号）。`BarMark(unit:)` 占满
/// `[这一格, 下一格)`，横轴若停在最后一格的起点，最后一根柱会画到图外。
public struct DailySpendChart: View {
    private let points: [PlotPoint]
    private let xStart: Date
    private let xEnd: Date
    private let unit: ChartTimeUnit
    private let visibleDayCount: Int?
    private let yMarks: [Double]
    @State private var rawSelection: Date?
    @Environment(\.calendar) private var calendar

    public init(
        points: [PlotPoint],
        xStart: Date,
        xEnd: Date,
        unit: ChartTimeUnit = .day,
        visibleDayCount: Int? = nil
    ) {
        self.points = points
        self.xStart = xStart
        self.xEnd = max(xEnd, xStart)
        self.unit = unit
        self.visibleDayCount = visibleDayCount
        self.yMarks = ChartMoneyScale.marks(max: points.map(\.amount).max() ?? 0)
    }

    /// 最后一格的柱要完整落在图里，右端取它的下一格起点。
    nonisolated public static func domainEnd(
        afterLastPeriodStart date: Date,
        unit: ChartTimeUnit,
        calendar: Calendar
    ) -> Date {
        let start = unit.bucket(date, calendar: calendar)
        switch unit {
        case .day:
            return calendar.date(byAdding: .day, value: 1, to: start) ?? start
        case .month:
            return calendar.date(byAdding: .month, value: 1, to: start) ?? start
        }
    }

    public var body: some View {
        Chart {
            ForEach(points) { point in
                BarMark(
                    x: .value(xLabel, point.date, unit: calendarUnit),
                    y: .value(String(localized: L("金额")), point.amount)
                )
                .foregroundStyle(Color.accentColor)
                .opacity(barOpacity(point))
            }
            if let inspection {
                RuleMark(x: .value(xLabel, inspection.date, unit: calendarUnit))
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .zIndex(-1)
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: AnnotationOverflowResolution(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        ChartInspectionLabel(date: inspection.date, amount: inspection.amount, unit: unit)
                    }
            }
        }
        .chartXScale(domain: xStart...plotEnd)
        .chartYScale(domain: 0...(yMarks.last ?? 1))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: unit == .month ? 6 : 4)) { value in
                AxisGridLine()
                if let date = value.as(Date.self), date >= xStart, date < plotEnd {
                    AxisValueLabel {
                        Text(date, format: xFormat)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: yMarks) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(ChartMoneyScale.label(amount))
                    }
                }
            }
        }
        .modifier(MeterChartScrolling(visibleDayCount: visibleDayCount, xStart: xStart, xEnd: xEnd))
        .modifier(MeterChartDaySelection(isScrollable: visibleDayCount != nil, selection: $rawSelection))
        .frame(height: MeterSpacing.chartPlot)
        .accessibilityHidden(true)
    }

    private var plotEnd: Date {
        Self.domainEnd(afterLastPeriodStart: xEnd, unit: unit, calendar: calendar)
    }

    private var inspection: ChartInspection? {
        ChartInspection.spend(raw: rawSelection, points: points, unit: unit, calendar: calendar)
    }

    private func barOpacity(_ point: PlotPoint) -> Double {
        guard let inspection else { return 1 }
        let selected = unit.bucket(point.date, calendar: calendar) == inspection.date
            && inspection.amount != nil
        return selected ? 1 : 0.35
    }

    private var xLabel: String {
        switch unit {
        case .day: String(localized: L("日"))
        case .month: String(localized: L("月"))
        }
    }

    private var calendarUnit: Calendar.Component {
        switch unit {
        case .day: .day
        case .month: .month
        }
    }

    private var xFormat: Date.FormatStyle {
        switch unit {
        case .day:
            .dateTime.month(.abbreviated).day()
        case .month:
            .dateTime.month(.abbreviated)
        }
    }
}

#Preview("Light") {
    DailySpendChart(
        points: DailySpendChartPreviewData.month,
        xStart: DailySpendChartPreviewData.start,
        xEnd: DailySpendChartPreviewData.end
    )
    .padding(MeterSpacing.md)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    DailySpendChart(
        points: DailySpendChartPreviewData.month,
        xStart: DailySpendChartPreviewData.start,
        xEnd: DailySpendChartPreviewData.end
    )
    .padding(MeterSpacing.md)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.dark)
}

#Preview("One day") {
    DailySpendChart(
        points: [PlotPoint(date: DailySpendChartPreviewData.start, amount: 2.2)],
        xStart: DailySpendChartPreviewData.start,
        xEnd: DailySpendChartPreviewData.end
    )
    .padding(MeterSpacing.md)
}

#Preview("Gaps") {
    DailySpendChart(
        points: DailySpendChartPreviewData.month,
        xStart: DailySpendChartPreviewData.start,
        xEnd: DailySpendChartPreviewData.end
    )
    .padding(MeterSpacing.md)
}

#Preview("Twelve months") {
    DailySpendChart(
        points: DailySpendChartPreviewData.year,
        xStart: DailySpendChartPreviewData.yearStart,
        xEnd: DailySpendChartPreviewData.yearEnd,
        unit: .month
    )
    .padding(MeterSpacing.md)
    .background(Color.meterGroupedBackground)
}

private enum DailySpendChartPreviewData {
    static let start = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2026, month: 8, day: 1)
    )!
    static let end = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2026, month: 8, day: 16)
    )!
    static let month: [PlotPoint] = {
        let calendar = Calendar(identifier: .gregorian)
        return (1...16).compactMap { day -> PlotPoint? in
            if day == 4 || day == 5 { return nil }
            guard let date = calendar.date(from: DateComponents(year: 2026, month: 8, day: day)) else {
                return nil
            }
            return PlotPoint(date: date, amount: day < 9 ? 0.5 : 2.2)
        }
    }()
    /// 和生产一样：窗的右端是月中的「今天」，不是下月 1 号。
    static let yearStart = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2025, month: 9, day: 1)
    )!
    static let yearEnd = end
    static let year: [PlotPoint] = {
        let calendar = Calendar(identifier: .gregorian)
        return (0..<12).compactMap { offset in
            calendar.date(byAdding: .month, value: offset, to: yearStart).map { date in
                PlotPoint(date: date, amount: Double([8, 14, 6, 18, 11, 16, 9, 13, 7, 15, 10, 12][offset]))
            }
        }
    }()
}
