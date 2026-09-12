#if DEBUG
import SwiftUI
import MeterDesign
import MeterModules

/// 仪表盘实验室：一块模块一页，看同一份生产视图在各宽度档下长什么样。
///
/// 不再铺「还能放什么」的原型卡——那些已经进了 `DashboardModuleID`。
/// 加一块模块不用改实验室：目录跟着 `defaultOrder` 走。
struct DeveloperDashboardLabView: View {
    var dashboard: DashboardModel

    var body: some View {
        MeterGroupedList {
            ForEach(DashboardLabSection.allCases, id: \.self) { section in
                Section {
                    ForEach(section.ids) { id in
                        MeterColumnLink(
                            value: id,
                            title: Text(id.title),
                            destination: {
                                DeveloperDashboardLabModuleView(id: id, dashboard: dashboard)
                            }
                        ) {
                            row(id)
                        }
                    }
                } header: {
                    Text(section.title)
                } footer: {
                    if section == .hero {
                        Text(L("每块模块一页。同一份视图按宽度档摊开：宽壳卡四档、手机列表、有小组件的再看真实尺寸。"))
                    }
                }
            }
        }
        .navigationTitle(L("仪表盘实验室"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ id: DashboardModuleID) -> some View {
        Label {
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(id.title)
                Text(status(id))
                    .font(MeterFont.caption)
                    .foregroundStyle(Color.meterSecondaryLabel)
            }
        } icon: {
            Image(systemName: id.systemImage)
        }
    }

    private func status(_ id: DashboardModuleID) -> LocalizedStringResource {
        if id.isRetired { return L("已下架") }
        if dashboard.has(id) { return L("有数据") }
        return L("当前账本没有")
    }
}

#Preview("Light") {
    NavigationStack {
        DeveloperDashboardLabView(dashboard: .preview)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        DeveloperDashboardLabView(dashboard: .preview)
    }
    .preferredColorScheme(.dark)
}
#endif
