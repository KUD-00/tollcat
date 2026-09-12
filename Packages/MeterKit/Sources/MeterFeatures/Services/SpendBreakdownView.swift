import SwiftUI
import MeterCore
import MeterDesign

/// 详情页「花在哪了」的全屏版本。一份代码画所有家：
/// 有 `scope` 维度的多一个分组选择器，有原价的多一行抵扣说明。
///
/// 和详情页那一节的关系是同一张版式的两个缩放级别：那边只给真花钱的前三组，
/// 这边把每一组摊开，行仍然是同一个 `SpendBreakdownRow`。
/// 概览图和仪表盘构成页共用 `CompositionDonut`——同一个问题（怎么分的）
/// 在这个 App 里只有一种画法。
///
/// 全部内容在同一张卡里，分隔线负责分组。一组一张卡在真实数据下会退化成
/// 一列只装一行的小卡——那是拿容器冒充结构，不是版式。
struct SpendBreakdownView: View {
    @Bindable var model: ProviderDetailModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let content = model.breakdown
        return MeterGroupedList {
            Section {
                summaryBlock(content)
                    .listRowInsets(EdgeInsets(
                        top: MeterSpacing.sm,
                        leading: MeterSpacing.md,
                        bottom: MeterSpacing.sm,
                        trailing: MeterSpacing.md
                    ))
                if content.supportsScopeGrouping {
                    Picker(L("分组"), selection: groupingBinding) {
                        Text(L("按服务")).tag(SpendBreakdownGrouping.category)
                        Text(L("按归属")).tag(SpendBreakdownGrouping.scope)
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
                }
            }

            // 一张卡列完，分隔线负责分组，不给每组套一个容器。
            // 一组一张卡在真实数据下就是一列只装一行的小卡——那是拿容器冒充结构。
            Section {
                ForEach(Array(content.groups.enumerated()), id: \.element.id) { index, group in
                    SpendBreakdownRow(group: group, color: MeterColor.composition(index: index))
                    // 只有一条时组行已经说完了，再列一遍是同一笔钱说两遍。
                    if group.items.count > 1 {
                        ForEach(group.items) { item in
                            itemRow(item)
                        }
                    }
                }
            }
        }
        .navigationTitle(L("花在哪了"))
        .navigationBarTitleDisplayMode(.large)
    }

    /// 合计是这一页的主角数字，和详情页「本月」、仪表大数字同一套字。
    /// 环跟在右边回答「怎么分的」——叠在数字下面会让环变成整节的视觉中心，
    /// 数字缩成 caption。辅助功能字号再改上下排，数字仍在上。
    private func summaryBlock(_ content: SpendBreakdownContent) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: MeterSpacing.sm) {
                    totalColumn(content)
                    donut(content)
                }
            } else {
                HStack(alignment: .center, spacing: MeterSpacing.md) {
                    totalColumn(content)
                    donut(content)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(content.spokenSummary))
    }

    private func totalColumn(_ content: SpendBreakdownContent) -> some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            Text(content.totalCaption)
                .meterAmountStyle()
                .foregroundStyle(Color.meterLabel)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
            if let discount = content.discountCaption {
                Text(discount)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func donut(_ content: SpendBreakdownContent) -> some View {
        CompositionDonut(
            slices: donutSlices(content),
            showsLegend: false,
            isInteractive: true
        )
    }

    /// 图例不开：下面的组行就是图例，环上再排一份名字是同一句话说两遍。
    /// 色序和组行同一套 `MeterColor.composition(index:)`，按住哪段浮签说哪组。
    private func donutSlices(_ content: SpendBreakdownContent) -> [CompositionDonut.Slice] {
        content.groups.enumerated().map { index, group in
            CompositionDonut.Slice(
                id: group.id,
                color: MeterColor.composition(index: index),
                fraction: group.fraction,
                name: group.title,
                amountText: group.amountCaption
            )
        }
    }

    /// 组行的下级。和仪表盘两张详情页的子服务行同一个 `SpendSublineRow`。
    private func itemRow(_ item: SpendBreakdownItem) -> some View {
        SpendSublineRow(
            title: item.title,
            detailCaption: item.detailCaption,
            amountCaption: item.amountCaption,
            listCaption: item.listCaption,
            indent: MeterSpacing.compositionSwatch + MeterSpacing.xs,
            spokenLabel: item.spokenLabel
        )
    }

    private var groupingBinding: Binding<SpendBreakdownGrouping> {
        Binding(
            get: { model.breakdownGrouping },
            set: { model.breakdownGrouping = $0 }
        )
    }
}

#Preview("Light") {
    NavigationStack {
        SpendBreakdownView(model: .preview(.github))
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        SpendBreakdownView(model: .preview(.github))
    }
    .preferredColorScheme(.dark)
}

#Preview("Cloudflare") {
    NavigationStack {
        SpendBreakdownView(model: .preview(.cloudflare))
    }
    .preferredColorScheme(.light)
}

#Preview("XXL") {
    NavigationStack {
        SpendBreakdownView(model: .preview(.cloudflare))
    }
    .dynamicTypeSize(.accessibility3)
}
