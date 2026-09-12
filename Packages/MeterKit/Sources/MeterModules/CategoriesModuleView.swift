import SwiftUI
import MeterCore
import MeterDesign

/// 「按类别构成」：和首屏构成同一副圆环加图例，只是段是类别。色板同一套（indigo 梯度 + 灰）。
public struct CategoriesModuleView: View {
    public let content: CategoriesModuleContent
    /// 卡里用小一号，手机列表里用默认。
    public var donutSize: CGFloat = MeterSpacing.donutTile

    public init(content: CategoriesModuleContent, donutSize: CGFloat = MeterSpacing.donutTile) {
        self.content = content
        self.donutSize = donutSize
    }
    @Environment(\.moduleWidth) private var width
    @Environment(\.moduleHeight) private var height
    /// 点不动的容器（分享卡、widget）不画 chevron，也不做成链接。
    @Environment(\.moduleContainer) private var container
    /// 壳注入了推法才做成链接。没注入（预览、组件库）照样把圆环画出来——
    /// 整块就是内容，外壳没了内容不能跟着没。
    @Environment(\.moduleLinkStyle) private var linkStyle

    private var isLinked: Bool { container.isInteractive && linkStyle != nil }

    /// 整块是一个链接，右上角一颗 chevron——和「较上月同期」那张方卡同一套。
    public var body: some View {
        if isLinked {
            ModuleInlineLink(route: .categories) {
                card(showsChevron: true)
            }
            .accessibilityHint(L("查看每个类别的花费"))
        } else {
            card(showsChevron: false)
        }
    }

    private func card(showsChevron: Bool) -> some View {
        HStack(alignment: .top, spacing: MeterSpacing.xs) {
            VStack(alignment: .leading, spacing: MeterSpacing.sm) {
                // 卡里那行数字是为了和别的 bento 卡对齐第一行（见 `CompositionTileView`）。
                if height.prefersCardMetrics, let top = content.slices.first {
                    DashboardCardHeadline(
                        value: "\(top.percent)%",
                        caption: String(localized: L("\(String(localized: top.title)) 占最多")),
                        animationValue: Double(top.percent)
                    )
                }
                donutAndLegend
            }
            // 贴右上角，不跟着整块居中：这一块高，居中的箭头会落在圆环的腰上。
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(MeterFont.footnote.weight(.semibold))
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.spokenLabel)
        .animation(DashboardMotion.number, value: content.animationSignature)
    }

    private var donutAndLegend: some View {
        HStack(alignment: .center, spacing: MeterSpacing.md) {
            CompositionDonut(
                slices: donutSlices,
                showsLegend: false,
                // 定高卡里圆环小一号才和图例并排装得下；手机 List 行不封顶，用整只。
                size: height.prefersCardMetrics ? donutSize : MeterSpacing.donut
            )
            VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                ForEach(Array(content.slices.enumerated()), id: \.element.id) { index, slice in
                    HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xs) {
                        Circle()
                            .fill(color(at: index))
                            .frame(width: MeterSpacing.compositionSwatch, height: MeterSpacing.compositionSwatch)
                            .accessibilityHidden(true)
                        Text(slice.title)
                            .font(MeterFont.subheadline)
                            .foregroundStyle(Color.meterLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        // 挤到 compact 时只留类别名：圆环旁边剩不到 100pt，
                        // 名字和金额并排会双双缩成省略号，不如让金额去详情页。
                        if width > .compact {
                            Spacer(minLength: MeterSpacing.xs)
                            Text(slice.amountText)
                                .font(MeterFont.subheadline)
                                .foregroundStyle(Color.meterSecondaryLabel)
                                .monospacedDigit()
                                .lineLimit(1)
                        } else {
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var donutSlices: [CompositionDonut.Slice] {
        content.slices.enumerated().map { index, slice in
            CompositionDonut.Slice(
                id: slice.category.rawValue,
                color: color(at: index),
                fraction: slice.fraction,
                name: String(localized: slice.title),
                amountText: slice.amountText,
                mergedNames: slice.memberNames
            )
        }
    }

    private func color(at index: Int) -> Color {
        index < MeterColor.compositionNamedLimit ? MeterColor.composition(index: index) : MeterColor.compositionOther
    }
}

#Preview("Light") {
    NavigationStack {
        List {
            Section {
                CategoriesModuleView(content: CategoriesPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        List {
            Section {
                CategoriesModuleView(content: CategoriesPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.dark)
}

public enum CategoriesPreviewData {
    public static let sample = CategoriesModuleContent(
        slices: [
            CategorySlice(category: .hosting, amountText: "$21.40", fraction: 0.55, percent: 55, colorKey: "aws", memberNames: ["AWS", "Vercel"]),
            CategorySlice(category: .aiInference, amountText: "$7.62", fraction: 0.20, percent: 20, colorKey: "openai", memberNames: ["OpenAI"]),
            CategorySlice(category: .networkEdge, amountText: "$11.05", fraction: 0.25, percent: 25, colorKey: "cloudflare", memberNames: ["Cloudflare"]),
        ],
        spokenLabel: "托管与算力 55%，AI 推理 20%，网络与边缘 25%"
    )
}
