import Charts
import SwiftUI

/// 预充值余额和「本月至今」观测都是连续量，用折线。
/// 两个已知点之间的变化真实存在、只是过程未知：那段用虚线，和实线必须能分开。
/// 只有一个点时只画点，不要拉一条占满图的线。
/// `isolate` 把不同日历单位的点拆开（本月至今跨月断开），不要连成假的下降。
public struct BalanceLineChart: View {
    private let points: [PlotPoint]
    private let inferred: [PlotSegment]
    private let xStart: Date
    private let xEnd: Date
    private let unit: ChartTimeUnit
    private let isolate: Calendar.Component?
    private let visibleDayCount: Int?
    private let yMarks: [Double]
    @State private var rawSelection: Date?
    @Environment(\.calendar) private var calendar

    public init(
        points: [PlotPoint],
        xStart: Date,
        xEnd: Date,
        inferred: [PlotSegment] = [],
        unit: ChartTimeUnit = .day,
        isolate: Calendar.Component? = nil,
        visibleDayCount: Int? = nil
    ) {
        self.points = points.sorted { $0.date < $1.date }
        self.inferred = inferred
        self.xStart = xStart
        self.xEnd = max(xEnd, xStart)
        self.unit = unit
        self.isolate = isolate
        self.visibleDayCount = visibleDayCount
        self.yMarks = ChartMoneyScale.marks(max: points.map(\.amount).max() ?? 0)
    }

    public var body: some View {
        Chart {
            if points.count >= 2 {
                ForEach(solidPairs.indices, id: \.self) { index in
                    let pair = solidPairs[index]
                    LineMark(
                        x: .value(xLabel, pair.start.date),
                        y: .value(String(localized: L("金额")), pair.start.amount),
                        series: .value(String(localized: L("已知")), "solid-\(index)")
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.linear)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    LineMark(
                        x: .value(xLabel, pair.end.date),
                        y: .value(String(localized: L("金额")), pair.end.amount),
                        series: .value(String(localized: L("已知")), "solid-\(index)")
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.linear)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                ForEach(inferred) { segment in
                    LineMark(
                        x: .value(xLabel, segment.start.date),
                        y: .value(String(localized: L("金额")), segment.start.amount),
                        series: .value(String(localized: L("推断")), segment.id)
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.linear)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    LineMark(
                        x: .value(xLabel, segment.end.date),
                        y: .value(String(localized: L("金额")), segment.end.amount),
                        series: .value(String(localized: L("推断")), segment.id)
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.linear)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                }
            }
            ForEach(points) { point in
                PointMark(
                    x: .value(xLabel, point.date),
                    y: .value(String(localized: L("金额")), point.amount)
                )
                .foregroundStyle(Color.accentColor)
                .symbolSize(pointSymbolSize(point))
            }
            if let inspection {
                RuleMark(x: .value(xLabel, inspection.date))
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
        .chartXScale(domain: xStart...xEnd)
        .chartYScale(domain: 0...(yMarks.last ?? 1))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: unit == .month ? 6 : 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
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

    private var inspection: ChartInspection? {
        ChartInspection.balance(raw: rawSelection, points: points, unit: unit, calendar: calendar)
    }

    private func pointSymbolSize(_ point: PlotPoint) -> CGFloat {
        guard let inspection else { return 40 }
        return unit.bucket(point.date, calendar: calendar) == inspection.date ? 80 : 40
    }

    private var solidPairs: [(start: PlotPoint, end: PlotPoint)] {
        guard points.count >= 2 else { return [] }
        let inferredKeys = Set(inferred.map { "\($0.start.date.timeIntervalSince1970)-\($0.end.date.timeIntervalSince1970)" })
        return zip(points, points.dropFirst()).compactMap { start, end in
            let key = "\(start.date.timeIntervalSince1970)-\(end.date.timeIntervalSince1970)"
            if inferredKeys.contains(key) { return nil }
            if let isolate, !calendar.isDate(start.date, equalTo: end.date, toGranularity: isolate) {
                return nil
            }
            return (start, end)
        }
    }

    private var xLabel: String {
        switch unit {
        case .day: String(localized: L("日"))
        case .month: String(localized: L("月"))
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
    BalanceLineChart(
        points: BalanceLineChartPreviewData.points,
        xStart: BalanceLineChartPreviewData.start,
        xEnd: BalanceLineChartPreviewData.end,
        inferred: [
            PlotSegment(
                start: BalanceLineChartPreviewData.points[0],
                end: BalanceLineChartPreviewData.points[1],
                isInferred: true
            ),
        ]
    )
    .padding(MeterSpacing.md)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    BalanceLineChart(
        points: BalanceLineChartPreviewData.points,
        xStart: BalanceLineChartPreviewData.start,
        xEnd: BalanceLineChartPreviewData.end,
        inferred: [
            PlotSegment(
                start: BalanceLineChartPreviewData.points[1],
                end: BalanceLineChartPreviewData.points[2],
                isInferred: true
            ),
        ]
    )
    .padding(MeterSpacing.md)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.dark)
}

#Preview("One point") {
    BalanceLineChart(
        points: [PlotPoint(date: BalanceLineChartPreviewData.end, amount: 42)],
        xStart: BalanceLineChartPreviewData.start,
        xEnd: BalanceLineChartPreviewData.end
    )
    .padding(MeterSpacing.md)
}

private enum BalanceLineChartPreviewData {
    static let start = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2026, month: 8, day: 1)
    )!
    static let mid = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2026, month: 8, day: 9)
    )!
    static let end = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2026, month: 8, day: 16)
    )!
    static let points = [
        PlotPoint(date: start, amount: 49.62),
        PlotPoint(date: mid, amount: 58.33),
        PlotPoint(date: end, amount: 42),
    ]
}
