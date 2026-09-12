import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

/// 三个 tab 的壳。玻璃和滚动收起交给系统，不要在这里手搓材质。
public struct RootView: View {
    @Bindable var dashboardModel: DashboardModel
    var persistenceStatus: PersistenceStatus
    @Bindable var settingsModel: SettingsModel
    @State private var servicesModel: ServicesModel
    @State private var selectedTab: AppTab = .dashboard
    @State private var reminderPresenter = ReminderNotificationPresenter()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.usageAnalytics) private var usageAnalytics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var windowSize = UsesPadChrome.initialWindowSize
    @State private var forceOnboarding = FeatureLaunchArguments.openOnboarding
    @State private var presentedUsageGuide: UsageGuideID?
    @State private var didFinishOnboardingThisLaunch = false
    @State private var didConsiderUsageGuideThisLaunch = false
    @State private var pendingWhatsNew: [WhatsNewEntry] = []
    @State private var didConsiderWhatsNewThisLaunch = false
    @State private var compositionRevealEpoch = 0
    /// widget 点进来要去的那一页。`DashboardView` 消费完置回 nil。
    @State private var deepLink: DashboardRoute?
    #if DEBUG
    @State private var forceGalleryItem = FeatureLaunchArguments.openGalleryItem
    #endif

    public init(
        dashboardModel: DashboardModel,
        persistenceStatus: PersistenceStatus = .preview,
        settingsModel: SettingsModel? = nil
    ) {
        self.dashboardModel = dashboardModel
        self.persistenceStatus = persistenceStatus
        self.settingsModel = settingsModel ?? SettingsModel(
            dashboard: dashboardModel,
            persistenceStatus: persistenceStatus
        )
        _servicesModel = State(initialValue: ServicesModel(dashboard: dashboardModel))
        if let startTab = FeatureLaunchArguments.startTab {
            _selectedTab = State(initialValue: startTab)
        }
    }

    /// widget / 深链的落点。
    private func open(_ url: URL) {
        guard !showsOnboarding else { return }
        if let navigation = SettingsDeepLink.navigation(from: url) {
            selectedTab = .settings
            settingsModel.presentNavigation(navigation)
            return
        }
        if DashboardDeepLink.isDashboard(url) {
            selectedTab = .dashboard
        } else if let route = DashboardDeepLink.route(from: url) {
            selectedTab = .dashboard
            deepLink = route
        }
    }

    public var body: some View {
        Group {
            if showsOnboarding {
                OnboardingView(
                    initialPage: FeatureLaunchArguments.onboardingPage,
                    presentation: dashboardModel.moneyPresentation,
                    availableCurrencies: dashboardModel.availableDisplayCurrencies,
                    onDisplayCurrencyChange: { dashboardModel.setDisplayCurrency($0) },
                    onSkip: finishOnboarding,
                    onAddFirstProvider: finishOnboardingAndAdd
                )
            } else {
                tabs
                    #if os(iOS)
                    .tabBarMinimizeBehavior(.onScrollDown)
                    #endif
                    .sensoryFeedback(.selection, trigger: selectedTab)
                    .onAppear {
                        considerWhatsNewIfNeeded()
                        considerUsageGuideIfNeeded()
                    }
            }
        }
        .meterControlChrome()
        .environment(\.meterShell, shell)
        .environment(\.moneyPresentation, dashboardModel.moneyPresentation)
        .environment(\.compositionRevealEpoch, compositionRevealEpoch)
        .environment(\.selectedAppTab, showsOnboarding ? nil : selectedTab)
        // widget 的落点。认不出来的 URL 一律不动——宁可当没点过，也别猜一个页面推出去。
        .onOpenURL { open($0) }
        .onChange(of: selectedTab) { old, new in
            if new == .dashboard, old != .dashboard {
                compositionRevealEpoch += 1
            }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { windowSize = $0 }
        .preferredColorScheme(settingsModel.appearance.preferredColorScheme)
        .task {
            await dashboardModel.refreshCatalog()
            reminderPresenter.onOpenSettings = { [settingsModel] in
                settingsModel.present(nil)
            }
            reminderPresenter.install()
            #if DEBUG
            if let seconds = FeatureLaunchArguments.scheduleReminderInSeconds, seconds > 0 {
                await settingsModel.scheduleDebugReminder(in: seconds)
            } else {
                await settingsModel.alignRemindersOnLaunch()
            }
            #else
            await settingsModel.alignRemindersOnLaunch()
            #endif
        }
        #if DEBUG
        .environment(DeveloperSession.shared)
        .task {
            if let raw = FeatureLaunchArguments.clockPreset,
               let preset = DeveloperClockPreset(rawValue: raw) {
                DeveloperSession.shared.apply(preset, to: dashboardModel)
            }
            // 主屏上的小组件截不到，只能把那几格渲成图交给宣传图那一层。
            if FeatureLaunchArguments.dumpsWidgetTiles {
                await DeveloperWidgetTileDump.write(
                    dashboard: dashboardModel,
                    appearance: settingsModel.appearance
                )
            }
        }
        .sheet(isPresented: Binding(
            get: { forceGalleryItem != nil },
            set: { if !$0 { forceGalleryItem = nil } }
        )) {
            NavigationStack {
                Group {
                    if let raw = forceGalleryItem, let id = GalleryItemID(rawValue: raw) {
                        GalleryRegistry.view(id: id)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(L("完成")) { forceGalleryItem = nil }
                    }
                }
            }
        }
        #endif
        .sheet(isPresented: Binding(
            get: { !pendingWhatsNew.isEmpty },
            set: { if !$0 { pendingWhatsNew = [] } }
        )) {
            WhatsNewDrawerView(entries: pendingWhatsNew) {
                dashboardModel.shell.markWhatsNewSeen(currentVersion: settingsModel.shortVersion)
            }
            .onDisappear {
                dashboardModel.shell.markWhatsNewSeen(currentVersion: settingsModel.shortVersion)
            }
        }
        .sheet(item: $presentedUsageGuide) { id in
            UsageGuideDrawerView(guide: .make(id)) {
                dashboardModel.shell.markUsageGuideSeen(id.rawValue)
            }
            .onDisappear {
                dashboardModel.shell.markUsageGuideSeen(id.rawValue)
            }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .background || phase == .inactive {
                usageAnalytics.flush()
            }
            guard phase == .active else { return }
            Task { await dashboardModel.refreshUsageIfNeededOnActivate() }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            guard selectedTab == .dashboard, !showsOnboarding else { return }
            compositionRevealEpoch += 1
        }
        .onOpenURL { url in
            guard url.pathExtension.lowercased() == "tollcat" else { return }
            forceOnboarding = false
            didConsiderUsageGuideThisLaunch = true
            presentedUsageGuide = nil
            if !dashboardModel.shell.hasCompletedOnboarding {
                didFinishOnboardingThisLaunch = true
                dashboardModel.shell.completeOnboarding()
            }
            selectedTab = .settings
            settingsModel.presentImport(url: url)
        }
        .onChange(of: settingsModel.revealGeneration) { _, generation in
            guard generation > 0 else { return }
            selectedTab = .settings
            _ = settingsModel.consumeReveal()
        }
        .onChange(of: settingsModel.clearSuccessToken) { _, token in
            guard token > 0 else { return }
            selectedTab = .dashboard
        }
        .onAppear {
            if settingsModel.consumeReveal() {
                selectedTab = .settings
            }
        }
    }

    private var shell: MeterShell {
        UsesPadChrome.shell(sizeClass: horizontalSizeClass, size: windowSize)
    }

    private var usesPadChrome: Bool {
        shell.usesWideChrome
    }

    private var showsOnboarding: Bool {
        forceOnboarding || !dashboardModel.shell.hasCompletedOnboarding
    }

    private func finishOnboarding() {
        forceOnboarding = false
        didFinishOnboardingThisLaunch = true
        dashboardModel.shell.completeOnboarding()
    }

    /// 更新后第一次冷启动那张抽屉。放在利用指南之前：刚更新完，先说这一版有什么。
    ///
    /// 无论弹没弹，都把「看到哪一版」推到当前版本——机会用掉了。
    private func considerWhatsNewIfNeeded() {
        guard !didConsiderWhatsNewThisLaunch else { return }
        didConsiderWhatsNewThisLaunch = true
        // Preview 自己有抽屉的 #Preview，根界面预览不要被挡。
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1",
           !FeatureLaunchArguments.openWhatsNewDrawer {
            return
        }
        if FeatureLaunchArguments.openWhatsNewDrawer {
            // 模拟器上的库永远是新装的，正常判据永远不成立。截图钩子直接给内容。
            let forced = WhatsNewLaunch.history()
            #if DEBUG
            // 首发之前 changelog.json 是空的，开发构建退回样例，好让抽屉能看。
            pendingWhatsNew = forced.isEmpty ? [.preview] : Array(forced.prefix(1))
            #else
            pendingWhatsNew = Array(forced.prefix(1))
            #endif
            return
        }
        pendingWhatsNew = WhatsNewLaunch.pending(
            currentVersion: settingsModel.shortVersion,
            lastSeenVersion: dashboardModel.shell.lastSeenWhatsNewVersion,
            hasCompletedOnboarding: dashboardModel.shell.hasCompletedOnboarding,
            completedOnboardingThisLaunch: didFinishOnboardingThisLaunch,
            skipDrawer: FeatureLaunchArguments.skipUsageGuideDrawer
        )
        dashboardModel.shell.markWhatsNewSeen(currentVersion: settingsModel.shortVersion)
    }

    private func considerUsageGuideIfNeeded() {
        guard !didConsiderUsageGuideThisLaunch else { return }
        didConsiderUsageGuideThisLaunch = true
        // Preview 自己有抽屉的 #Preview，根界面预览不要被挡。
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1",
           FeatureLaunchArguments.openUsageGuideDrawer == nil {
            return
        }
        if let forced = FeatureLaunchArguments.openUsageGuideDrawer,
           dashboardModel.shell.hasCompletedOnboarding {
            presentedUsageGuide = forced
            return
        }
        presentedUsageGuide = UsageGuideLaunch.nextUnseen(
            hasCompletedOnboarding: dashboardModel.shell.hasCompletedOnboarding,
            completedOnboardingThisLaunch: didFinishOnboardingThisLaunch,
            seenIDs: dashboardModel.shell.seenUsageGuideIDs,
            skipDrawer: FeatureLaunchArguments.skipUsageGuideDrawer
        )
    }

    private func finishOnboardingAndAdd() {
        finishOnboarding()
        selectedTab = .services
        dashboardModel.requestAddProvider()
    }

    @ViewBuilder
    private var tabs: some View {
        // Mac 的壳永远是宽版式（`MeterShell.mac.usesWideChrome`），所以这一句
        // 在 Mac 上恒走 `padSplit`——不需要 `#if os`，两个平台的两条路都参与编译。
        if usesPadChrome {
            padSplit
        } else {
            phoneTabs
        }
    }

    private var phoneTabs: some View {
        TabView(selection: $selectedTab) {
            // label 闭包形式：tab 条按钮要挂 UI 冒烟锚点，便利初始化器挂不上。
            Tab(value: AppTab.dashboard) {
                dashboardTab
            } label: {
                Label(L("仪表盘"), systemImage: Self.dashboardTabSymbol)
                    .accessibilityIdentifier(UITestID.tabDashboard)
            }

            Tab(value: AppTab.services) {
                ServicesView(model: servicesModel)
            } label: {
                Label(L("服务"), systemImage: "square.stack.3d.up")
                    .accessibilityIdentifier(UITestID.tabServices)
            }

            Tab(value: AppTab.settings) {
                SettingsView(model: settingsModel)
            } label: {
                Label(L("设置"), systemImage: "gearshape")
                    .accessibilityIdentifier(UITestID.tabSettings)
            }
        }
        .tabViewStyle(.tabBarOnly)
    }

    /// Mac 的外层永远两栏。两栏和三栏是两种 `NavigationSplitView`，来回切会把侧栏
    /// 和顶栏整棵拆掉重画；服务 / 设置的主从列在这一列里用 `PadSecondaryPair` 拼，
    /// 列头一律自画（`meterMacColumnBar`），不指望系统导航栏。
    ///
    /// iPad 不能跟着走这条：一个分栏列只发一条系统导航栏，`PadSecondaryPair` 里
    /// 第二根 `NavigationStack` 领不到自己的栏——详情列和它推进去的二级页会彻底
    /// 没有标题和返回钮。iPad 仍旧按 tab 换分栏形状，见 `padSplitByTab`。
    @ViewBuilder
    private var padSplit: some View {
        if shell == .mac {
            macSplit
        } else {
            padSplitByTab
        }
    }

    private var macSplit: some View {
        NavigationSplitView {
            padSidebar
        } detail: {
            Group {
                switch selectedTab {
                case .dashboard:
                    dashboardTab
                case .services:
                    ServicesView(model: servicesModel)
                case .settings:
                    SettingsView(model: settingsModel)
                }
            }
            // Mac：主区所有滚动面统一 token 画布，别让 List/Form 自己铺灰。
            .meterMacDetailCanvas()
        }
        .navigationSplitViewStyle(.balanced)
        .meterSplitViewChrome()
    }

    /// iPad：服务 / 设置三栏，仪表盘两栏。三栏的两列各是真正的分栏列，
    /// 大标题、列内推进的返回钮、每列自己的工具栏按钮都由系统给。
    /// 不用 `sidebarAdaptable`：它在 iPad 上经常还是顶栏，侧栏还要人自己点出来。
    @ViewBuilder
    private var padSplitByTab: some View {
        switch selectedTab {
        case .dashboard:
            NavigationSplitView {
                padSidebar
            } detail: {
                dashboardTab
            }
            .navigationSplitViewStyle(.balanced)
        case .services:
            NavigationSplitView {
                padSidebar
            } content: {
                ServicesView(model: servicesModel)
                    .environment(\.padColumn, .list)
                    .navigationSplitViewColumnWidth(
                        min: 360,
                        ideal: MeterSpacing.phoneColumn,
                        max: 430
                    )
            } detail: {
                ServicesView(model: servicesModel)
                    .environment(\.padColumn, .detail)
            }
            .navigationSplitViewStyle(.balanced)
        case .settings:
            NavigationSplitView {
                padSidebar
            } content: {
                SettingsView(model: settingsModel)
                    .environment(\.padColumn, .list)
                    .navigationSplitViewColumnWidth(
                        min: 360,
                        ideal: MeterSpacing.phoneColumn,
                        max: 430
                    )
            } detail: {
                SettingsView(model: settingsModel)
                    .environment(\.padColumn, .detail)
            }
            .navigationSplitViewStyle(.balanced)
        }
    }

    private var padSidebar: some View {
        let column = MeterSpacing.sidebarColumnWidth(
            hasPinnedModule: dashboardModel.sidebarModuleID != nil
        )
        return List(selection: padTabSelection) {
            Label(L("仪表盘"), systemImage: Self.dashboardTabSymbol)
                .tag(AppTab.dashboard)
                .accessibilityIdentifier(UITestID.tabDashboard)
            Label(L("服务"), systemImage: "square.stack.3d.up")
                .tag(AppTab.services)
                .accessibilityIdentifier(UITestID.tabServices)
            Label(L("设置"), systemImage: "gearshape")
                .tag(AppTab.settings)
                .accessibilityIdentifier(UITestID.tabSettings)
        }
        .modifier(PadSidebarIdentity())
        .meterSplitColumnChrome()
        .navigationSplitViewColumnWidth(min: column.min, ideal: column.ideal, max: column.max)
        // 侧栏底下那段空：用户可以在「编辑」里挑一块一格宽的模块钉在这里，主区就不再画它。
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let id = dashboardModel.sidebarModuleID {
                DashboardSidebarCard(id: id, model: dashboardModel)
                    .environment(\.dashboardRouteOpener) { route in
                        selectedTab = .dashboard
                        dashboardModel.requestOpen(route)
                    }
            }
        }
    }

    /// iOS 的 `List(selection:)` 只要 Optional；TabView 那边继续用非 Optional。
    private var padTabSelection: Binding<AppTab?> {
        Binding(
            get: { selectedTab },
            set: { if let tab = $0 { selectedTab = tab } }
        )
    }

    private var dashboardTab: some View {
        DashboardView(
            model: dashboardModel,
            persistenceStatus: persistenceStatus,
            onOpenServices: { selectedTab = .services },
            deepLink: $deepLink
        )
    }

    /// 默认呼应分段横条；`-tab-icon=` 只用来并排对比候选。
    private static var dashboardTabSymbol: String {
        FeatureLaunchArguments.dashboardTabSymbol ?? "rectangle.split.3x1"
    }
}

#Preview("Light") {
    @Previewable @State var model = DashboardModel.preview
    RootView(dashboardModel: model)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var model = DashboardModel.preview
    RootView(dashboardModel: model)
        .preferredColorScheme(.dark)
}

#Preview("Empty") {
    @Previewable @State var model = DashboardModel.previewEmpty
    RootView(dashboardModel: model)
}

#Preview("Pad") {
    @Previewable @State var model = DashboardModel.preview
    RootView(dashboardModel: model)
        .environment(\.horizontalSizeClass, .regular)
}
