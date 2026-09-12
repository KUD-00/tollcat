import SwiftUI

/// 一个月的花费热力格：一格一天，一列一周，不标日期、不标星期。
/// 参照 GitHub 的贡献图——颜色深浅就是全部信息。
public struct SpendHeatmapGrid: View {
    /// 每天的值，下标 = 日 - 1。nil = 那天没有读数（含未来），画成空。
    private let values: [Double?]
    /// 1 号前面要空几格（1 号是一周里的第几天）。
    private let leadingEmptyDays: Int
    private let maxValue: Double

    public init(values: [Double?], leadingEmptyDays: Int, maxValue: Double) {
        self.values = values
        self.leadingEmptyDays = max(0, min(leadingEmptyDays, 6))
        self.maxValue = maxValue
    }

    private var cells: [Double??] {
        Array(repeating: .some(nil), count: leadingEmptyDays) + values.map { .some($0) }
    }

    private var weeks: [[Double??]] {
        let all = cells
        return stride(from: 0, to: all.count, by: 7).map { start in
            Array(all[start..<min(start + 7, all.count)])
        }
    }

    public var body: some View {
        HStack(alignment: .top, spacing: MeterSpacing.heatGap) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                VStack(spacing: MeterSpacing.heatGap) {
                    ForEach(0..<7, id: \.self) { row in
                        cell(row < week.count ? week[row] : nil)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func cell(_ value: Double??) -> some View {
        RoundedRectangle(cornerRadius: MeterRadius.heatCell, style: .continuous)
            .fill(fill(for: value))
            .frame(width: MeterSpacing.heatCell, height: MeterSpacing.heatCell)
    }

    /// 四档深浅，按占当月最高的比例分。月初前的占位格透明；还没到的日子淡淡画出来，
    /// 整月的形状才在；有读数但为 0 用底色。
    private func fill(for value: Double??) -> Color {
        guard let value else { return Color.clear }
        guard let value else { return Color.meterTertiarySystemFill.opacity(0.4) }
        guard value > 0, maxValue > 0 else { return Color.meterTertiarySystemFill }
        let ratio = value / maxValue
        let level: Double = ratio > 0.75 ? 1 : ratio > 0.5 ? 0.75 : ratio > 0.25 ? 0.5 : 0.3
        return Color.accentColor.opacity(level)
    }
}

#Preview("Light") {
    SpendHeatmapGrid(
        values: (1...30).map { day in day > 20 ? nil : Double(day % 7) * 1.7 },
        leadingEmptyDays: 2,
        maxValue: 10.2
    )
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    SpendHeatmapGrid(
        values: (1...31).map { day in Double((day * 7) % 11) },
        leadingEmptyDays: 5,
        maxValue: 10
    )
    .padding()
    .preferredColorScheme(.dark)
}
