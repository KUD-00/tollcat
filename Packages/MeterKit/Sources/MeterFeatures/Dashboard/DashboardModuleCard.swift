import SwiftUI
import MeterDesign
import MeterModules

/// 宽壳上「需要注意」的一个模块 = 一张 bento 卡：模块名做小标题，
/// 行还是手机同一套洞察行（`DashboardInsightRow`），卡内自带热区和 chevron。
///
/// 版式档（`meterModuleStyle`）不在这里声明，由 `DashboardPadLayout` 在行里按
/// 实测卡宽给——只有那一层知道这张卡最后有多宽。单独用这张卡时自己补上。
struct DashboardModuleCard: View {
    let id: DashboardModuleID
    var model: DashboardModel

    var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            Text(title)
                .font(MeterFont.caption)
                .foregroundStyle(Color.meterSecondaryLabel)
            DashboardModuleFactory.view(id: id, contents: model)
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(MeterSpacing.md)
        .background(
            Color.meterSecondaryGroupedBackground,
            in: RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
        )
        // 卡是定高的，装不下的部分裁掉，不把整行撑高。
        .clipShape(RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous))
        // 卡里的 NavigationLink 不在 List 里：素排版，别渲成蓝字按钮。
        .buttonStyle(.plain)
    }

    /// SPEC 第 05 节的模块名。合计和构成在英雄区，走不到这张卡。
    private var title: LocalizedStringResource { id.title }
}

#Preview("Light") {
    @Previewable @State var model = DashboardModel.preview
    ScrollView {
        VStack(spacing: MeterSpacing.sm) {
            ForEach(DashboardModuleRegion.attentionIDs(from: model.visibleModuleIDs)) { id in
                DashboardModuleCard(id: id, model: model)
                    .meterModuleStyle(width: .regular, height: .regular, container: .card)
            }
        }
        .padding(MeterSpacing.pageHorizontal)
    }
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var model = DashboardModel.preview
    ScrollView {
        VStack(spacing: MeterSpacing.sm) {
            ForEach(DashboardModuleRegion.attentionIDs(from: model.visibleModuleIDs)) { id in
                DashboardModuleCard(id: id, model: model)
                    .meterModuleStyle(width: .regular, height: .regular, container: .card)
            }
        }
        .padding(MeterSpacing.pageHorizontal)
    }
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.dark)
}
