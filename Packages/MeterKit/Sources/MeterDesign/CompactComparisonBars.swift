import Charts
import SwiftUI

/// 两根柱：本月从量 / 上月同期。方卡里只撑个形状，数字在柱外面。
/// `isInteractive` 打开后按住出竖线 + 浮签，规格和详情页日柱图同一套
/// （竖线 tertiaryLabel 1pt、未选中柱压到 0.35、浮签是 [ChartCalloutLabel]）。
public struct CompactComparisonBars: View {
    public struct Bar: Identifiable {
        public var id: String
        public var label: String
        public var amount: Double
        public var isCurrent: Bool

        public init(id: String, label: String, amount: Double, isCurrent: Bool) {
            self.id = id
            self.label = label
            self.amount = amount
            self.isCurrent = isCurrent
        }
    }

    private let bars: [Bar]
    private let plotHeight: CGFloat
    private let accent: Color
    private let isInteractive: Bool
    @State private var selection: String?

    public init(
        current: Double,
        previous: Double?,
        currentLabel: String,
        previousLabel: String,
        plotHeight: CGFloat = MeterSpacing.bentoChart,
        accent: Color = .accentColor,
        isInteractive: Bool = false
    ) {
        var bars: [Bar] = []
        if let previous {
            bars.append(
                Bar(id: "previous", label: previousLabel, amount: max(previous, 0), isCurrent: false)
            )
        }
        bars.append(
            Bar(id: "current", label: currentLabel, amount: max(current, 0), isCurrent: true)
        )
        self.bars = bars
        self.plotHeight = plotHeight
        self.accent = accent
        self.isInteractive = isInteractive
    }

    public var body: some View {
        if isInteractive {
            chart.chartXSelection(value: $selection)
        } else {
            chart
        }
    }

    private var chart: some View {
        Chart {
            ForEach(bars) { bar in
                BarMark(
                    x: .value(String(localized: L("期间")), bar.label),
                    y: .value(String(localized: L("金额")), bar.amount)
                )
                .foregroundStyle(bar.isCurrent ? accent : Color.meterTertiaryLabel)
                .opacity(barOpacity(bar))
                .cornerRadius(MeterSpacing.xxs)
            }
            if let selected = selectedBar {
                RuleMark(x: .value(String(localized: L("期间")), selected.label))
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .zIndex(-1)
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: AnnotationOverflowResolution(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        ChartCalloutLabel(
                            title: selected.label,
                            valueText: ChartMoneyScale.detailLabel(selected.amount)
                        )
                    }
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label)
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .frame(height: plotHeight)
        .accessibilityHidden(true)
    }

    private var selectedBar: Bar? {
        guard isInteractive, let selection else { return nil }
        return bars.first { $0.label == selection }
    }

    private func barOpacity(_ bar: Bar) -> Double {
        guard let selected = selectedBar else { return 1 }
        return selected.id == bar.id ? 1 : 0.35
    }
}

#Preview("Light") {
    CompactComparisonBars(
        current: 47.2,
        previous: 29.1,
        currentLabel: String(localized: L("本月")),
        previousLabel: String(localized: L("上月"))
    )
    .padding(MeterSpacing.md)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    CompactComparisonBars(
        current: 47.2,
        previous: 29.1,
        currentLabel: String(localized: L("本月")),
        previousLabel: String(localized: L("上月"))
    )
    .padding(MeterSpacing.md)
    .preferredColorScheme(.dark)
}

#Preview("Interactive") {
    CompactComparisonBars(
        current: 47.2,
        previous: 29.1,
        currentLabel: String(localized: L("本月")),
        previousLabel: String(localized: L("上月")),
        plotHeight: MeterSpacing.donut,
        isInteractive: true
    )
    .padding(MeterSpacing.md)
}
