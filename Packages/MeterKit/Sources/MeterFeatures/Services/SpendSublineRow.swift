import SwiftUI
import MeterDesign

/// 子级行的统一版式：主行（组 / 服务）下面缩进一截的一行小字。
/// 「花在哪了」全屏页、仪表盘的构成页和较上月同期页共用这一行——
/// 从属关系全靠同一个缩进 + 降一档的字号说话，三处不各画各的。
///
/// `indent` 是上一级主行**文字**的起点：主行前导是色点就传色点那一档，
/// 是 glyph 就传 glyph 那一档。行内在这之上再进一档（`md`）——
/// 和父行文字齐平会被读成并列项，从属关系必须靠肉眼可见的缩进说出来。
/// 子行自己不带色点：它不是构成里的一段，只是上一段的展开。
///
/// 左右分栏手写，不用 `LabeledContent`：长说明（Cloudflare 的
/// "First 500 GB included"）会把右侧金额挤成两行。金额必须保持一行，
/// 标题和说明自己在左侧折。辅助功能字号再改成上下排。
struct SpendSublineRow: View {
    var title: String
    /// 「1,667 Minutes」这类用量说明。仪表盘两页不传——那两页只回答钱。
    var detailCaption: String?
    var amountCaption: String
    /// 「原价 $0.35」。有值就划掉，表示被额度或折扣抵过。
    var listCaption: String?
    /// 较上月同期页才填。有值时右侧改画涨跌，两头金额落到第二行。
    var comparisonSubtitle: String?
    var changeCaption: String?
    var changeRatio: Double?
    /// 上一级主行文字的起点，不是这一行最终的缩进。
    var indent: CGFloat
    var spokenLabel: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        title: String,
        detailCaption: String? = nil,
        amountCaption: String,
        listCaption: String? = nil,
        comparisonSubtitle: String? = nil,
        changeCaption: String? = nil,
        changeRatio: Double? = nil,
        indent: CGFloat,
        spokenLabel: String
    ) {
        self.title = title
        self.detailCaption = detailCaption
        self.amountCaption = amountCaption
        self.listCaption = listCaption
        self.comparisonSubtitle = comparisonSubtitle
        self.changeCaption = changeCaption
        self.changeRatio = changeRatio
        self.indent = indent
        self.spokenLabel = spokenLabel
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                stacked
            } else {
                columns
            }
        }
        .meterListRowHitTarget()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spokenLabel))
    }

    private var columns: some View {
        HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.sm) {
            leadingColumn
                .padding(.leading, indent + MeterSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            trailingColumn
        }
    }

    private var stacked: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            leadingColumn
            trailingColumn
        }
        .padding(.leading, indent + MeterSpacing.md)
    }

    private var leadingColumn: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            Text(title)
                .font(MeterFont.subheadline)
                .foregroundStyle(Color.meterLabel)
                .fixedSize(horizontal: false, vertical: true)
            if let comparisonSubtitle {
                Text(comparisonSubtitle)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .monospacedDigit()
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let detailCaption {
                Text(detailCaption)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var trailingColumn: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: MeterSpacing.xxs) {
            if let changeCaption {
                Text(changeCaption)
                    .font(MeterFont.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(changeColor)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .contentTransition(.numericText(value: changeRatio ?? 0))
            } else {
                Text(amountCaption)
                    .font(MeterFont.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            if let listCaption {
                Text(listCaption)
                    .font(MeterFont.footnote)
                    .monospacedDigit()
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .strikethrough()
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .layoutPriority(1)
    }

    private var changeColor: Color {
        guard let changeRatio else { return Color.meterSecondaryLabel }
        if changeRatio > 0 { return MeterColor.warn }
        if changeRatio < 0 { return MeterColor.good }
        return Color.meterSecondaryLabel
    }
}

#Preview("Light") {
    List {
        Section {
            SpendSublineRow(
                title: "Workers",
                detailCaption: "1,667 Minutes",
                amountCaption: "$3.20",
                indent: MeterSpacing.compositionSwatch + MeterSpacing.xs,
                spokenLabel: "Workers，3 美元 20 美分"
            )
            SpendSublineRow(
                title: "R2 Storage",
                amountCaption: "$0.00",
                listCaption: "原价 $0.35",
                indent: MeterSpacing.compositionSwatch + MeterSpacing.xs,
                spokenLabel: "R2 Storage，0 美元"
            )
            SpendSublineRow(
                title: "Container Egress, Oceania, Taiwan, and Korea, per GB",
                detailCaption: "412 GB · First 500 GB included",
                amountCaption: "$0.00",
                listCaption: "原价 $4.12",
                indent: MeterSpacing.compositionSwatch + MeterSpacing.xs,
                spokenLabel: "Container Egress，0 美元"
            )
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        Section {
            SpendSublineRow(
                title: "EC2",
                amountCaption: "$12.10",
                indent: MeterSpacing.providerGlyph + MeterSpacing.sm,
                spokenLabel: "EC2，12 美元 10 美分"
            )
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("XXL") {
    List {
        Section {
            SpendSublineRow(
                title: "Container Egress, Oceania",
                detailCaption: "412 GB",
                amountCaption: "$4.12",
                indent: MeterSpacing.compositionSwatch + MeterSpacing.xs,
                spokenLabel: "Container Egress，4 美元 12 美分"
            )
        }
    }
    .dynamicTypeSize(.accessibility3)
}

#Preview("Comparison") {
    List {
        Section {
            SpendSublineRow(
                title: "Workers KV",
                amountCaption: "$3.20",
                comparisonSubtitle: "本月 $3.20 · 7 月同期 $1.10",
                changeCaption: "+191%",
                changeRatio: 1.91,
                indent: MeterSpacing.providerGlyph + MeterSpacing.sm,
                spokenLabel: "Workers KV 较上月同期上升百分之 191"
            )
            SpendSublineRow(
                title: "R2 Storage",
                amountCaption: "$0.80",
                indent: MeterSpacing.providerGlyph + MeterSpacing.sm,
                spokenLabel: "R2 Storage，80 美分"
            )
        }
    }
    .preferredColorScheme(.light)
}
