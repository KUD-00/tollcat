import SwiftUI
import MeterDesign
import MeterPersistence
import MeterUsage

public struct SettingsView: View {
    @Bindable var model: SettingsModel
    @State private var path = NavigationPath()
    @State private var detailPath = NavigationPath()
    /// Mac 分栏 detail 列的手工推入栈，见 `MacColumnStackModel`。
    @State private var macDetailStack = MacColumnStackModel()
    @Environment(\.usesPadChrome) private var usesPadChrome
    @Environment(\.meterShell) private var shell
    @Environment(\.padColumn) private var padColumn
    @Environment(\.selectedAppTab) private var selectedAppTab

    public init(model: SettingsModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            switch padColumn {
            case .list:
                settingsListColumn
            case .detail:
                settingsDetailColumn
            case nil:
                if usesPadChrome {
                    padSplit
                } else {
                    phoneStack
                }
            }
        }
        .onChange(of: model.inboundTransferURL) { _, url in
            if url != nil {
                open(.importExport)
            }
        }
        .onChange(of: model.settingsNavigationGeneration) { _, generation in
            guard generation > 0 else { return }
            guard padColumn != .detail else { return }
            applyPendingSettingsNavigation()
        }
        .onAppear {
            guard padColumn != .detail else { return }
            applyPendingSettingsNavigation()
        }
        .sheet(isPresented: reminderOptInBinding) {
            ReminderOptInSheet(
                onAllow: {
                    Task { await model.confirmReminderOptIn() }
                },
                onDecline: {
                    model.cancelReminderOptIn()
                }
            )
        }
        .sensoryFeedback(.success, trigger: padColumn == .detail ? 0 : model.clearSuccessToken)
        .onChange(of: model.selectedPane) { _, _ in
            macDetailStack.popToRoot()
        }
        .recordsUsageScreen(settingsUsageScreen, isActive: settingsUsageIsActive)
        .task {
            if padColumn != .detail {
                try? await Task.sleep(for: .milliseconds(250))
                applyLaunchHooks()
                model.refreshLoginItemStatus()
                await model.refreshReminderAuthorization()
            }
            #if DEBUG
            if padColumn != .list {
                await openDeveloperDestinationIfNeeded()
            }
            #endif
        }
    }

    private var phoneStack: some View {
        NavigationStack(path: $path) {
            settingsList
                .navigationDestination(for: SettingsRoute.self) { route in
                    SettingsDestinationView(route: route, model: model)
                }
                #if DEBUG
                .navigationDestination(for: DeveloperRoute.self) { _ in
                    DeveloperToolsView(model: model)
                }
                .modifier(DeveloperSettingsDestinations(model: model))
                #endif
        }
    }

    private var padSplit: some View {
        PadSecondaryPair(
            list: settingsListColumn,
            detail: settingsDetailColumn
        )
    }

    private var settingsListColumn: some View {
        NavigationStack { settingsList }
            .meterSplitColumnChrome()
            .meterMacColumnBar(title: Text(L("设置")))
    }

    private var settingsDetailColumn: some View {
        padDetailStack
            .meterSplitColumnChrome()
            .meterMacColumnBar(
                title: settingsDetailTitle,
                showBack: macDetailStack.canPop || !detailPath.isEmpty,
                onBack: {
                    if macDetailStack.canPop {
                        macDetailStack.pop()
                    } else if !detailPath.isEmpty {
                        detailPath.removeLast()
                    }
                }
            )
    }

    private var padDetailStack: some View {
        NavigationStack(path: $detailPath) {
            macWrappedDetailRoot
                #if DEBUG
                .navigationDestination(for: DeveloperRoute.self) { _ in
                    DeveloperToolsView(model: model)
                }
                .modifier(DeveloperSettingsDestinations(model: model))
                #endif
        }
    }

    /// Mac 上整个 detail 面（含开发页）都套手工栈，推入一律列内换页。
    @ViewBuilder
    private var macWrappedDetailRoot: some View {
        if shell == .mac {
            MacColumnStack(model: macDetailStack) { padDetailRoot }
        } else {
            padDetailRoot
        }
    }

    @ViewBuilder
    private var padDetailRoot: some View {
        switch model.selectedPane {
        case .route(let route):
            SettingsDestinationView(route: route, model: model)
        case .developer:
            #if DEBUG
            DeveloperToolsView(model: model)
            #else
            settingsPlaceholder
            #endif
        case nil:
            settingsPlaceholder
        }
    }

    private func appendDetail<Value: Hashable>(_ value: Value) {
        if usesPadChrome {
            detailPath.append(value)
        } else {
            path.append(value)
        }
    }

    private var settingsPlaceholder: some View {
        ContentUnavailableView {
            Label(L("选择一项设置"), systemImage: "gearshape")
        } description: {
            Text(L("从左边选一项。"))
        }
    }

    /// nil = 没选设置项（空态）。列头不能再兜「设置」——和列表列的标题重复。
    private var settingsDetailTitle: Text? {
        if let top = macDetailStack.topTitle {
            return top
        }
        return switch model.selectedPane {
        case .route(let route):
            Text(route.title)
        case .developer:
            #if DEBUG
            Text(L("开发"))
            #else
            nil
            #endif
        case nil:
            nil
        }
    }

    private var settingsList: some View {
        MeterGroupedList {
            tipSection
            generalSection
            ReminderSettingsSection(model: model)
            dataSection
            otherSection
            dangerSection
        }
        .accessibilityIdentifier(UITestID.settingsList)
        .navigationTitle(L("设置"))
        .navigationBarTitleDisplayMode(.large)
    }

    /// 打赏单独一节提到整份设置最上面。仍然是系统的分组行——图标 + 名称 + 说明 + chevron，
    /// 显眼靠的是位置和这颗糖（全份设置只有这一行有画），不是把它做成一张广告位。
    private var tipSection: some View {
        Section {
            settingsLink(route: .tip, hint: L("打开打赏页")) {
                HStack(spacing: MeterSpacing.sm) {
                    TipTreatView(kind: .candy, size: MeterSpacing.tipTreatRow)
                    VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                        Text(L("请猫猫吃点东西"))
                        ListRowNote(text: L("这是打赏，不解锁任何功能。"))
                    }
                }
            }
        }
    }

    private var generalSection: some View {
        Section {
            Picker(L("外观"), selection: appearanceBinding) {
                Text(L("亮色")).tag(AppearancePreference.light)
                Text(L("暗色")).tag(AppearancePreference.dark)
                Text(L("跟随系统")).tag(AppearancePreference.system)
            }
            .accessibilityLabel(L("外观"))

            Picker(L("显示货币"), selection: displayCurrencyBinding) {
                ForEach(model.availableDisplayCurrencies, id: \.self) { code in
                    Text(DisplayCurrencyCopy.pickerLabel(for: code)).tag(code)
                }
            }
            .accessibilityLabel(L("显示货币"))
            .accessibilityHint(L("账本按美元记。选别的货币时，按目录里的汇率换算显示，和厂商实际结算价会有出入。"))

            Toggle(isOn: refreshesUsageOnActivateBinding) {
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    Text(L("每次进入 App 的时候自动刷新用量"))
                    ListRowNote(text: L("花钱才能刷新的服务不会跟着刷。"))
                }
            }
            .accessibilityLabel(L("每次进入 App 的时候自动刷新用量"))
            .accessibilityHint(L("花钱才能刷新的服务不会跟着刷。"))

            Toggle(isOn: showsCatBinding) {
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    Text(L("打开猫猫"))
                    ListRowNote(text: L("仪表上不再出现猫。"))
                }
            }
            .accessibilityLabel(L("打开猫猫"))
            .accessibilityHint(L("仪表上不再出现猫。"))
            .accessibilityIdentifier(UITestID.settingsHideCat)

            #if os(macOS)
            Picker(L("菜单栏样式"), selection: menuBarStyleBinding) {
                Text(L("只有猫猫")).tag(MenuBarStyle.cat)
                Text(L("猫猫和金额")).tag(MenuBarStyle.catAndAmount)
                Text(L("只有金额")).tag(MenuBarStyle.amount)
            }
            .accessibilityLabel(L("菜单栏样式"))

            Toggle(isOn: launchesAtLoginBinding) {
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    Text(L("开机自启动"))
                    if model.loginItemRequiresApproval {
                        ListRowNote(text: L("要在「系统设置 › 通用 › 登录项」里允许 TollCat。"))
                    }
                }
            }
            .accessibilityLabel(L("开机自启动"))

            Toggle(isOn: hidesDockIconBinding) {
                Text(L("关掉窗口后只留在菜单栏"))
            }
            .accessibilityLabel(L("关掉窗口后只留在菜单栏"))
            #endif

            // 使用指南暂时不摆进设置页：内容还没定稿。路由和 `-open-usage-guides`
            // 启动参数都留着，画廊和截图脚本仍然进得去。
            settingsLink(route: .whatsNew, title: L("更新说明"), hint: L("打开每一版的更新说明"))
        } header: {
            Text(L("通用"))
        }
    }

    #if os(macOS)
    private var menuBarStyleBinding: Binding<MenuBarStyle> {
        Binding(
            get: { model.menuBarStyle },
            set: { model.setMenuBarStyle($0) }
        )
    }

    private var launchesAtLoginBinding: Binding<Bool> {
        Binding(
            get: { model.launchesAtLogin },
            set: { model.setLaunchesAtLogin($0) }
        )
    }

    private var hidesDockIconBinding: Binding<Bool> {
        Binding(
            get: { model.hidesDockIconWhenWindowClosed },
            set: { model.setHidesDockIconWhenWindowClosed($0) }
        )
    }
    #endif

    private var appearanceBinding: Binding<AppearancePreference> {
        Binding(
            get: { model.appearance },
            set: { model.setAppearance($0) }
        )
    }

    private var displayCurrencyBinding: Binding<String> {
        Binding(
            get: { model.displayCurrency },
            set: { model.setDisplayCurrency($0) }
        )
    }

    private var showsCatBinding: Binding<Bool> {
        Binding(
            get: { !model.hidesCat },
            set: { model.setHidesCat(!$0) }
        )
    }

    private var refreshesUsageOnActivateBinding: Binding<Bool> {
        Binding(
            get: { model.refreshesUsageOnActivate },
            set: { model.setRefreshesUsageOnActivate($0) }
        )
    }

    private var otherSection: some View {
        Section {
            settingsLink(route: .feedback, title: L("反馈"), hint: L("提一条反馈"))

            settingsLink(route: .about, hint: L("打开关于页")) {
                LabeledContent(L("关于")) {
                    Text(model.versionCaption)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .monospacedDigit()
                }
            }

            #if DEBUG
            developerLink
            #endif
        } header: {
            Text(L("其他"))
        }
    }

    private func settingsLink(
        route: SettingsRoute,
        title: LocalizedStringResource,
        hint: LocalizedStringResource
    ) -> some View {
        settingsLink(route: route, hint: hint) {
            Text(title)
        }
    }

    @ViewBuilder
    private func settingsLink<Label: View>(
        route: SettingsRoute,
        hint: LocalizedStringResource,
        @ViewBuilder label: () -> Label
    ) -> some View {
        if usesPadChrome {
            PadSplitRowButton(
                isSelected: model.selectedPane == .route(route),
                hint: hint,
                action: { model.selectedPane = .route(route) },
                label: label
            )
        } else {
            NavigationLink(value: route, label: label)
                .accessibilityHint(hint)
        }
    }

    #if DEBUG
    @ViewBuilder
    private var developerLink: some View {
        if usesPadChrome {
            PadSplitRowButton(
                isSelected: model.selectedPane == .developer,
                hint: L("调试工具和组件画廊"),
                action: { model.selectedPane = .developer }
            ) {
                Text(L("开发"))
            }
            .accessibilityLabel(L("开发"))
        } else {
            NavigationLink(value: DeveloperRoute.home) {
                Text(L("开发"))
            }
            .accessibilityLabel(L("开发"))
            .accessibilityHint(L("调试工具和组件画廊"))
        }
    }
    #endif

    private func applyPendingSettingsNavigation() {
        guard let navigation = model.consumePendingSettingsNavigation() else { return }
        switch navigation {
        case .root:
            popToSettingsRoot()
        case .route(let route):
            open(route)
        }
    }

    private func popToSettingsRoot() {
        if usesPadChrome {
            model.selectedPane = nil
            detailPath = NavigationPath()
        } else {
            path = NavigationPath()
        }
    }

    private func open(_ route: SettingsRoute) {
        if usesPadChrome {
            model.selectedPane = .route(route)
            detailPath = NavigationPath()
        } else {
            var next = NavigationPath()
            next.append(route)
            path = next
        }
    }

    private func applyLaunchHooks() {
        if FeatureLaunchArguments.openUsageGuides {
            open(.usageGuides)
        }
        if FeatureLaunchArguments.openWhatsNew {
            open(.whatsNew)
        }
        if FeatureLaunchArguments.openAbout {
            open(.about)
        }
        if FeatureLaunchArguments.openTip {
            open(.tip)
        }
        if FeatureLaunchArguments.openTransferExport
            || FeatureLaunchArguments.openTransferImport
            || FeatureLaunchArguments.transferImportBanner != nil
            || model.inboundTransferURL != nil {
            open(.importExport)
        }
        if FeatureLaunchArguments.openInbox {
            open(.inbox)
        }
        if FeatureLaunchArguments.openFeedback {
            open(.feedback)
        }
        #if DEBUG
        if FeatureLaunchArguments.openDeveloper
            || FeatureLaunchArguments.openGalleryItem != nil
            || FeatureLaunchArguments.openDeveloperTool != nil {
            if usesPadChrome {
                model.selectedPane = .developer
            } else {
                path.append(DeveloperRoute.home)
            }
        }
        #endif
    }

    #if DEBUG
    private func openDeveloperDestinationIfNeeded() async {
        if FeatureLaunchArguments.openGalleryItem != nil {
            try? await Task.sleep(for: .milliseconds(200))
            appendDetail(DeveloperToolID.gallery)
            try? await Task.sleep(for: .milliseconds(200))
            if let raw = FeatureLaunchArguments.openGalleryItem,
               let id = GalleryItemID(rawValue: raw) {
                appendDetail(id)
            }
            return
        }
        if let raw = FeatureLaunchArguments.openDeveloperTool,
           let id = DeveloperToolID(rawValue: raw) {
            try? await Task.sleep(for: .milliseconds(200))
            appendDetail(id)
        }
    }
    #endif

    private var dataSection: some View {
        Section {
            settingsLink(
                route: .inbox,
                title: L("读数信箱"),
                hint: L("管理你自己投递读数用的信箱和投递 key")
            )

            settingsLink(
                route: .importExport,
                title: L("导入与导出"),
                hint: L("把接入转到另一台设备，或从加密文件恢复")
            )
        } header: {
            Text(L("数据"))
        } footer: {
            if !model.persistenceStatus.notices.isEmpty {
                PersistenceNoticeList(status: model.persistenceStatus) {
                    model.dismissDemoBanner()
                }
            }
        }
    }

    private var dangerSection: some View {
        Section {
            // 注解跟在按钮下面、同一行里。单独再占一行会画出分隔线。
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Button(role: .destructive) {
                    model.isConfirmingClear = true
                } label: {
                    Text(L("清除全部数据"))
                        .meterListRowHitTarget()
                }
                .meterListRowButtonStyle()
                .accessibilityHint(L("删除凭据和全部历史账单"))
                .confirmationDialog(
                    L("清除全部数据？"),
                    isPresented: $model.isConfirmingClear,
                    titleVisibility: .visible
                ) {
                    Button(L("清除全部数据"), role: .destructive) {
                        model.confirmClearAllData()
                    }
                    Button(L("取消"), role: .cancel) {}
                } message: {
                    Text(L("会删除 Keychain 里的全部凭据，以及本机上所有历史读数和手动订阅。此操作不能撤销。"))
                }

                ListRowNote(text: L("清除后，Keychain 里的凭据和所有历史读数都会从这台设备上删掉。"))
            }

            if let clearErrorMessage = model.clearErrorMessage {
                Text(clearErrorMessage)
                    .font(MeterFont.footnote)
                    .foregroundStyle(MeterColor.crit)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var reminderOptInBinding: Binding<Bool> {
        Binding(
            get: { padColumn != .detail && model.isPresentingReminderOptIn },
            set: { presented in
                if !presented {
                    model.cancelReminderOptIn()
                }
            }
        )
    }

    private var settingsUsageIsActive: Bool {
        guard selectedAppTab == .settings, padColumn != .list else { return false }
        if usesPadChrome { return true }
        return path.isEmpty
    }

    private var settingsUsageScreen: UsageAnalyticsScreen {
        if usesPadChrome, case .route(let route) = model.selectedPane {
            return route.usageScreen
        }
        return .settings
    }
}

#Preview("Light") {
    @Previewable @State var model = SettingsModel.preview
    SettingsView(model: model)
        #if DEBUG
        .environment(DeveloperSession.shared)
        #endif
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var model = SettingsModel.preview
    SettingsView(model: model)
        #if DEBUG
        .environment(DeveloperSession.shared)
        #endif
        .preferredColorScheme(.dark)
}

#Preview("Empty") {
    @Previewable @State var model = SettingsModel.previewEmpty
    SettingsView(model: model)
        #if DEBUG
        .environment(DeveloperSession.shared)
        #endif
}

#Preview("Denied") {
    @Previewable @State var model = SettingsModel.previewDenied
    SettingsView(model: model)
        #if DEBUG
        .environment(DeveloperSession.shared)
        #endif
}

#Preview("XXL") {
    @Previewable @State var model = SettingsModel.preview
    SettingsView(model: model)
        #if DEBUG
        .environment(DeveloperSession.shared)
        #endif
        .dynamicTypeSize(.accessibility3)
}

#Preview("Pad") {
    @Previewable @State var model = SettingsModel.preview
    SettingsView(model: model)
        #if DEBUG
        .environment(DeveloperSession.shared)
        #endif
        .environment(\.meterShell, .pad)
}
