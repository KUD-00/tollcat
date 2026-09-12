import SwiftUI
import MeterDesign

/// 宽壳上的构成卡：两格宽，圆环加图例，右上角 chevron 表示整张能点。
public struct CompositionTileView: View {
    public let content: CompositionModuleContent

    public init(content: CompositionModuleContent) {
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            HStack {
                Text(L("构成"))
                    .font(MeterFont.caption)
                    .foregroundStyle(Color.meterSecondaryLabel)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(MeterFont.footnote.weight(.semibold))
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .accessibilityHidden(true)
            }
            // 圆环上面这行数字是为了让 bento 里每张卡的第一行都落在同一条基线上——
            // 别的卡都有 headline，这张缺一行就整行错位。删过一次，更丑。
            if let top = content.segments.max(by: { $0.fraction < $1.fraction }) {
                DashboardCardHeadline(
                    value: "\(top.percent)%",
                    caption: String(localized: L("\(top.displayName) 占最多")),
                    animationValue: Double(top.percent)
                )
            }
            Spacer(minLength: 0)
            CompositionModuleView(content: content, donutSize: MeterSpacing.donutTile)
            Spacer(minLength: 0)
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(MeterSpacing.md)
        .background(
            Color.meterSecondaryGroupedBackground,
            in: RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous))
    }
}

#Preview("Light") {
    CompositionTileView(content: CompositionPreviewData.sample)
        .frame(width: 520, height: MeterSpacing.dashboardTileHeight)
        .padding()
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CompositionTileView(content: CompositionPreviewData.sample)
        .frame(width: 520, height: MeterSpacing.dashboardTileHeight)
        .padding()
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.dark)
}
