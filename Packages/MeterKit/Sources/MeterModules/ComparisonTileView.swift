import SwiftUI
import MeterCore
import MeterDesign

public struct ComparisonTileView: View {
    public let content: ComparisonModuleContent
    public var showsDisclosure: Bool = false

    public init(content: ComparisonModuleContent, showsDisclosure: Bool = false) {
        self.content = content
        self.showsDisclosure = showsDisclosure
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xs) {
                Text(L("较上月同期"))
                    .font(MeterFont.caption)
                    .foregroundStyle(Color.meterSecondaryLabel)
                Spacer(minLength: 0)
                if showsDisclosure {
                    Image(systemName: "chevron.right")
                        .font(MeterFont.caption.weight(.semibold))
                        .foregroundStyle(Color.meterTertiaryLabel)
                        .accessibilityHidden(true)
                }
            }
            // 「含还不能对比」那句挪进详情页语境里去了；方卡只留主角百分比。
            Text(content.percentText)
                .font(MeterFont.largeTitle.weight(.semibold))
                .foregroundStyle(percentColor)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Spacer(minLength: 0)
            if content.tone != .unknown || content.current > 0 {
                CompactComparisonBars(
                    current: content.current,
                    previous: content.tone == .unknown ? nil : content.previous,
                    currentLabel: content.currentLabel,
                    previousLabel: content.previousLabel
                )
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(MeterSpacing.md)
        .background(
            Color.meterSecondaryGroupedBackground,
            in: RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.spokenLabel)
    }

    private var percentColor: Color {
        switch content.tone {
        case .up: MeterColor.warn
        case .down: MeterColor.good
        case .flat, .unknown: Color.meterLabel
        }
    }
}

#Preview("Light") {
    ComparisonTileView(content: ComparisonTilePreview.up)
        .frame(width: 170, height: 170)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ComparisonTileView(
        content: ComparisonModuleContent(
            percentText: "—",
            caption: String(localized: L("还不能对比")),
            spokenLabel: String(localized: L("还不能和上月同期对比")),
            current: 0,
            previous: 0,
            currentLabel: String(localized: L("本月")),
            previousLabel: String(localized: L("上月")),
            tone: .unknown
        )
    )
    .frame(width: 170, height: 170)
    .preferredColorScheme(.dark)
}

private enum ComparisonTilePreview {
    static let caption = String(localized: L("对比 \("7 月")同期 \("$29.10")"))
    static let up = ComparisonModuleContent(
        percentText: "+62%",
        caption: caption,
        spokenLabel: String(localized: L("按量较上月同期 \(DashboardPercentFormat.spokenSigned(0.62))，\(caption)")),
        current: 47.2,
        previous: 29.1,
        currentLabel: String(localized: L("本月")),
        previousLabel: String(localized: L("上月")),
        tone: .up
    )
}
