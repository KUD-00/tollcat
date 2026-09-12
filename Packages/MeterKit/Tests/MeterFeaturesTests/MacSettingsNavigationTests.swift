import Foundation
import Testing
@testable import MeterFeatures

/// Mac 设置走主窗口侧栏，⌘, 切过去，不要另开 Settings 场景。
struct MacSettingsNavigationTests {
    @Test("侧栏三个入口都在，不再按平台藏掉设置")
    func sidebarAlwaysIncludesSettings() throws {
        let root = try GuardrailSourceScan.sourceText(named: "RootView.swift")
        #expect(root.contains("Label(L(\"设置\"), systemImage: \"gearshape\")"))
        #expect(!root.contains("openSettings"))
        #expect(!root.contains("@Environment(\\.openSettings)"))
        let settingsLabel = try #require(
            root.range(of: "Label(L(\"设置\"), systemImage: \"gearshape\")")
        )
        let before = root[root.startIndex..<settingsLabel.lowerBound]
        #expect(!before.hasSuffix("#if os(iOS)\n            "))
    }

    @Test("Mac 壳没有 Settings 场景")
    func macAppHasNoSettingsScene() throws {
        let files = try GuardrailSourceScan.swiftFiles(under: ["Mac"])
        let url = try #require(files.first { $0.lastPathComponent == "TollCatMacApp.swift" })
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(!text.contains("Settings {"))
        #expect(text.contains("TollCatCommands("))
        #expect(text.contains("settings: environment.settingsModel"))
    }

    @Test("⌘, 替换系统 Settings 菜单，切到主窗口设置栏")
    func commandCommaReplacesAppSettings() throws {
        let text = try GuardrailSourceScan.sourceText(named: "TollCatCommands.swift")
        #expect(text.contains("CommandGroup(replacing: .appSettings)"))
        #expect(text.contains("keyboardShortcut(\",\", modifiers: .command)"))
        #expect(text.contains("settings.requestReveal()"))
        #expect(text.contains("openWindow(id: mainWindowID)"))
        #expect(text.contains("#if os(macOS)"))
        #expect(text.contains("L(\"设置…\")"))
    }

    @Test("RootView 收到 reveal 就落到设置栏")
    func rootViewConsumesReveal() throws {
        let root = try GuardrailSourceScan.sourceText(named: "RootView.swift")
        #expect(root.contains("settingsModel.revealGeneration"))
        #expect(root.contains("settingsModel.consumeReveal()"))
        #expect(root.contains("selectedTab = .settings"))
    }

    @Test("Mac 开关钉成 switch，行高按可点下限")
    func macSettingsUsesSwitchAndTapHeight() throws {
        let chrome = try GuardrailSourceScan.sourceText(named: "MeterControlChrome.swift")
        let root = try GuardrailSourceScan.sourceText(named: "RootView.swift")
        #expect(chrome.contains("toggleStyle(.switch)"))
        #expect(chrome.contains("defaultMinListRowHeight"))
        #expect(chrome.contains("MeterSpacing.minTap"))
        #expect(root.contains("meterControlChrome()"))
    }

    @Test("Mac 宽壳只有一棵分栏；iPad 的服务 / 设置仍是真三栏")
    func padSplitShapeIsPerPlatform() throws {
        let root = try GuardrailSourceScan.sourceText(named: "RootView.swift")
        // Mac：两栏和三栏是两种 `NavigationSplitView`，来回切会把侧栏整棵拆掉重画。
        // 分叉是运行时的（`meterShell == .mac`），两条路都参与编译；Mac 那条叫 `macSplit`。
        let macBranch = try #require(root.range(of: "private var macSplit: some View {"))
        let macEnd = try #require(root.range(of: "private var padSplitByTab", range: macBranch.upperBound..<root.endIndex))
        let mac = String(root[macBranch.lowerBound..<macEnd.lowerBound])
        #expect(mac.components(separatedBy: "NavigationSplitView {").count == 2)
        #expect(!mac.contains("} content: {"))
        #expect(!root.contains("#if os(macOS)\n    private var padSplit"), "壳的分叉不再是编译期的")
        // 那段「为什么」写在 `#if` 上面，所以按整份源码查。
        #expect(root.contains("Mac 的外层永远两栏"))
        // iPad：一个分栏列只发一条系统导航栏。主从两列必须各自是真正的分栏列，
        // 拿 `PadSecondaryPair` 在一列里拼的话，详情列和它推进去的二级页
        // 领不到自己的栏——标题和返回钮全没。
        #expect(root.contains("} content: {"))
        #expect(root.contains("environment(\\.padColumn, .list)"))
        #expect(root.contains("environment(\\.padColumn, .detail)"))
        let settings = try GuardrailSourceScan.sourceText(named: "SettingsView.swift")
        let services = try GuardrailSourceScan.sourceText(named: "ServicesView.swift")
        #expect(settings.contains("PadSecondaryPair"))
        #expect(services.contains("PadSecondaryPair"))
    }

    @Test("分栏每列自己导航，窗口顶栏必须空着")
    func splitColumnsOwnTheirNavigation() throws {
        let chrome = try GuardrailSourceScan.sourceText(named: "MeterSplitColumnChrome.swift")
        let bar = try GuardrailSourceScan.sourceText(named: "MeterMacColumnBar.swift")
        let title = try GuardrailSourceScan.sourceText(named: "MeterMacTitleDisplayMode.swift")
        let root = try GuardrailSourceScan.sourceText(named: "RootView.swift")
        let settings = try GuardrailSourceScan.sourceText(named: "SettingsView.swift")
        let services = try GuardrailSourceScan.sourceText(named: "ServicesView.swift")
        let dashboard = try GuardrailSourceScan.sourceText(named: "DashboardView.swift")
        let transfer = try GuardrailSourceScan.sourceText(named: "DeviceTransferView.swift")
        #expect(chrome.contains("toolbar(removing: .sidebarToggle)"))
        #expect(chrome.contains("toolbar(removing: .title)"))
        #expect(chrome.contains("toolbar(.hidden, for: .windowToolbar)"))
        #expect(bar.contains("safeAreaInset(edge: .top"))
        let sidebar = try GuardrailSourceScan.sourceText(named: "PadSidebarIdentity.swift")
        #expect(!sidebar.contains("placement: .navigation"))
        // 侧栏顶上不放品牌章（和菜单栏、程序坞重复），底部不放猫。
        #expect(!sidebar.contains("safeAreaInset"))
        #expect(!sidebar.contains("BrandMark"))
        #expect(!root.contains("CatView("))
        #expect(title.contains("toolbarTitleDisplayMode(.inline)"))
        #expect(!title.contains("toolbarTitleDisplayMode(.large)"))
        #expect(root.contains("meterSplitViewChrome()"))
        #expect(root.contains("MeterSpacing.sidebarColumnWidth"))
        #expect(!root.contains("ideal: 240"))
        #expect(settings.contains("meterMacColumnBar"))
        #expect(services.contains("meterMacColumnBar"))
        #expect(dashboard.contains("meterMacColumnBar"))
        #expect(!transfer.contains("placement: .principal"))
        #expect(transfer.contains("safeAreaInset(edge: .top"))
    }

    @Test("设置页 Mac 走 grouped Form，不是 inset 密表")
    func settingsUsesGroupedFormOnMac() throws {
        let grouped = try GuardrailSourceScan.sourceText(named: "MeterGroupedList.swift")
        let settings = try GuardrailSourceScan.sourceText(named: "SettingsView.swift")
        #expect(grouped.contains("formStyle(.grouped)"))
        #expect(grouped.contains("listStyle(.insetGrouped)"))
        #expect(settings.contains("MeterGroupedList"))
        #expect(!settings.contains(".listStyle(.insetGrouped)"))
        #expect(settings.contains("meterListRowButtonStyle()"))
    }

    @Test("requestReveal 递增，consume 只吃一次")
    @MainActor
    func revealGenerationIsConsumedOnce() {
        let model = SettingsModel.preview
        #expect(model.revealGeneration == 0)
        #expect(model.consumeReveal() == false)
        model.requestReveal()
        #expect(model.revealGeneration == 1)
        model.requestReveal()
        #expect(model.revealGeneration == 2)
        #expect(model.consumeReveal())
        #expect(model.revealGeneration == 0)
        #expect(model.consumeReveal() == false)
    }

    @Test("开机自启动直接问系统，不落盘；注册失败时开关回到系统真值")
    @MainActor
    func launchAtLoginFollowsLoginItem() {
        let item = InMemoryLoginItem()
        let model = SettingsModel(dashboard: .preview, persistenceStatus: .preview, loginItem: item)
        #expect(!model.launchesAtLogin)

        model.setLaunchesAtLogin(true)
        #expect(item.isEnabled)
        #expect(model.launchesAtLogin)

        item.failsNextChange = true
        model.setLaunchesAtLogin(false)
        #expect(item.isEnabled)
        #expect(model.launchesAtLogin)

        item.isEnabled = false
        model.refreshLoginItemStatus()
        #expect(!model.launchesAtLogin)
    }

    @Test("关掉窗口后只留在菜单栏是这台 Mac 的事，落盘且清库后回默认")
    @MainActor
    func hidesDockIconPersistsAndResets() {
        let model = SettingsModel(dashboard: .preview, persistenceStatus: .preview, loginItem: InMemoryLoginItem())
        #expect(!model.hidesDockIconWhenWindowClosed)
        model.setHidesDockIconWhenWindowClosed(true)
        let reloaded = SettingsModel(
            dashboard: model.dashboard,
            persistenceStatus: .preview,
            loginItem: InMemoryLoginItem()
        )
        #expect(reloaded.hidesDockIconWhenWindowClosed)
        model.confirmClearAllData()
        #expect(!model.hidesDockIconWhenWindowClosed)
    }
}
