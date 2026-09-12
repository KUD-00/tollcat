import SwiftUI
import MeterCore
import MeterDesign
import MeterProviders
import MeterUsage

struct ServicesView: View {
    @Bindable var model: ServicesModel
    @State private var path: [ServicesRoute] = []
    /// Mac 分栏 detail 列的手工推入栈，见 `MacColumnStackModel`。
    @State private var macDetailStack = MacColumnStackModel()
    @State private var editingSubscription: ManualSubscriptionItem?
    @State private var subscriptionPendingDeletion: ManualSubscriptionItem?
    @Environment(\.usesPadChrome) private var usesPadChrome
    @Environment(\.meterShell) private var shell
    @Environment(\.padColumn) private var padColumn
    @Environment(\.selectedAppTab) private var selectedAppTab

    var body: some View {
        Group {
            switch padColumn {
            case .list:
                servicesListColumn
            case .detail:
                servicesDetailColumn
            case nil:
                if usesPadChrome {
                    padSplit
                } else {
                    phoneStack
                }
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: model.refreshSuccessToken)
        .confirmationDialog(
            L("删除这笔订阅？"),
            isPresented: isConfirmingSubscriptionDelete,
            titleVisibility: .visible
        ) {
            Button(L("删除"), role: .destructive) {
                if let item = subscriptionPendingDeletion {
                    model.deleteSubscription(item)
                }
                subscriptionPendingDeletion = nil
            }
            Button(L("取消"), role: .cancel) {
                subscriptionPendingDeletion = nil
            }
        } message: {
            Text(L("过去每个月的合计都会少掉这笔钱。只是不订了的话，在这笔订阅里填一个结束月。"))
        }
        .sheet(item: $editingSubscription) { item in
            NavigationStack {
                SubscriptionEditorForm(
                    model: SubscriptionEditorModel(
                        dashboard: model.dashboard,
                        editing: item
                    ),
                    showsClose: true
                )
            }
            .meterDrawerChrome(.large, usesPadChrome: usesPadChrome)
        }
        .task {
            guard padColumn != .detail else { return }
            await model.loadCatalog()
            applyLaunchHooks()
            if model.dashboard.shouldPresentAddProvider {
                presentAdd()
                model.dashboard.shouldPresentAddProvider = false
            }
        }
        .onAppear { model.reload() }
        .onChange(of: model.dashboard.persistenceToken) { _, _ in
            model.reload()
        }
        .onChange(of: model.dashboard.catalogRevision) { _, _ in
            Task { await model.loadCatalog() }
        }
        .onChange(of: model.dashboard.refreshSuccessToken) { _, _ in
            model.reload()
        }
        .onChange(of: editingSubscription) { _, item in
            if item == nil {
                model.reload()
            }
        }
        .onChange(of: model.dashboard.shouldPresentAddProvider) { _, pending in
            if pending {
                presentAdd()
                model.dashboard.shouldPresentAddProvider = false
            }
        }
        .onChange(of: model.selectedProviderID) { old, new in
            guard usesPadChrome, let new, old != new else { return }
            model.setupPath.removeAll()
            macDetailStack.popToRoot()
        }
        .onChange(of: model.setupPath) { _, path in
            if path.isEmpty {
                model.reload()
            }
        }
        .onChange(of: macDetailStack.canPop) { _, canPop in
            if !canPop {
                model.reload()
            }
        }
        .onChange(of: path) { _, path in
            if path.isEmpty {
                model.reload()
            }
        }
        .recordsUsageScreen(servicesUsageScreen, isActive: servicesUsageIsActive)
    }

    private var phoneStack: some View {
        NavigationStack(path: $path) {
            columnRoot
                .navigationDestination(for: ServicesRoute.self, destination: servicesDestination)
        }
    }

    private var padSplit: some View {
        PadSecondaryPair(
            list: servicesListColumn,
            detail: servicesDetailColumn
        )
    }

    private var servicesListColumn: some View {
        NavigationStack { columnRoot }
            .meterSplitColumnChrome()
            .meterMacColumnBar(title: Text(L("服务")), actions: { servicesColumnActions })
    }

    private var servicesDetailColumn: some View {
        padDetail
            .meterSplitColumnChrome()
            .meterMacColumnBar(
                title: macDetailStack.topTitle ?? servicesDetailTitle,
                showBack: macDetailStack.canPop || !model.setupPath.isEmpty,
                onBack: {
                    if macDetailStack.canPop {
                        macDetailStack.pop()
                    } else if !model.setupPath.isEmpty {
                        model.setupPath.removeLast()
                    }
                }
            )
    }

    @ViewBuilder
    private var padDetail: some View {
        NavigationStack(path: $model.setupPath) {
            macWrappedDetail
                .navigationDestination(for: ServicesRoute.self, destination: servicesDestination)
        }
    }

    /// Mac 上详情列套手工栈：账单明细 / 管理凭据 / 读数明细在列内推。
    @ViewBuilder
    private var macWrappedDetail: some View {
        if shell == .mac {
            MacColumnStack(model: macDetailStack) { padDetailRoot }
        } else {
            padDetailRoot
        }
    }

    @ViewBuilder
    private var padDetailRoot: some View {
            Group {
                if let selected = model.selectedProviderID {
                    ProviderDetailView(
                        model: ProviderDetailModel(providerID: selected, dashboard: model.dashboard)
                    )
                    // 换一家才换页。同一家刷新不能拆掉详情，否则连接参考跟着关。
                    .id(selected)
                } else {
                    ContentUnavailableView {
                        Label(L("选择一项服务"), systemImage: "square.stack.3d.up")
                    } description: {
                        Text(L("从左边选一家，查看账单和接入。"))
                    }
                }
            }
    }

    @ViewBuilder
    private func servicesDestination(_ route: ServicesRoute) -> some View {
        switch route {
        case .add:
            AddProviderView(model: model, onAdd: finishAdd)
        case .addMore:
            AddProviderView(model: model, browse: .more, onAdd: finishAdd)
        case .subscription:
            SubscriptionEditorForm(
                model: SubscriptionEditorModel(
                    dashboard: model.dashboard
                ),
                showsClose: false
            )
        case .detail(let id):
            ProviderDetailView(
                model: ProviderDetailModel(providerID: id, dashboard: model.dashboard)
            )
            .id(id)
        case .past:
            pastServicesPage
        }
    }

    private func finishAdd(_ id: ProviderID) {
        try? model.dashboard.addMembership(id)
        model.selectedProviderID = id
        if usesPadChrome {
            model.setupPath.removeAll()
            macDetailStack.popToRoot()
        } else if path.last == .add || path.last == .addMore {
            // 从添加页推进，不要整栈换成详情：同一深度替换没有从右进来的动画。
            path.append(.detail(id))
        } else {
            path = [.detail(id)]
        }
        model.reload()
    }

    private var columnRoot: some View {
        content
            .navigationTitle(L("服务"))
            .navigationBarTitleDisplayMode(.large)
            .meterNavigationToolbar { toolbarContent }
            .meterRefreshable { await model.refreshAll() }
    }

    /// 一家都没接、也没有手动订阅和目录提示时，空态**替换整个列表**。
    ///
    /// 只有全空才替换：手里已经有一笔手动订阅的话，列表是有内容的，
    /// 整页接管就会把那笔订阅藏起来。那种半空的情况走列表里的「添加服务」那一行。
    @ViewBuilder
    private var content: some View {
        if model.isFullyEmpty {
            ServicesEmptyView(onAdd: presentAdd)
        } else {
            list
        }
    }

    @ViewBuilder
    private var list: some View {
        MeterGroupedList {
            listSections
        }
    }

    @ViewBuilder
    private var listSections: some View {
        if !model.catalogNotices.isEmpty {
            Section {
                ForEach(model.catalogNotices, id: \.id) { notice in
                    SetupNoticeBanner(message: notice.message)
                }
            } header: {
                leadingSectionHeader
            }
        }

        connectedSections

        if !model.activeManualSubscriptions.isEmpty {
            Section {
                ForEach(model.activeManualSubscriptions) { item in
                    manualSubscriptionRow(item)
                        .swipeActions { deleteSwipeAction(item) }
                }
            } header: {
                Text(L("手动订阅"))
            }
        }
    }

    private var isConfirmingSubscriptionDelete: Binding<Bool> {
        Binding(
            get: { subscriptionPendingDeletion != nil },
            set: { if !$0 { subscriptionPendingDeletion = nil } }
        )
    }

    /// 划出来的删除。**不能写 `role: .destructive`**——SwiftUI 会先播一次删行
    /// 动画，而真删还卡在确认弹窗后面，行会先消失一下再弹回来。要红色自己上 tint。
    private func deleteSwipeAction(_ item: ManualSubscriptionItem) -> some View {
        Button(L("删除")) {
            subscriptionPendingDeletion = item
        }
        .tint(MeterColor.crit)
    }

    private func manualSubscriptionRow(_ item: ManualSubscriptionItem) -> some View {
        Button {
            editingSubscription = item
        } label: {
            HStack(spacing: MeterSpacing.sm) {
                ManualSubscriptionRow(item: item)
                Image(systemName: "chevron.right")
                    .font(MeterFont.footnote.weight(.semibold))
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .accessibilityHidden(true)
            }
            .meterListRowHitTarget()
        }
        .buttonStyle(.plain)
        .accessibilityHint(L("编辑这笔订阅"))
    }

    @ViewBuilder
    private var connectedSections: some View {
        let sections = model.arrangedSections
        if sections.isEmpty {
            Section {
                // 一家都没接但列表里还有别的东西（手动订阅 / 目录提示）时，
                // 只留这一行。整屏空态在 `content` 那边，不能塞进 List 的行里——
                // 行的容器撑不开，`ContentUnavailableView` 会挤在顶上还留一块死白。
                addServiceRow
                pastServicesRow
            } header: {
                if model.catalogNotices.isEmpty {
                    leadingSectionHeader
                }
            } footer: {
                Text(L("还没有接入服务。凭据只存在这台设备上，不上传。"))
            }
        } else {
            ForEach(sections) { section in
                Section {
                    ForEach(section.rows) { row in
                        rowLink(row)
                    }
                    if !model.usesSectionTitles, section.id == sections.last?.id {
                        addServiceRow
                        pastServicesRow
                    }
                } header: {
                    connectedSectionHeader(section, isFirst: section.id == sections.first?.id)
                }
            }
            if model.usesSectionTitles {
                // 有分组小标题时，「添加服务」不能跟最后一组待在同一张卡里，
                // 否则它看起来像属于「免费额度内」。
                Section {
                    addServiceRow
                    pastServicesRow
                }
            }
        }
    }

    @ViewBuilder
    private func connectedSectionHeader(
        _ section: ServiceListSection,
        isFirst: Bool
    ) -> some View {
        if let title = section.title {
            Text(title)
        } else if isFirst, model.catalogNotices.isEmpty {
            leadingSectionHeader
        }
    }

    /// 设置页第一组有「通用」，系统走「大标题 → 分组标题」那套 inset。
    /// 服务页去掉「已接入」之后第一组没了 header，会改走无标题 inset，卡顶到大标题底下。
    /// 留空 header 槽位，间距和设置页同一套，不再写一句废话小标题。
    ///
    /// 只做给 iOS 的大标题规则。Mac 列头是自己画的 bar，没有那套 inset——
    /// 占位 header 反而把列表整体顶下去，和右列详情的起点错开。
    @ViewBuilder
    private var leadingSectionHeader: some View {
        if shell != .mac {
            Color.clear
                .frame(height: 0)
                .accessibilityHidden(true)
        }
    }

    private var addServiceRow: some View {
        Button(action: presentAdd) {
            Label(L("添加服务"), systemImage: "plus.circle.fill")
        }
        .foregroundStyle(.tint)
        .accessibilityLabel(L("添加服务"))
        .accessibilityIdentifier(UITestID.servicesAdd)
    }

    /// 停掉的那些不占主列表——主列表回答「我现在每个月付多少」。
    /// 给一个入口，想查再进去。没有历史就不出这一行。
    @ViewBuilder
    private var pastServicesRow: some View {
        if model.hasPastRecords {
            Button(action: presentPast) {
                HStack {
                    Label(L("历史服务"), systemImage: "clock.arrow.circlepath")
                    Spacer(minLength: MeterSpacing.sm)
                    Image(systemName: "chevron.right")
                        .font(MeterFont.footnote.weight(.semibold))
                        .foregroundStyle(Color.meterTertiaryLabel)
                        .accessibilityHidden(true)
                }
                .meterListRowHitTarget()
            }
            .buttonStyle(.plain)
            .accessibilityHint(L("查看已经不再计入的服务和订阅"))
        }
    }

    private func presentPast() {
        if shell == .mac {
            model.setupPath.removeAll()
            macDetailStack.popToRoot()
            pushMacPast()
        } else if usesPadChrome {
            model.setupPath = [.past]
        } else {
            path = [.past]
        }
    }

    private var pastServicesPage: some View {
        PastServicesView(
            rows: model.endedRows,
            subscriptions: model.endedManualSubscriptions,
            onOpenProvider: openPastProvider,
            onEditSubscription: { editingSubscription = $0 }
        )
    }

    /// 从历史那一页点进某一家。三种壳各有各的推进方式，和 `finishAdd` 同一套分支。
    private func openPastProvider(_ id: ProviderID) {
        if shell == .mac {
            macDetailStack.push(
                title: Text(providerTitle(id)),
                tag: AnyHashable(ServicesRoute.detail(id)),
                destination: ProviderDetailView(
                    model: ProviderDetailModel(providerID: id, dashboard: model.dashboard)
                )
            )
        } else if usesPadChrome {
            model.selectedProviderID = id
            model.setupPath.removeAll()
        } else {
            path.append(.detail(id))
        }
    }

    private func providerTitle(_ id: ProviderID) -> String {
        model.rows.first { $0.id == id }?.displayName ?? id.rawValue
    }

    private func presentAdd() {
        if shell == .mac {
            // 系统栈在 split 的 detail 里一 push 就接管整个主区（列表列卸载、返回钮和
            // 搜索框跑进窗口顶栏）。添加页推详情列的手工栈，左边列表留着，从右平移进来。
            model.setupPath.removeAll()
            macDetailStack.popToRoot()
            pushMacAdd()
        } else if usesPadChrome {
            model.setupPath = [.add]
        } else {
            path = [.add]
        }
    }

    // Mac 列内手工栈的三个推入口。两个平台都编译：壳是运行时的值，不是 `#if os`。
    private func pushMacAdd() {
        macDetailStack.push(
            title: Text(L("添加服务")),
            tag: AnyHashable(ServicesRoute.add),
            destination: AddProviderView(model: model, onAdd: finishAdd)
        )
    }

    private func pushMacPast() {
        macDetailStack.push(
            title: Text(L("历史服务")),
            tag: AnyHashable(ServicesRoute.past),
            destination: pastServicesPage
        )
    }

    private func pushMacManualSubscription() {
        macDetailStack.push(
            title: Text(L("手动订阅")),
            tag: AnyHashable(ServicesRoute.subscription),
            destination: SubscriptionEditorForm(
                model: SubscriptionEditorModel(dashboard: model.dashboard),
                showsClose: false
            )
        )
    }

    @ViewBuilder
    private func rowLink(_ row: ServiceRowItem) -> some View {
        if usesPadChrome {
            PadSplitRowButton(
                isSelected: model.selectedProviderID == row.id,
                hint: L("查看这家的账单和接入"),
                action: { model.selectedProviderID = row.id }
            ) {
                rowContent(row)
            }
            .accessibilityIdentifier(UITestID.servicesRow(row.id.rawValue))
        } else {
            NavigationLink(value: ServicesRoute.detail(row.id)) {
                rowContent(row)
            }
            .accessibilityHint(L("查看这家的账单和接入"))
            .accessibilityIdentifier(UITestID.servicesRow(row.id.rawValue))
        }
    }

    private func rowContent(_ row: ServiceRowItem) -> some View {
        ProviderRow(
            name: row.displayName,
            colorKey: row.colorKey,
            value: row.value,
            subtitle: row.subtitle,
            isConnected: row.isConnected,
            usesSecondaryValue: row.usesSecondaryValue,
            staleLabel: row.isStale ? String(localized: L("数据陈旧")) : nil,
            valueCaption: row.valueCaption,
            spokenValue: row.spokenValue,
            amountValue: row.amountValue,
            accessibilityName: row.spokenName
        )
    }

    /// nil = 没选服务（空态）。列头不能再兜「服务」——和列表列的标题重复。
    private var servicesDetailTitle: Text? {
        guard let id = model.selectedProviderID,
              let row = model.rows.first(where: { $0.providerID == id }) else {
            return nil
        }
        return Text(row.displayName)
    }

    @ViewBuilder
    private var servicesColumnActions: some View {
        Button {
            Task { await model.refreshAll() }
        } label: {
            Label {
                Text(L("刷新"))
            } icon: {
                MeterRefreshGlyph(isRefreshing: model.isRefreshing)
            }
        }
        .meterRefreshing(model.isRefreshing)
        .accessibilityLabel(L("刷新账单"))
        if !model.connectedRows.isEmpty {
            Menu {
                // macOS 26 的 Menu 里塞 inline Picker，整组菜单项会渲成禁用灰、
                // 点不动（guardrail 已把 inline 样式整目录禁掉）。改 Button + 勾选。
                sortOption(L("计费模式"), sort: .kind)
                sortOption(L("类别"), sort: .category)
                sortOption(L("价格"), sort: .price)
            } label: {
                Label(L("排序"), systemImage: "arrow.up.arrow.down")
            }
            .accessibilityLabel(L("排序"))
            .accessibilityValue(model.sort.title)
        }
    }

    private func sortOption(_ title: LocalizedStringResource, sort: ServiceListSort) -> some View {
        Button {
            model.sort = sort
        } label: {
            if model.sort == sort {
                // 勾选项明确要图标加字，不跟着外面的 label 样式走。
                Label(title, systemImage: "checkmark")
                    .labelStyle(.titleAndIcon)
            } else {
                Text(title)
            }
        }
    }

    /// 一个 `ToolbarItem` 只认一个 item，多颗按钮要用 Group（见 `DashboardView.toolbarContent`）。
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            servicesColumnActions
        }
    }

    private func applyLaunchHooks() {
        if FeatureLaunchArguments.openManualSubscription {
            if shell == .mac {
                pushMacAdd()
                pushMacManualSubscription()
            } else if usesPadChrome {
                model.setupPath = [.add, .subscription]
            } else {
                path = [.add, .subscription]
            }
            return
        }
        if FeatureLaunchArguments.openAddProvider {
            presentAdd()
            return
        }
        if let id = FeatureLaunchArguments.openSetup {
            finishAdd(id)
            return
        }
        if let id = model.dashboard.accountIDForOpenProviderDetail() {
            let providerID = model.dashboard.connectionStates()
                .first { $0.accountID == id }?.providerID
            if let providerID {
                if usesPadChrome {
                    model.selectedProviderID = providerID
                } else {
                    path = [.detail(providerID)]
                }
            }
        }
    }

    private var servicesUsageIsActive: Bool {
        selectedAppTab == .services && padColumn != .list
    }

    private var servicesUsageScreen: UsageAnalyticsScreen {
        if editingSubscription != nil { return .servicesSubscription }
        if usesPadChrome {
            if model.setupPath.contains(.subscription)
                || macDetailStack.contains(tag: ServicesRoute.subscription) {
                return .servicesSubscription
            }
            if model.setupPath.contains(.add)
                || model.setupPath.contains(.addMore)
                || macDetailStack.contains(tag: ServicesRoute.add)
                || macDetailStack.contains(tag: ServicesRoute.addMore) {
                return .servicesAdd
            }
            if model.selectedProviderID != nil { return .servicesDetail }
            return .services
        }
        switch path.last {
        case .add, .addMore: return .servicesAdd
        case .subscription: return .servicesSubscription
        case .detail: return .servicesDetail
        // 历史是服务页的一个子列表，不是单独一步漏斗，不另开一个屏幕名。
        case .past: return .services
        case nil: return .services
        }
    }
}

#Preview("Light") {
    @Previewable @State var model = ServicesModel.preview
    ServicesView(model: model)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var model = ServicesModel.preview
    ServicesView(model: model)
        .preferredColorScheme(.dark)
}

#Preview("Empty") {
    @Previewable @State var model = ServicesModel.previewEmpty
    ServicesView(model: model)
}

#Preview("Stale") {
    @Previewable @State var model = ServicesModel.previewStale
    ServicesView(model: model)
}

#Preview("XXL") {
    @Previewable @State var model = ServicesModel.preview
    ServicesView(model: model)
        .dynamicTypeSize(.accessibility3)
}

#Preview("Pad") {
    @Previewable @State var model = ServicesModel.preview
    ServicesView(model: model)
        .environment(\.meterShell, .pad)
}

#Preview("两个 Cloudflare") {
    @Previewable @State var model = ServicesModel.previewTwoCloudflare
    ServicesView(model: model)
}

#Preview("按类别") {
    @Previewable @State var model = {
        let model = ServicesModel.preview
        model.sort = .category
        return model
    }()
    ServicesView(model: model)
}

#Preview("按价格") {
    @Previewable @State var model = {
        let model = ServicesModel.preview
        model.sort = .price
        return model
    }()
    ServicesView(model: model)
}
