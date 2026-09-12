import SwiftUI
import MeterDesign
import MeterFormat

struct ProviderHistoryChartView: View {
    let content: ProviderHistoryChartContent
    var visibleDayCount: Int? = nil
    @State private var visibleStart: Date?
    @Environment(\.calendar) private var calendar

    var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            if let caption = windowCaption {
                Text(caption)
                    .font(MeterFont.caption)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .contentTransition(.numericText())
                    .accessibilityHidden(true)
            }
            plot
            if let note = content.readingNote {
                Text(note)
                    .font(MeterFont.caption)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .animation(.snappy, value: windowCaption)
        .onPreferenceChange(ChartVisibleStartPreference.self) { visibleStart = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(spokenCaption ?? windowCaption ?? "")
        .accessibilityHint(accessibilityHint)
    }

    @ViewBuilder
    private var plot: some View {
        switch content {
        case .spend(let points, let start, let end, let granularity, _):
            if points.isEmpty {
                Text(L("还没有每日花费"))
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Color.meterSecondaryLabel)
            } else {
                DailySpendChart(
                    points: points,
                    xStart: start,
                    xEnd: end,
                    unit: granularity.chartUnit,
                    visibleDayCount: visibleDayCount
                )
                .accessibilityHidden(true)
            }
        case .balance(let points, let start, let end, let granularity, let inferred):
            if points.isEmpty {
                Text(L("还没有余额记录"))
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Color.meterSecondaryLabel)
            } else {
                BalanceLineChart(
                    points: points,
                    xStart: start,
                    xEnd: end,
                    inferred: inferred,
                    unit: granularity.chartUnit,
                    visibleDayCount: visibleDayCount
                )
                .accessibilityHidden(true)
            }
        case .none:
            EmptyView()
        }
    }

    private var visibleWindow: (start: Date, end: Date, granularity: HistoryGranularity)? {
        guard let window = content.plotWindow else { return nil }
        if let days = visibleDayCount {
            let start = visibleStart
                ?? calendar.date(byAdding: .day, value: 1 - days, to: window.end)
                ?? window.end
            let end = calendar.date(byAdding: .day, value: days - 1, to: start) ?? start
            return (start, end, .day)
        }
        return window
    }

    private var windowCaption: String? {
        guard let window = visibleWindow else { return nil }
        switch window.granularity {
        case .day:
            return MeterDateFormat.period(from: window.start, to: window.end, calendar: calendar)
        case .month:
            return MeterDateFormat.monthRange(from: window.start, to: window.end, calendar: calendar)
        }
    }

    private var spokenCaption: String? {
        guard let window = visibleWindow else { return nil }
        switch window.granularity {
        case .day:
            return MeterDateFormat.spokenPeriod(
                from: window.start,
                to: window.end,
                calendar: calendar
            )
        case .month:
            return MeterDateFormat.monthRange(from: window.start, to: window.end, calendar: calendar)
        }
    }

    private var accessibilityLabel: String {
        switch content {
        case .spend(let points, _, _, let granularity, _):
            switch granularity {
            case .day:
                return String(localized: L("每日花费柱形图，\(points.count) 天有读数"))
            case .month:
                return String(localized: L("每月花费柱形图，\(points.count) 个月有读数"))
            }
        case .balance(let points, _, _, _, _):
            return String(localized: L("余额折线图，\(points.count) 个读数"))
        case .none:
            return ""
        }
    }

    private var accessibilityHint: LocalizedStringResource {
        if visibleDayCount != nil {
            L("左右滑动查看更早的用量。点一下查看对应日期的金额。")
        } else {
            L("按住查看对应日期的金额")
        }
    }
}

#Preview("Light") {
    ProviderHistoryChartView(
        content: .spend(
            points: DailySpendChartPreviewPoints.month,
            start: DailySpendChartPreviewPoints.start,
            end: DailySpendChartPreviewPoints.end,
            granularity: .day,
            isIntervalSpend: false
        ),
        visibleDayCount: 7
    )
    .padding(MeterSpacing.md)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    ProviderHistoryChartView(
        content: .spend(
            points: DailySpendChartPreviewPoints.month,
            start: DailySpendChartPreviewPoints.start,
            end: DailySpendChartPreviewPoints.end,
            granularity: .day,
            isIntervalSpend: false
        ),
        visibleDayCount: 7
    )
    .padding(MeterSpacing.md)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.dark)
}

private enum DailySpendChartPreviewPoints {
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
}
