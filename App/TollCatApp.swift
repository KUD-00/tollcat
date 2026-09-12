import MeterFeatures
import SwiftUI

@main
struct TollCatApp: App {
    /// 唯一的组装点。具体实现只在这里被创建,往下全靠注入。
    @State private var environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            RootView(
                dashboardModel: environment.dashboardModel,
                persistenceStatus: environment.persistenceStatus,
                settingsModel: environment.settingsModel
            )
            .environment(\.usageAnalytics, environment.usageAnalytics)
            .tint(.indigo)
        }
    }
}
