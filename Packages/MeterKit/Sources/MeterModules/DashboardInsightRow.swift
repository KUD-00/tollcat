import SwiftUI
import MeterDesign

/// 洞察行：glyph / 标题+副标题 / 数值 /（NavigationLink 自带 chevron）各自成列。
///
/// 不要把数值塞进标题那一行再靠 Spacer 推过去——VStack 若没拿到满宽，
/// 不同标题长度会把右侧数值挤到不同的 x。
/// 也不要把 `maxWidth: .infinity` 加在只有一个 Text 的 VStack 上，
/// 宽度提议会被压窄并从左侧裁掉首字母。
public struct DashboardInsightRow: View {
    public var colorKey: String?
    public var title: String
    public var subtitle: String
    public var trailingText: String
    public var trailingColor: Color
    public var spokenLabel: String
    public var animationValue: Double

    public init(
        colorKey: String? = nil,
        title: String,
        subtitle: String,
        trailingText: String,
        trailingColor: Color,
        spokenLabel: String,
        animationValue: Double
    ) {
        self.colorKey = colorKey
        self.title = title
        self.subtitle = subtitle
        self.trailingText = trailingText
        self.trailingColor = trailingColor
        self.spokenLabel = spokenLabel
        self.animationValue = animationValue
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.moduleWidth) private var width
    @Environment(\.moduleContainer) private var container
    /// Mac 列里的链接行自带 chevron，别再叠一颗。
    @Environment(\.moduleRowChromeFromLink) private var rowChromeFromLink

    public var body: some View {
        HStack(alignment: .center, spacing: MeterSpacing.sm) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    stacked
                } else {
                    columns
                }
            }
            // List 行的 chevron 由系统补；bento 卡里没有那层，自己画一颗同款。
            // Mac 列里的链接行（`MeterColumnLink`）自带 chevron，别再叠一颗。
            // 渲成图时（分享卡、widget）一颗都不画：那上面点不动，箭头是假线索。
            if container.drawsOwnChevron, !rowChromeFromLink {
                Image(systemName: "chevron.right")
                    .font(MeterFont.footnote.weight(.semibold))
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .accessibilityHidden(true)
            }
        }
        // 行高也是 List 补的那一层。卡和图上得自己撑到能点的高度。
        .frame(minHeight: container.suppliesRowChrome ? 0 : MeterSpacing.minTap)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
    }

    private var columns: some View {
        HStack(alignment: .center, spacing: MeterSpacing.sm) {
            if showsGlyph { glyph }
            textColumn
            trailing
        }
    }

    /// 挤到 compact（侧栏卡、widget small、被压到 0.75 格的 bento 卡）就收掉图标：
    /// 它连间距是 36pt，在 190pt 宽里足以决定标题是完整读出还是缩成省略号。
    /// 这一行的身份本来就由名字承担，图标是同一件事说第二遍。
    private var showsGlyph: Bool { width > .compact }

    private var stacked: some View {
        HStack(alignment: .top, spacing: MeterSpacing.sm) {
            if showsGlyph { glyph }
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(title)
                    .font(MeterFont.body)
                    .foregroundStyle(Color.meterLabel)
                trailing
                Text(subtitle)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var glyph: some View {
        ProviderGlyph(
            colorKey: colorKey ?? "unknown",
            accessibilityName: title
        )
        .frame(width: MeterSpacing.providerGlyph, alignment: .center)
    }

    /// 两个 Text 才把 maxWidth 加在 VStack 上，避免单行被兄弟节点挤窄。
    private var textColumn: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            Text(title)
                .font(MeterFont.body)
                .foregroundStyle(Color.meterLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(MeterFont.footnote)
                .foregroundStyle(Color.meterSecondaryLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trailing: some View {
        Text(trailingText)
            .font(MeterFont.body)
            .foregroundStyle(trailingColor)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .multilineTextAlignment(.trailing)
            .contentTransition(.numericText(value: animationValue))
    }
}

#Preview("Light") {
    List {
        Section {
            DashboardInsightRow(
                colorKey: "aws",
                title: "AWS",
                subtitle: String(localized: L("对比 7 月同期 $13.20")),
                trailingText: "+62%",
                trailingColor: MeterColor.warn,
                spokenLabel: String(localized: L("AWS 较上月同期上升百分之 62")),
                animationValue: 62
            )
            DashboardInsightRow(
                colorKey: "openai",
                title: "OpenAI",
                subtitle: String(localized: L("余额 $42.00")),
                trailingText: String(localized: L("18 天")),
                trailingColor: Color.meterSecondaryLabel,
                spokenLabel: String(localized: L("OpenAI 余额 42 美元，还能用 18 天")),
                animationValue: 18
            )
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        Section {
            DashboardInsightRow(
                colorKey: "vercel",
                title: "Vercel",
                subtitle: String(localized: L("免费额度")),
                trailingText: "84%",
                trailingColor: Color.meterSecondaryLabel,
                spokenLabel: String(localized: L("Vercel 免费额度用了百分之 84")),
                animationValue: 84
            )
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("XXL") {
    List {
        Section {
            DashboardInsightRow(
                colorKey: "openai",
                title: "ChatGPT Plus",
                subtitle: String(localized: L("8 月 20 日")),
                trailingText: "$20.00",
                trailingColor: Color.meterSecondaryLabel,
                spokenLabel: String(localized: L("ChatGPT Plus 20 美元，8 月 20 日扣款")),
                animationValue: 20
            )
        }
    }
    .dynamicTypeSize(.accessibility3)
}
