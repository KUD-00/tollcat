import SwiftUI

/// Mac 菜单。刷新和工具栏那颗是同一条路，花钱才能刷的家仍不进全局刷新。
/// ⌘, 切到主窗口设置栏，不要另开 Settings 场景。
public struct TollCatCommands: Commands {
    var dashboard: DashboardModel
    var settings: SettingsModel
    /// 直发壳传进来；App Store 版传空，菜单里就没有「检查更新…」。
    var updateChecker: AppUpdateChecker?
    #if os(macOS)
    var mainWindowID: String
    @Environment(\.openWindow) private var openWindow
    #endif

    public init(
        dashboard: DashboardModel,
        settings: SettingsModel,
        updateChecker: AppUpdateChecker? = nil,
        mainWindowID: String = "main"
    ) {
        self.dashboard = dashboard
        self.settings = settings
        self.updateChecker = updateChecker
        #if os(macOS)
        self.mainWindowID = mainWindowID
        #endif
    }

    public var body: some Commands {
        CommandGroup(replacing: .newItem) {}
        // Mac 惯例：紧跟「关于 TollCat」。安装进行中灰掉，别让人点第二次。
        if let updateChecker {
            CommandGroup(after: .appInfo) {
                Button(L("检查更新…")) {
                    updateChecker.checkForUpdates()
                }
                .disabled(!updateChecker.canCheck)
            }
        }
        CommandGroup(replacing: .appSettings) {
            Button(L("设置…")) {
                settings.requestReveal()
                #if os(macOS)
                openWindow(id: mainWindowID)
                #endif
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        CommandGroup(after: .sidebar) {
            Button(L("刷新用量")) {
                Task { await dashboard.refresh() }
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(dashboard.isRefreshing)
        }
    }
}
