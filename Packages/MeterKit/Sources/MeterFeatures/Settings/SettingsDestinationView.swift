import SwiftUI

/// 设置里点进去的那一页。手机栈和 iPad 分栏共用，避免写两份 switch。
struct SettingsDestinationView: View {
    var route: SettingsRoute
    var model: SettingsModel
    @Environment(\.selectedAppTab) private var selectedAppTab
    @Environment(\.padColumn) private var padColumn

    var body: some View {
        destination
            .recordsUsageScreen(
                route.usageScreen,
                isActive: selectedAppTab == .settings && padColumn != .list
            )
    }

    @ViewBuilder
    private var destination: some View {
        switch route {
        case .usageGuides:
            UsageGuideListView(dashboard: model.dashboard)
        case .whatsNew:
            WhatsNewListView()
        case .tip:
            TipView(model: model.tipModel)
        case .about:
            AboutView(versionCaption: model.versionCaption)
        case .importExport:
            DeviceTransferView(
                dashboard: model.dashboard,
                settings: model,
                initialURL: model.inboundTransferURL
            )
        case .inbox:
            InboxSettingsView(
                model: InboxSettingsModel(dashboard: model.dashboard)
            )
        case .feedback:
            FeedbackView(model: model.makeFeedbackModel())
        }
    }
}
