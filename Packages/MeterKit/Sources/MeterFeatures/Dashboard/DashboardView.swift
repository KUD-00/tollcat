import SwiftUI
import MeterCore
import MeterDesign
import MeterUsage
import MeterProviders
import MeterModules

public struct DashboardView: View {
    @State private var isSharing = false
    @State private var isFiltering = false
    @State private var isEditingLayout = false
    var model: DashboardModel
    var persistenceStatus: PersistenceStatus
    var onOpenServices: () -> Void
    /// widget / 深链点进来要去的那一页。消费掉就置回 nil——
    /// 留着的话切走再切回来会再推一次。
    @Binding var deepLink: DashboardRoute?
    @State private var path: [DashboardRoute] = []
    /// Mac 列内的手工栈（构成 / 较上月同期 / 服务详情）。iPhone / iPad 不用。
    @State private var macStack = MacColumnStackModel()
    @State private var localRevealEpoch = 0
    @Environment(\.usesPadChrome) private var usesPadChrome
    @Environment(\.meterShell) private var shell
    @Environment(\.compositionRevealEpoch) private var parentRevealEpoch
    @Environment(\.selectedAppTab) private var selectedAppTab


    public init(
        model: DashboardModel,
        persistenceStatus: PersistenceStatus = .preview,
        onOpenServices: @escaping () -> Void = {},
        deepLink: Binding<DashboardRoute?> = .constant(nil)
    ) {
        self.model = model
        self.persistenceStatus = persistenceStatus
        self.onOpenServices = onOpenServices
        self._deepLink = deepLink
    }

    public var body: some View {
        stack
            // widget / 深链推进来的一页。消费完置回 nil，切走再切回来不会重推。
            .onChange(of: deepLink) { _, route in
                guard let route else { return }
                open(route)
                deepLink = nil
            }
            .onAppear {
                guard let route = deepLink else { return }
                open(route)
                deepLink = nil
            }
    }

    private var stack: some View {
        NavigationStack(path: $path) {
            macWrappedRoot
            // 卡里自己画箭头的链接（「查看更多 ›」）走这条：和系统栈 / Mac 手工栈同一个 open。
            .environment(\.dashboardInlineRouteOpener, { open($0) })
            .navigationTitle(monthTitle)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: DashboardRoute.self) { route in
                destination(for: route)
            }
            .meterNavigationToolbar { toolbarContent }
            .sheet(isPresented: $isSharing) {
                ShareCardSheet(model: ShareCardModel(dashboard: model))
            }
            // 挂在整页上：顶栏「更多」里的「编辑仪表盘」开的就是这张面。
            .sheet(isPresented: $isEditingLayout) {
                DashboardEditSheet(model: model)
            }
            .environment(\.compositionRevealEpoch, parentRevealEpoch + localRevealEpoch)
            .onChange(of: path) { old, new in
                if new.isEmpty, !old.isEmpty {
                    localRevealEpoch += 1
                }
            }
            .onChange(of: macStack.canPop) { _, canPop in
                if !canPop {
                    localRevealEpoch += 1
                }
            }
            // 侧栏底部那张卡里点的路线：切到仪表盘之后在这一列里开。
            .onChange(of: model.requestedRoute, initial: true) { _, route in
                guard let route else { return }
                open(route)
                model.consumeRequestedRoute()
            }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: model.refreshSuccessToken)
            .recordsUsageScreen(dashboardUsageScreen, isActive: selectedAppTab == .dashboard)
            .task {
                if FeatureLaunchArguments.openCompositionDetail, model.compositionContent != nil {
                    open(.composition)
                }
                if FeatureLaunchArguments.openComparisonDetail, model.comparisonContent != nil {
                    open(.comparison)
                }
                if let id = model.accountIDForOpenProviderDetail() {
                    open(.account(id))
                }
                if FeatureLaunchArguments.openFilter {
                    isFiltering = true
                }
                if FeatureLaunchArguments.openDashboardEdit {
                    isEditingLayout = true
                }
                if FeatureLaunchArguments.openShare {
                    isSharing = true
                }
            }
        }
        .meterSplitColumnChrome()
        .meterMacColumnBar(
            title: macStack.topTitle ?? Text(monthTitle),
            showBack: macStack.canPop || !path.isEmpty,
            onBack: {
                if macStack.canPop {
                    macStack.pop()
                } else if !path.isEmpty {
                    path.removeLast()
                }
            },
            actions: { dashboardColumnActions }
        )
    }

    @ViewBuilder
    private var root: some View {
        if model.isEmpty {
            DashboardEmptyView(
                onOpenServices: onOpenServices,
                persistenceStatus: persistenceStatus,
                onDismissDemo: { model.dismissDemoBanner() },
                didClearAllData: model.didClearAllData
            )
        } else {
            populated
        }
    }

    /// Mac 上整列套手工栈：详情从右平移进来，列头和返回由 `meterMacColumnBar` 接管。
    @ViewBuilder
    private var macWrappedRoot: some View {
        if shell == .mac {
            MacColumnStack(model: macStack) { root }
                .environment(\.dashboardRouteResolver, DashboardRouteResolver(
                    title: { title(for: $0) },
                    destination: { AnyView(destination(for: $0)) }
                ))
        } else {
            root
        }
    }

    /// 推一页详情。Mac 推列内手工栈（系统栈会接管整个主区、往顶栏塞返回钮），
    /// 其他平台走系统栈。壳是运行时的值（`MeterShell`），不是编译期分叉——
    /// 两条路在两个平台上都参与编译。
    private func open(_ route: DashboardRoute) {
        if shell == .mac {
            macStack.push(title: title(for: route), tag: route, destination: destination(for: route))
        } else {
            path.append(route)
        }
    }

    private func title(for route: DashboardRoute) -> Text {
        switch route {
        case .composition:
            Text(L("构成"))
        case .comparison:
            Text(L("较上月同期"))
        case .account(let id):
            Text(providerDisplayName(providerID(forAccount: id)))
        case .provider(let id):
            Text(providerDisplayName(id))
        case .subscriptions:
            Text(L("固定订阅"))
        case .heatmap:
            Text(L("日历热力图"))
        case .categories:
            Text(L("按类别构成"))
        }
    }

    @ViewBuilder
    private func destination(for route: DashboardRoute) -> some View {
        switch route {
        case .composition:
            if let content = model.compositionContent {
                CompositionDetailView(content: content)
            }
        case .comparison:
            if let content = model.comparisonContent {
                ComparisonDetailView(content: content)
            }
        case .account(let id):
            // 账号在接入表里找不到就不进详情——默认成 Cloudflare 是把别家的钱挂错名。
            if let providerID = providerID(forAccount: id) {
                ProviderDetailView(
                    model: ProviderDetailModel(providerID: providerID, dashboard: model)
                )
                .id(id)
            }
        case .provider(let id):
            ProviderDetailView(
                model: ProviderDetailModel(providerID: id, dashboard: model)
            )
            .id(id)
        case .subscriptions:
            if let content = model.subscriptionsContent {
                SubscriptionsDetailView(content: content)
            }
        case .heatmap:
            if let content = model.heatmapContent {
                HeatmapDetailView(content: content)
            }
        case .categories:
            if let content = model.categoriesContent {
                CategoriesDetailView(content: content)
            }
        }
    }

    private func providerID(forAccount id: AccountID) -> ProviderID? {
        model.connectionStates().first(where: { $0.accountID == id })?.providerID
    }

    private func providerDisplayName(_ id: ProviderID?) -> String {
        guard let id else { return "" }
        return ProviderCatalog.descriptor(id: id)?.displayName ?? id.rawValue
    }

    /// 标题跟着取景框走。回看七月时标题还写「八月」，页面就在自我矛盾。
    /// 多月区间同理：标题写「近 3 个月」「五月–七月」，和筛选面板上选中的那颗一致。
    /// 单个整月仍然写月份名（不是「本月」）——标题会跟着页面滚走，
    /// 再看到它的时候「本月」已经说不清是哪个月了。
    private var monthTitle: String {
        let asOf = model.filter.anchor(now: model.clock.now, calendar: model.clock.calendar)
        return DashboardFilterSummary.periodHeading(
            period: model.filter.period,
            window: model.filterWindow,
            asOf: asOf,
            calendar: model.clock.calendar
        )
    }

    private var attentionIDs: [DashboardModuleID] {
        DashboardModuleRegion.attentionIDs(from: model.visibleModuleIDs)
    }

    private var showsComposition: Bool {
        DashboardModuleRegion.hasComposition(in: model.visibleModuleIDs)
            && model.compositionContent != nil
    }

    private var showsEnvironmentFooter: Bool {
        !persistenceStatus.notices.isEmpty || model.refreshFailureCaption != nil
    }

    /// 模块视图住在 MeterModules，它自己不知道怎么推页。这一列的推法在这里接上；
    /// 分享卡和 widget 不接，链接在那边退化成纯文字。
    @ViewBuilder
    private var populated: some View {
        populatedBody
            .dashboardModuleLinks()
    }

    @ViewBuilder
    private var populatedBody: some View {
        if usesPadChrome {
            DashboardPadLayout(
                model: model,
                persistenceStatus: persistenceStatus,
                onOpenProvider: { open(.account($0)) },
                onOpenComposition: { open(.composition) },
                onOpenComparison: { open(.comparison) }
            )
        } else {
            List {
                heroAndComposition
                bodySections
            }
            .listStyle(.insetGrouped)
            // 手机列表是模块的老家：行修饰交给 List，宽度一路在 regular 档
            // （最窄的 iPhone 扣掉页边也有 288pt）。默认值就是这一对，
            // 仍然明写出来——容器不声明档位，读的人分不清是「没写」还是「就是默认」。
            .meterModuleStyle(width: .regular, height: .unbounded, container: .listRow)
            .environment(\.defaultMinListHeaderHeight, 0)
            .contentMargins(.top, MeterSpacing.xs, for: .scrollContent)
            .meterRefreshable { await model.refresh() }
        }
    }

    @ViewBuilder
    private var heroAndComposition: some View {
        let needsFooter = showsEnvironmentFooter && bodySectionList.isEmpty
        // 合计不能单独成节。insetGrouped 会按连续圆角裁切，单行节四个角都是圆的，
        // 「预计月底」贴左下角就会被削——垫多少底 inset 都不够，再垫饼图更远。
        // 跟构成卡同一行：字不在圆角上，猫叠在数字那一行，空隙收到一半。
        Section {
            DashboardCatStage(
                composition: showsComposition ? model.compositionContent : nil,
                mood: model.catMood,
                speech: model.catSpeech,
                showsCat: !model.shell.hidesCat,
                monthToDate: model.monthToDateContent,
                comparison: showsComposition ? model.comparisonContent : nil,
                trend: showsComposition ? model.trendContent : nil,
                onOpenComposition: { open(.composition) },
                onOpenComparison: { open(.comparison) },
                onSelectSubscription: {
                    if let id = model.monthToDateContent?.subscriptionAccountID {
                        open(.account(id))
                    }
                },
                onToggleSubscriptions: { model.setIncludesSubscriptions($0) }
            )
            .listRowBackground(Color.meterGroupedBackground)
            .listRowSeparator(.hidden)
            .listRowInsets(
                EdgeInsets(
                    top: 0,
                    leading: -MeterSpacing.pageHorizontal,
                    bottom: 0,
                    trailing: -MeterSpacing.pageHorizontal
                )
            )
        } footer: {
            if needsFooter {
                environmentFooter
            }
        }
    }

    /// 英雄区之外的模块，按版式顺序各成一节；相邻的「需要注意」并成一节。
    private var bodySectionList: [DashboardModuleRegion.Section] {
        DashboardModuleRegion.sections(from: model.visibleModuleIDs)
    }

    @ViewBuilder
    private var bodySections: some View {
        let sections = bodySectionList
        ForEach(sections) { section in
            let isLast = section == sections.last
            Section {
                ForEach(section.ids) { id in
                    DashboardModuleFactory.view(id: id, contents: model)
                }
            } header: {
                Text(
                    section.isAttention
                        ? String(localized: L("需要注意"))
                        : (section.ids.first.map { model.moduleTitle(for: $0) }
                            ?? String(localized: L("需要注意")))
                )
            } footer: {
                if isLast, showsEnvironmentFooter {
                    environmentFooter
                }
            }
        }
    }

    @ViewBuilder
    private var environmentFooter: some View {
        if showsEnvironmentFooter {
            VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                PersistenceNoticeList(status: persistenceStatus) {
                    model.dismissDemoBanner()
                }
                if let refreshFailureCaption = model.refreshFailureCaption {
                    Text(refreshFailureCaption)
                        .font(MeterFont.footnote)
                        .foregroundStyle(MeterColor.warn)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(refreshFailureCaption)
                }
            }
        }
    }

    /// Mac 列头：刷新、筛选、更多。iOS 导航栏把前两颗成组、更多单独一颗玻璃圆。
    @ViewBuilder
    private var dashboardColumnActions: some View {
        if !model.isEmpty {
            refreshButton
            filterButton
            moreMenu
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await model.refresh() }
        } label: {
            Label {
                Text(L("刷新"))
            } icon: {
                MeterRefreshGlyph(isRefreshing: model.isRefreshing)
            }
        }
        .meterRefreshing(model.isRefreshing)
        .accessibilityLabel(L("刷新账单"))
    }

    private var filterButton: some View {
        Button(L("筛选"), systemImage: filterSymbol) {
            isFiltering = true
        }
        .accessibilityLabel(L("筛选"))
        .accessibilityValue(filterAccessibilityValue)
        // 挂在筛选钮上，popover 的箭头才指着它；挂在整页上会漂到列头左边。
        // 每次打开都新建一份草稿：上次没按「用这个」就丢掉的调整
        // 不该在下一次冒出来。
        .modifier(PadPopoverOrSheet(isPresented: $isFiltering) {
            DashboardFilterSheet(model: DashboardFilterModel(dashboard: model))
        })
    }

    /// 分享和编辑是偶发动作，收进系统 Menu：iOS 26 会从这颗玻璃钮长出列表。
    /// 刷新 / 筛选有状态（转圈、填实），不进这里。
    private var moreMenu: some View {
        Menu {
            Button(L("分享"), systemImage: "square.and.arrow.up") {
                isSharing = true
            }
            .accessibilityLabel(L("分享这个月的账单卡片"))
            Button(L("编辑仪表盘"), systemImage: "rectangle.3.group") {
                isEditingLayout = true
            }
        } label: {
            Label(L("更多"), systemImage: "ellipsis")
        }
        .accessibilityLabel(L("更多"))
    }

    /// 一个 `ToolbarItem` 只认一个 item：多颗按钮要用 Group，否则 iOS 只渲染第一颗。
    /// 更多单独一颗，和刷新 / 筛选拆开共享玻璃底——overflow 在最右。
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !model.isEmpty {
            ToolbarItemGroup(placement: .topBarTrailing) {
                refreshButton
                filterButton
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                moreMenu
            }
        }
    }

    /// 筛选生效时图标填实。工具栏图标是唯一在任何滚动位置都看得见的东西,
    /// 首屏那行限定语会随内容滚走,这颗不会。
    private var filterSymbol: String {
        model.filter.isActive
            ? "line.3.horizontal.decrease.circle.fill"
            : "line.3.horizontal.decrease"
    }

    private var filterAccessibilityValue: LocalizedStringResource {
        let asOf = model.filter.anchor(now: model.clock.now, calendar: model.clock.calendar)
        guard let note = DashboardFilterSummary.full(
            filter: model.filter,
            window: model.filterWindow,
            asOf: asOf,
            calendar: model.clock.calendar,
            connections: model.connectionStates()
        ) else {
            return L("未筛选")
        }
        return L("筛选中：\(note)")
    }

    private var dashboardUsageScreen: UsageAnalyticsScreen {
        switch path.last {
        case .composition: .dashboardComposition
        case .comparison: .dashboardComparison
        // 仅订阅的家没有账号，但落点是同一张详情页。
        case .account, .provider: .dashboardAccount
        // 订阅、日历、类别这三页还没有各自的上报名单条目，都记在仪表盘名下。
        case .subscriptions, .heatmap, .categories, nil: .dashboard
        }
    }
}

#Preview("Light") {
    @Previewable @State var model = DashboardModel.preview
    DashboardView(model: model)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var model = DashboardModel.preview
    DashboardView(model: model)
        .preferredColorScheme(.dark)
}

#Preview("Empty") {
    @Previewable @State var model = DashboardModel.previewEmpty
    DashboardView(model: model)
}

#Preview("XXL") {
    @Previewable @State var model = DashboardModel.preview
    DashboardView(model: model)
        .dynamicTypeSize(.accessibility3)
}

#Preview("Pad") {
    @Previewable @State var model = DashboardModel.preview
    DashboardView(model: model)
        .environment(\.meterShell, .pad)
}
