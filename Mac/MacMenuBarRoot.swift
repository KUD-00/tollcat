import MeterFeatures
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// 菜单栏的内容。开主窗口必须走 `openWindow`，退出必须走 `NSApp`，所以留在壳里。
struct MacMenuBarRoot: View {
    var dashboard: DashboardModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        MenuBarMeterView(
            dashboard: dashboard,
            onOpenMainWindow: openMainWindow,
            onQuit: { NSApp.terminate(nil) }
        )
    }

    private func openMainWindow() {
        // 关窗后收进菜单栏的那一档会把 App 退成 accessory，先回 regular 再露窗口。
        TollCatMacAppDelegate.showInDock()
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "main")
    }
}
