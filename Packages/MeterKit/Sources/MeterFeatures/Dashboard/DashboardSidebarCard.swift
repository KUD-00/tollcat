import SwiftUI
import MeterDesign
import MeterModules

/// 钉在侧栏底部的那张卡。和主区的模块卡同一张皮，只是不定高——侧栏里它一张独占，按内容长。
/// 里面的链接经 `dashboardRouteOpener` 切回仪表盘再开，不在侧栏这一列里推页。
struct DashboardSidebarCard: View {
    let id: DashboardModuleID
    var model: DashboardModel

    /// 侧栏宽度由系统给（Mac 上用户还能拖），只有这一层量得到。
    /// 量的是卡自己被提议的宽——卡是 `maxWidth: .infinity` 的，内容长什么样
    /// 决定不了这个数，所以不构成反馈环；模块自己量才会。
    @State private var width: ModuleWidth = .compact

    var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            Text(id.title)
                .font(MeterFont.caption)
                .foregroundStyle(Color.meterSecondaryLabel)
            DashboardModuleFactory.view(id: id, contents: model)
        }
        // 封顶：侧栏是三个入口的家，这张卡再高也不能把它们挤掉。装不下的行裁掉。
        .frame(maxWidth: .infinity, maxHeight: MeterSpacing.sidebarCard, alignment: .topLeading)
        .padding(MeterSpacing.md)
        .background(
            Color.meterSecondaryGroupedBackground,
            in: RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
        )
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous))
        .meterModuleStyle(width: width, height: .regular, container: .card)
        .dashboardModuleLinks()
        .padding(.horizontal, MeterSpacing.sm)
        .padding(.bottom, MeterSpacing.sm)
        .onGeometryChange(for: CGFloat.self) { proxy in
            // 量的是最外层，所以两层边距都要扣：外面的 sm 是卡和侧栏边的距离，
            // 里面的 md 是卡面到内容。剩下的才是模块拿到的宽。
            max(proxy.size.width - (MeterSpacing.sm + MeterSpacing.md) * 2, 0)
        } action: { width = ModuleWidth.bucket(forContentWidth: $0) }
    }
}

#Preview("Light") {
    DashboardSidebarCard(id: .subscriptions, model: .preview)
        .frame(width: MeterSpacing.sidebarColumnMax)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    DashboardSidebarCard(id: .heatmap, model: .preview)
        .frame(width: MeterSpacing.sidebarColumnMax)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.dark)
}
