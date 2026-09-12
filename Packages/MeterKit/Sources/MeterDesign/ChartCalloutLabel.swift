import SwiftUI

/// 图表选中态跟着走的那块浮签：标题 + 值，值缺席时说「无数据」。
/// 柱状图的竖线、余额线、圆环选段共用这一块——浮签样式只在这里定一次。
struct ChartCalloutLabel: View {
    var title: String
    var valueText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            Text(title)
                .font(MeterFont.caption)
                .foregroundStyle(Color.meterSecondaryLabel)
            if let valueText {
                Text(valueText)
                    .font(MeterFont.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(Color.meterLabel)
            } else {
                Text(L("无数据"))
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Color.meterSecondaryLabel)
            }
        }
        .padding(.horizontal, MeterSpacing.xs)
        .padding(.vertical, MeterSpacing.xxs)
        // 玻璃只属于系统导航层（ARCHITECTURE.md），内容浮层用实底语义色。
        .background(Color.meterSecondarySystemBackground, in: RoundedRectangle(cornerRadius: MeterRadius.searchField, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    VStack(spacing: MeterSpacing.sm) {
        ChartCalloutLabel(title: "8月", valueText: "$21.40")
        ChartCalloutLabel(title: "8月4日", valueText: nil)
    }
    .padding(MeterSpacing.md)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    ChartCalloutLabel(title: "AWS", valueText: "$21.40")
        .padding(MeterSpacing.md)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.dark)
}
