import SwiftUI
import MeterCore
import MeterDesign

/// 「固定订阅」：一个数、最贵的三笔，整块点进去看全部。
/// 卡里不解释口径、不预告下一笔——那些在详情页里。
public struct SubscriptionsModuleView: View {
    public let content: SubscriptionsModuleContent

    public init(content: SubscriptionsModuleContent) {
        self.content = content
    }
    @Environment(\.moduleHeight) private var height

    /// 列几笔按高度收。medium 的 widget 是 `.tight` 档（内容才 126pt 高），
    /// 大数字加三行会被裁掉最后一笔——裁掉的那笔看起来就像不存在。
    private var rowLimit: Int {
        switch height {
        case .tight: 1
        case .regular: 3
        case .tall, .unbounded: 6
        }
    }
    /// 点不动的容器（分享卡、widget）不画「查看更多」：那一行点不动。
    @Environment(\.moduleContainer) private var container

    /// 「查看更多」头上留多少，照容器脚下留多少配：卡的内边距是 `md`，
    /// List 行的默认上下内边距是 11 —— `sm` 是离它最近的一档。
    private var moreLinkSpacing: CGFloat {
        container == .card ? MeterSpacing.md : MeterSpacing.sm
    }

    /// 内容和「查看更多」必须包在同一个 VStack 里。分成两截时手机上 List 会把它们
    /// 拆成两行，各自垫一次行内边距，「查看更多」头上就比脚下多出一倍空白
    /// （11 + 11 + 8 对 11）；包成一行之后，头上是 `moreLinkSpacing`、脚下是容器内边距。
    public var body: some View {
        VStack(alignment: .leading, spacing: moreLinkSpacing) {
            rows
            // 全部订阅在详情页；卡里一行「查看更多」进去，不让整张卡带 chevron。
            if container.isInteractive {
                ModuleInlineLink(route: .subscriptions) {
                    MeterInlineLinkLabel(Text(L("查看更多")))
                }
                .accessibilityHint(L("查看全部订阅"))
            }
        }
    }

    /// 数字和最贵的几笔。整块合成一个 a11y 元素，所以「查看更多」不能进来——
    /// 进来就被 `children: .ignore` 吞掉，VoiceOver 里再也走不到那颗链接。
    private var rows: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.sm) {
            DashboardCardHeadline(
                value: content.monthlyTotalText,
                caption: content.headlineCaption,
                captionPlacement: .trailing,
                animationValue: content.monthlyTotalValue
            )
            VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                ForEach(content.items.prefix(rowLimit)) { item in
                        HStack(spacing: MeterSpacing.sm) {
                            ProviderGlyph(colorKey: item.colorKey ?? "unknown", accessibilityName: item.name)
                                .frame(width: MeterSpacing.providerGlyph)
                                .accessibilityHidden(true)
                            Text(item.name)
                                .font(MeterFont.subheadline)
                                .foregroundStyle(Color.meterLabel)
                                .lineLimit(1)
                            Spacer(minLength: MeterSpacing.xs)
                            Text(item.amountText)
                                .font(MeterFont.subheadline)
                                .foregroundStyle(Color.meterSecondaryLabel)
                                .monospacedDigit()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(DashboardMotion.number, value: content.animationSignature)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            content.isMonthlyRunRate
                ? L("固定订阅折算每月 \(content.spokenTotal)，\(content.countCaption)")
                : L("固定订阅合计 \(content.spokenTotal)，\(content.countCaption)")
        )
    }
}


#Preview("Light") {
    NavigationStack {
        List {
            Section {
                SubscriptionsModuleView(content: SubscriptionsPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.light)
}


public enum SubscriptionsPreviewData {
    public static let sample = SubscriptionsModuleContent(
        monthlyTotalText: "$24.00",
        monthlyTotalValue: 24,
        spokenTotal: "24 美元",
        headlineCaption: "每月",
        isMonthlyRunRate: true,
        countCaption: "2 笔，折算每月。年付按 12 摊。",
        nextChargeCaption: "下一笔：GitHub Team，9月12日",
        items: [
            SubscriptionRowItem(id: "a", name: "GitHub Team", amountText: "$4.00", amountValue: 4, periodCaption: "每月", accountID: nil, providerID: .github, colorKey: "github", spokenLabel: "GitHub Team，4 美元，每月"),
            SubscriptionRowItem(id: "b", name: "ChatGPT Plus", amountText: "$20.00", amountValue: 20, periodCaption: "每月", accountID: nil, providerID: .openai, colorKey: "openai", spokenLabel: "ChatGPT Plus，20 美元，每月"),
        ]
    )
}
