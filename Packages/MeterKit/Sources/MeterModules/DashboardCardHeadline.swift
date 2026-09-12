import SwiftUI
import MeterDesign

/// 卡上「一眼要看到的那个数」：和「较上月同期」那颗百分比同一副字，旁边一行小字说它是什么。
/// 每张宽壳卡都该有一个，列表和图表是它的展开。
///
/// 连圆环那两张（构成 / 按类别构成）也要——哪怕百分比和图例说的是同一件事。
/// bento 一行里的卡都是定高的，少一张的第一行就整行对不齐，比重复难看。
public struct DashboardCardHeadline: View {
    /// 小字摆哪。两种都是小一号灰字——试过把小字并进大数字里同字号同粗细
    /// （「$24.00 每月」「39% Fly.io」），太重，压过了数字本身，已撤回。
    /// - `below`：数字下面一行。说明性的一整句用这个（「Fly.io 占最多」）。
    /// - `trailing`：贴在数字后面、基线对齐。量词用这个（「每月」跟着数字一起读）。
    public enum CaptionPlacement {
        case below
        case trailing
    }

    public var value: String
    public var caption: String?
    public var captionPlacement: CaptionPlacement = .below
    public var tone: Color = Color.meterLabel
    public var animationValue: Double = 0

    public init(
        value: String,
        caption: String? = nil,
        captionPlacement: CaptionPlacement = .below,
        tone: Color = Color.meterLabel,
        animationValue: Double = 0
    ) {
        self.value = value
        self.caption = caption
        self.captionPlacement = captionPlacement
        self.tone = tone
        self.animationValue = animationValue
    }

    public var body: some View {
        Group {
            switch captionPlacement {
            case .below:
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    number
                    captionText
                }
            case .trailing:
                // 数字先按内容量宽，小字紧跟其后；数字太长时先缩数字，不把小字挤下去。
                HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xxs) {
                    number
                    captionText
                        .layoutPriority(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var number: some View {
        Text(value)
            .font(MeterFont.largeTitle.weight(.semibold))
            .foregroundStyle(tone)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .contentTransition(.numericText(value: animationValue))
    }

    @ViewBuilder
    private var captionText: some View {
        if let caption {
            Text(caption)
                .font(MeterFont.footnote)
                .foregroundStyle(Color.meterSecondaryLabel)
                .lineLimit(1)
        }
    }
}

#Preview("Light") {
    DashboardCardHeadline(value: "56%", caption: "Neon 占最多")
        .padding()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    DashboardCardHeadline(value: "12 天", caption: "OpenAI 最紧", tone: MeterColor.warn)
        .padding()
        .preferredColorScheme(.dark)
}

#Preview("量词跟在数字后面") {
    DashboardCardHeadline(value: "$24.00", caption: "每月", captionPlacement: .trailing)
        .padding()
}
