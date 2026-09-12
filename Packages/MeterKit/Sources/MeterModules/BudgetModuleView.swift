import SwiftUI
import MeterCore
import MeterDesign

/// 「预算线」：本月合计对着月预算，画成一排一排的小方块。
///
/// 为什么不是进度条：一条填了多少全靠眼估，格子能数——「三十格填了十八格」比
/// 「大概六成」确定。格子也是这个 App 已有的语言（热力图一天一格），两处一副手感。
public struct BudgetModuleView: View {
    public let content: BudgetModuleContent
    @Environment(\.moduleWidth) private var width

    public init(content: BudgetModuleContent) {
        self.content = content
    }

    private var tint: Color {
        content.isOver ? MeterColor.crit : content.isClose ? MeterColor.warn : Color.accentColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            DashboardCardHeadline(
                value: content.percentText,
                tone: content.isOver ? MeterColor.crit : content.isClose ? MeterColor.warn : Color.meterLabel,
                animationValue: content.fraction
            )
            blocks
            // 花了多少 / 一共多少。「还剩多少、用了几成」不再单写一行——
            // 剩下的就是没染色的那几格，百分比已经在上面那个大数字里。
            Text(L("\(content.spentText) / \(content.budgetText)"))
                .font(MeterFont.footnote)
                .foregroundStyle(Color.meterSecondaryLabel)
                .monospacedDigit()
                .lineLimit(1)
                // 2×2 里这一行正好差一点：宁可缩一号，也不要「$80....」。
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.spokenLabel)
    }

    /// 一行几格。**模块不许自己量宽**（那是布局反馈环），只读容器声明的宽度档；
    /// 判据写成区间比较，没做某一档版式的按就近下一档画。
    ///
    /// 数是这么定的：每档下来一格都落在 10～17pt，和热力图那一格（14pt）同一个身量。
    /// 格子太大就成了色块（数不清也不像格子），太小在 2×2 里挤成一排点。
    private var columns: Int {
        if width >= .expanded { return 32 }
        if width >= .wide { return 26 }
        if width >= .regular { return 20 }
        return 10
    }

    /// 圆角跟着格子的身量走：2×2 里那一格只有 10pt 宽，还用 3 就圆成了点。
    private var blockRadius: CGFloat {
        width >= .regular ? MeterRadius.budgetBlock : MeterRadius.budgetBlockCompact
    }

    /// 排数。一排太单薄——widget 的 2×2 里也就是一条细线；两排既能撑住一张卡，
    /// 也把一格的分量降到 2%～5%，数得过来。要改就改这一处。
    private var rows: Int { 2 }

    private var total: Int { columns * rows }

    /// 染几格。超预算时全染（红），此时格子只说「满了」，超了多少看下面那行数字。
    /// 花了钱就至少亮一格：四舍五入会把 1% 抹成 0，那看着像没花钱。
    private var filled: Int {
        guard content.fraction > 0 else { return 0 }
        let clamped = min(content.fraction, 1)
        return min(total, max(1, Int((Double(total) * clamped).rounded())))
    }

    private var blocks: some View {
        VStack(spacing: MeterSpacing.budgetBlockGap) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: MeterSpacing.budgetBlockGap) {
                    ForEach(0..<columns, id: \.self) { column in
                        RoundedRectangle(cornerRadius: blockRadius, style: .continuous)
                            .fill(row * columns + column < filled ? tint : Color.meterSeparator)
                            // 方的：宽由 HStack 均分，高跟着宽走，谁也不用去量。
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .animation(DashboardMotion.number, value: filled)
        .accessibilityHidden(true)
    }
}

#Preview("Light") {
    NavigationStack {
        List {
            Section {
                BudgetModuleView(content: BudgetPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        List {
            Section {
                BudgetModuleView(content: BudgetPreviewData.over)
            }
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("窄卡") {
    BudgetModuleView(content: BudgetPreviewData.sample)
        .meterModuleStyle(width: .compact, height: .tight, container: .snapshot)
        .padding()
        .frame(width: 146)
}

public enum BudgetPreviewData {
    public static let sample = BudgetModuleContent(
        spentText: "$47.20", budgetText: "$80.00", fraction: 0.59,
        caption: "还剩 $32.80，用了 59%", spokenLabel: "预算 80 美元，已花 47 美元 20 美分",
        isOver: false, isClose: false
    )
    public static let over = BudgetModuleContent(
        spentText: "$91.30", budgetText: "$80.00", fraction: 1.14,
        caption: "超出 $11.30", spokenLabel: "预算 80 美元，已花 91 美元 30 美分，超出 11 美元 30 美分",
        isOver: true, isClose: true
    )
}
