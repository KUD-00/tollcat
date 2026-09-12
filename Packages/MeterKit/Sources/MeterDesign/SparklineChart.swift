import SwiftUI
import Charts

/// 迷你走势：一条线、一个末点，没有坐标轴。只表示方向，不标数。
public struct SparklineChart: View {
    private let values: [Double]

    public init(values: [Double]) {
        self.values = values
    }

    public var body: some View {
        Chart {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value(String(localized: L("月")), index),
                    y: .value(String(localized: L("金额")), value)
                )
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .foregroundStyle(Color.accentColor)
            }
            if let last = values.indices.last {
                PointMark(
                    x: .value(String(localized: L("月")), last),
                    y: .value(String(localized: L("金额")), values[last])
                )
                .symbolSize(18)
                .foregroundStyle(Color.accentColor)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartYScale(domain: 0...max((values.max() ?? 0) * 1.15, 0.01))
        .chartXScale(domain: 0...max(values.count - 1, 1))
        .accessibilityHidden(true)
    }
}

#Preview("Light") {
    SparklineChart(values: [2, 5, 3, 8, 6, 9])
        .frame(width: 72, height: 24)
        .padding()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SparklineChart(values: [0, 0, 1, 0.5, 2, 1.5])
        .frame(width: 72, height: 24)
        .padding()
        .preferredColorScheme(.dark)
}
