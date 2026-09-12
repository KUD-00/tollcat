import AppKit
import MeterDesign
import MeterFeatures
import SwiftUI

@main
struct TollCatMacApp: App {
    @State private var environment = AppEnvironment.live()
    @State private var updater = MacUpdater()
    @NSApplicationDelegateAdaptor(TollCatMacAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup(id: "main") {
            RootView(
                dashboardModel: environment.dashboardModel,
                persistenceStatus: environment.persistenceStatus,
                settingsModel: environment.settingsModel
            )
            .environment(\.usageAnalytics, environment.usageAnalytics)
            .environment(\.appUpdateChecker, updater.checker)
            .tint(.indigo)
            .onAppear {
                let settings = environment.settingsModel
                appDelegate.hidesDockIconWhenWindowClosed = { settings.hidesDockIconWhenWindowClosed }
            }
            #if DEBUG
            .background(MacDebugShotOpener())
            #endif
            .frame(
                minWidth: MeterSpacing.macWindowMinWidth,
                minHeight: MeterSpacing.macWindowMinHeight
            )
        }
        .defaultSize(
            width: MeterSpacing.macWindowIdealWidth,
            height: MeterSpacing.macWindowIdealHeight
        )
        .commands {
            TollCatCommands(
                dashboard: environment.dashboardModel,
                settings: environment.settingsModel,
                updateChecker: updater.checker
            )
        }

        MenuBarExtra {
            MacMenuBarRoot(dashboard: environment.dashboardModel)
                .tint(.indigo)
        } label: {
            MenuBarMeterLabel(dashboard: environment.dashboardModel)
        }
        // 面板里有构成条和柱状图，菜单式放不下；窗口式才是任意 SwiftUI。
        .menuBarExtraStyle(.window)

        #if DEBUG
        Window("MenuBarShot", id: MacDebugShotWindow.id) {
            MacMenuBarRoot(dashboard: environment.dashboardModel)
                .tint(.indigo)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        #endif
    }
}

/// 「关掉窗口后只留在菜单栏」的执行者。
///
/// 最后一个主窗口关掉就退成 accessory：程序坞图标消失、菜单栏菜单收走，进程还在，
/// 菜单栏那只猫照常。主窗口再露面（菜单栏点「打开 TollCat」、⌘, 之类）就回 regular——
/// 窗口开着的时候必须有程序坞图标和菜单栏菜单，否则 ⌘R / ⌘, 没地方住，
/// 用户也找不到「这个窗口是谁的」。
@MainActor
final class TollCatMacAppDelegate: NSObject, NSApplicationDelegate {
    /// 由壳在启动后接上，读设置里的那一档。
    var hidesDockIconWhenWindowClosed: () -> Bool = { false }

    /// `WindowGroup(id: "main")` 的 NSWindow identifier 以这个开头。
    /// 菜单栏面板和 popover 不算主窗口，它们关掉不该动程序坞。
    static let mainWindowIDPrefix = "main"

    func applicationDidFinishLaunching(_ notification: Notification) {
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
    }

    static func isMainWindow(_ window: NSWindow) -> Bool {
        !(window is NSPanel) && (window.identifier?.rawValue.hasPrefix(mainWindowIDPrefix) ?? false)
    }

    /// 主窗口要露面之前调一次：先回 regular，再 activate / openWindow。
    static func showInDock() {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
    }

    @objc private func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow,
              Self.isMainWindow(closing),
              hidesDockIconWhenWindowClosed()
        else { return }
        // willClose 时窗口还在 NSApp.windows 里；等这一轮走完再数剩下几扇。
        DispatchQueue.main.async { [weak self] in
            guard let self, self.hidesDockIconWhenWindowClosed() else { return }
            let remaining = NSApp.windows.filter { window in
                window !== closing && Self.isMainWindow(window) && window.isVisible
            }
            if remaining.isEmpty {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, Self.isMainWindow(window) else { return }
        Self.showInDock()
        // 主窗口不带工具栏，红绿灯那一行（32pt）露的是窗口底色：亮色系统白，
        // 和列底（F2F2F7）拼出一道横缝。窗口底色换成列底同一个 token（动态色，
        // 跟外观切换），titlebar 透掉，顶上连成一片。
        // `containerBackground(for: .window)` 在这条上不管用，实测亮色仍是白。
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(Color.meterGroupedBackground)
    }
}

#if DEBUG
/// 落地页截图：把菜单栏面板单独开成一扇无标题栏窗口。
/// 系统状态项要点击、还受辅助功能权限限制，截图脚本不能靠它。
enum MacDebugShotWindow {
    static let id = "menubar-shot"
    static let openArgument = "-open-menu-bar-panel"
}

struct MacDebugShotOpener: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onAppear {
                // 整段已经在 `#if DEBUG` 里，但仍然走统一入口：
                // 「谁能读启动参数」只该有一个答案，闸也照这一条扫。
                guard FeatureLaunchArguments.arguments.contains(MacDebugShotWindow.openArgument) else {
                    return
                }
                openWindow(id: MacDebugShotWindow.id)
            }
    }
}
#endif

