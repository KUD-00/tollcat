import SwiftUI
import MeterDesign
import MeterModules

/// 分享卡上的模块区：**和仪表盘同一批模块、同一个顺序、同一批视图**。
///
/// 卡不许另攒一套「精简版仪表盘」——用户在「编辑仪表盘」里开了热力图，
/// 发出去的图上就该有热力图；关掉构成，卡上也不该有那个环。所以这里不重新排版，
/// 只把 `DashboardModuleFactory` 出来的模块视图一块一张卡地摆下去。
///
/// 合计在卡的英雄区、构成和它那两张方卡由 `ShareCardView` 自己画（跟仪表盘英雄区
/// 同一组），这里排的是剩下那些。钉去 iPad 侧栏的那块也算——卡上没有侧栏，
/// 它仍然是这个人仪表盘的一部分。
struct ShareCardModules: View {
    var model: DashboardModel

    private var ids: [DashboardModuleID] { Self.moduleIDs(for: model) }

    /// 卡上排哪几块。给测试留的纯查询：卡上的模块清单必须就是仪表盘的那一份。
    static func moduleIDs(for model: DashboardModel) -> [DashboardModuleID] {
        DashboardModuleRegion.bodyIDs(from: model.visibleModuleIDs)
    }

    var body: some View {
        if !ids.isEmpty {
            VStack(alignment: .leading, spacing: MeterSpacing.sm) {
                ForEach(ids) { id in
                    card(id)
                }
            }
        }
    }

    /// 版式跟宽壳的 bento 卡（`DashboardModuleCard`）同一套：模块名做小标题，
    /// 底下是手机上那同一个模块视图。只有两处不一样：颜色走卡自己那份浅色，
    /// 高度按内容长（bento 卡是定高裁切，图上裁掉半行没人能滚动去看）。
    private func card(_ id: DashboardModuleID) -> some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            Text(id.title)
                .font(MeterFont.caption)
                .foregroundStyle(ShareCardPalette.secondaryInk)
            DashboardModuleFactory.view(id: id, contents: model)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, MeterSpacing.md)
        .padding(.vertical, MeterSpacing.sm)
        .background(
            ShareCardPalette.card,
            in: RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
        )
        // 模块视图本来是 List 行：热区、行高、分隔都指望列表补，卡里没有那层。
        // 图上还点不动，所以是 `.snapshot` 而不是 `.card`：行高和 headline 照卡的来，
        // chevron、「查看更多」、翻月箭头一概不画。
        //
        // 宽度是算得出来的定值，不用量：432（`ShareCardView.layoutSize`）
        // 扣掉页边 lg×2 和卡自己的 md×2，约 352pt，落在 regular 档。
        .meterModuleStyle(width: .regular, height: .regular, container: .snapshot)
        // 卡里的 NavigationLink 不在 List 里：素排版，别渲成蓝字按钮。
        .buttonStyle(.plain)
    }
}
