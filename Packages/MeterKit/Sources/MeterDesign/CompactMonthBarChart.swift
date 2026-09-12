import Charts
import SwiftUI

/// 仪表方卡里的近几个月。没有选择、没有 Y 轴——地方不够，按住看数去构成页也不对。
/// 缺的月份不画柱。横轴每个整月都标：方卡只有几根柱，抽稀会让人去数格子；
/// 英文窄格式 `J` / `M` / `A` 本身就不唯一，少标几个更对不上。
///
/// `xEnd` 必须是最后一个月的**下月 1 号**。`BarMark(unit: .month)` 占满 `[本月 1 号, 下月 1 号)`，
/// 横轴若停在本月 1 号，本月柱会画到卡外面。
public struct CompactMonthBarChart: View {
    private let points: [PlotPoint]
    private let xStart: Date
    private let xEnd: Date
    private let highlight: Date?
    private let plotHeight: CGFloat
    private let accent: Color
    @Environment(\.calendar) private var calendar

    public init(
        points: [PlotPoint],
        xStart: Date,
        xEnd: Date,
        highlight: Date? = nil,
        plotHeight: CGFloat = MeterSpacing.bentoChart,
        accent: Color = .accentColor
    ) {
        self.points = points
        self.xStart = xStart
        self.xEnd = max(xEnd, xStart)
        self.highlight = highlight
        self.plotHeight = plotHeight
        self.accent = accent
    }

    /// 最后一个月的柱要完整落在图里，右端取它的下月 1 号。
    nonisolated public static func domainEnd(afterLastMonthStart date: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .month, value: 1, to: date) ?? date
    }

    /// 每个整月一个刻度，不含横轴右端。右端是最后一根柱的尽头，标上去会多一个月。
    nonisolated static func monthLabels(from start: Date, to end: Date, calendar: Calendar) -> [Date] {
        var date = calendar.date(from: calendar.dateComponents([.year, .month], from: start)) ?? start
        var labels: [Date] = []
        while date < end {
            labels.append(date)
            guard let next = calendar.date(byAdding: .month, value: 1, to: date), next > date else { break }
            date = next
        }
        return labels
    }

    public var body: some View {
        Chart {
            ForEach(points) { point in
                BarMark(
                    x: .value(String(localized: L("月")), point.date, unit: .month),
                    y: .value(String(localized: L("金额")), point.amount)
                )
                .foregroundStyle(accent)
                .opacity(isHighlighted(point) ? 1 : 0.4)
                .cornerRadius(MeterSpacing.xxs)
            }
        }
        .chartXScale(domain: xStart...xEnd)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(preset: .aligned, values: Self.monthLabels(from: xStart, to: xEnd, calendar: calendar)) { value in
                // 默认碰撞会把贴边的首尾月藏掉，高亮那根反而没字。
                AxisValueLabel(centered: true, collisionResolution: .disabled) {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.month(.narrow))
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .chartPlotStyle { plot in
            plot.clipped()
        }
        .frame(height: plotHeight)
        .clipped()
        .accessibilityHidden(true)
    }

    private func isHighlighted(_ point: PlotPoint) -> Bool {
        guard let highlight else { return true }
        return calendar.isDate(point.date, equalTo: highlight, toGranularity: .month)
    }
}

#Preview("Light") {
    CompactMonthBarChart(
        points: CompactMonthBarPreview.points,
        xStart: CompactMonthBarPreview.start,
        xEnd: CompactMonthBarPreview.end,
        highlight: CompactMonthBarPreview.lastMonth
    )
    .padding(MeterSpacing.md)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    CompactMonthBarChart(
        points: CompactMonthBarPreview.points,
        xStart: CompactMonthBarPreview.start,
        xEnd: CompactMonthBarPreview.end,
        highlight: CompactMonthBarPreview.lastMonth
    )
    .padding(MeterSpacing.md)
    .preferredColorScheme(.dark)
}

private enum CompactMonthBarPreview {
    static let lastMonth = Date(timeIntervalSince1970: 1_787_616_000)
    static let start: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(byAdding: .month, value: -5, to: lastMonth) ?? lastMonth
    }()
    static let end: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return CompactMonthBarChart.domainEnd(afterLastMonthStart: lastMonth, calendar: calendar)
    }()
    static let points: [PlotPoint] = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return [12, 18, 9, 22, 15, 21].enumerated().compactMap { index, amount in
            calendar.date(byAdding: .month, value: index, to: start).map {
                PlotPoint(date: $0, amount: Double(amount))
            }
        }
    }()
}
