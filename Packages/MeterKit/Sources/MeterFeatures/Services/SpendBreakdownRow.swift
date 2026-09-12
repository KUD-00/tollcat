import SwiftUI
import MeterCore
import MeterDesign

/// 一组明细的图例行。详情页「本月」里那几行和全屏那一页共用同一行，
/// 两处的密度差别是一个 `style`，不是两套代码。
///
/// 版式照系统「储存空间」：色点 + 名字在左，金额在右。`.regular` 给全屏页：
/// 用量、额度、百分比这类次要说明降一档跟在旁边。`.compact` 给详情页的
/// 「本月」节：只留色点 + 名字 + 金额一行——那一节的主角是上面的大数字，
/// 这几行是它的注脚，百分比和用量都留给「全部 N 项」。
///
/// 左右分栏手写：组里只有一条时额度说明会提到这一行，
/// 「First 500 GB included」这种长句不能把右侧金额挤成两行。
/// 辅助功能字号再改成上下排。
struct SpendBreakdownRow: View {
    enum Style {
        case regular
        case compact
    }

    let group: SpendBreakdownGroup
    let color: Color
    var style: Style = .regular

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        .accessibilityLabel(Text(group.spokenLabel))
    }

    private var columns: some View {
        HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.sm) {
            leadingColumn
                .frame(maxWidth: .infinity, alignment: .leading)
            trailingColumn
        }
    }

    private var stacked: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            leadingColumn
            trailingColumn
                .padding(.leading, MeterSpacing.compositionSwatch + MeterSpacing.xs)
        }
    }

    private var leadingColumn: some View {
        HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: MeterSpacing.compositionSwatch, height: MeterSpacing.compositionSwatch)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(group.title)
                    .font(titleFont)
                    .foregroundStyle(Color.meterLabel)
                    .lineLimit(style == .compact ? 1 : 2)
                    .fixedSize(horizontal: false, vertical: true)
                if style == .regular, let caption = secondaryCaption {
                    Text(caption)
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var trailingColumn: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: MeterSpacing.xxs) {
            Text(group.amountCaption)
                .font(titleFont)
                .foregroundStyle(Color.meterLabel)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            if style == .regular, let share = group.shareCaption {
                Text(share)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .layoutPriority(1)
    }

    private var titleFont: Font {
        style == .compact ? MeterFont.subheadline : MeterFont.body
    }

    /// 用量和额度抵扣挤在同一行小字里。两个都有就用「·」串起来——
    /// 各占一行会把这一节又拉高一倍，而它们是同一个意思的两面。
    private var secondaryCaption: String? {
        [group.detailCaption, group.allowanceCaption]
            .compactMap { $0 }
            .joined(separator: " · ")
            .nilWhenEmpty
    }
}

private extension String {
    var nilWhenEmpty: String? { isEmpty ? nil : self }
}
