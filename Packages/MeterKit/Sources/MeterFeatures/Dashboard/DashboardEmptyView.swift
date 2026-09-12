import SwiftUI
import MeterDesign

/// 一条数据都没有是空态，不是 loading。要告诉人下一步做什么。
struct DashboardEmptyView: View {
    var onOpenServices: () -> Void
    var persistenceStatus: PersistenceStatus = .preview
    var onDismissDemo: (() -> Void)?
    var didClearAllData = false

    var body: some View {
        CatEmptyState(
            mood: .sleeping,
            title: didClearAllData ? L("已清除全部数据") : L("还没有账单"),
            description: didClearAllData
                ? L("凭据和历史账单都从这台设备上删掉了。可以重新添加服务。")
                : L("接入第一家云服务之后，本月已经花了多少会显示在这里。"),
            actionTitle: L("添加第一个服务"),
            action: onOpenServices,
            identifier: UITestID.dashboardEmpty,
            // 仪表空态的按钮只是跳到服务 tab，冒烟不点它——点的是服务空态那颗。
            actionIdentifier: "dashboard.empty.action"
        )
        .overlay(alignment: .top) {
            PersistenceNoticeList(status: persistenceStatus, onDismissDemo: onDismissDemo)
                .padding(.horizontal, MeterSpacing.pageHorizontal)
                .padding(.top, MeterSpacing.md)
        }
    }
}

#Preview("Light") {
    DashboardEmptyView(onOpenServices: {})
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    DashboardEmptyView(onOpenServices: {})
        .preferredColorScheme(.dark)
}

#Preview("Cleared") {
    DashboardEmptyView(onOpenServices: {}, didClearAllData: true)
}
