#if DEBUG
import SwiftUI
import MeterModules

/// 开发层的后两级。手机栈和 iPad 分栏的 detail 栈共用。
struct DeveloperSettingsDestinations: ViewModifier {
    var model: SettingsModel

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: DeveloperToolID.self) { id in
                DeveloperToolRegistry.view(
                    id: id,
                    dashboard: model.dashboard,
                    persistenceStatus: model.persistenceStatus
                )
            }
            .navigationDestination(for: GalleryItemID.self) { id in
                GalleryRegistry.view(id: id)
            }
            .navigationDestination(for: DashboardModuleID.self) { id in
                DeveloperDashboardLabModuleView(id: id, dashboard: model.dashboard)
            }
    }
}
#endif
