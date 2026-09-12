import SwiftUI
import MeterCore
import MeterDesign
import MeterProviders
import MeterModules

/// 「编辑仪表盘」：开关模块、拖动排序；「特别关心」钉哪几家、「预算线」多少钱也在这里。
/// 改了就生效，没有草稿——这一面动的是版式不是数据，看着仪表盘变比按「用这个」直接。
struct DashboardEditSheet: View {
    var model: DashboardModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.usesPadChrome) private var usesPadChrome
    @State private var budget: Decimal?

    private var enabled: [DashboardModuleID] {
        DashboardModuleID.resolvedOrder(from: model.layout).filter { !$0.isPinned }
    }

    private var disabled: [DashboardModuleID] {
        DashboardModuleID.editableOrder(from: model.layout).filter { !enabled.contains($0) }
    }

    var body: some View {
        NavigationStack {
            MeterReorderableList {
                enabledSection
                if !disabled.isEmpty {
                    moreSection
                }
                if enabled.contains(.services) {
                    pinnedServicesSection
                }
                if enabled.contains(.budget) {
                    budgetSection
                }
                if usesPadChrome {
                    sidebarSection
                }
            }
            .meterSheetTitle(Text(L("编辑仪表盘")))
            .meterSheetClose {
                dismiss()
            }
        }
        .meterPhoneDrawerChrome(.large, usesPadChrome: usesPadChrome)
        .onAppear {
            budget = model.layout.monthlyBudgetUSD
        }
        .onChange(of: budget) { _, newValue in
            model.setMonthlyBudget(newValue)
        }
    }

    // MARK: - 模块

    private var enabledSection: some View {
        Section {
            ForEach(enabled) { id in
                moduleRow(id) {
                    toggle(id)
                }
                // 定槽的那块（构成）画在英雄区，排哪儿都不动，所以不给拖、也不给上下移。
                .moveDisabled(id.isFixedSlot)
                .contextMenu {
                    if !id.isFixedSlot {
                        Button(L("上移"), systemImage: "arrow.up") { move(id, by: -1) }
                            .disabled(!canMove(id, by: -1))
                        Button(L("下移"), systemImage: "arrow.down") { move(id, by: 1) }
                            .disabled(!canMove(id, by: 1))
                    }
                }
            }
            .onMove { offsets, destination in
                var order = enabled
                order.move(fromOffsets: offsets, toOffset: destination)
                model.setModuleOrder(order)
            }
        } header: {
            Text(L("显示中"))
        } footer: {
            Text(L("拖动排序。本月合计和构成始终在最上面，没数据的模块会自动不显示。"))
        }
    }

    private var moreSection: some View {
        Section {
            ForEach(disabled) { id in
                moduleRow(id) {
                    toggle(id)
                }
                .moveDisabled(true)
            }
        } header: {
            Text(L("更多模块"))
        }
    }

    private func moduleRow(_ id: DashboardModuleID, @ViewBuilder trailing: () -> some View) -> some View {
        HStack(spacing: MeterSpacing.sm) {
            Image(systemName: id.systemImage)
                .font(MeterFont.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: MeterSpacing.providerGlyph, alignment: .center)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(id.title)
                    .font(MeterFont.body)
                    .foregroundStyle(Color.meterLabel)
                Text(id.summary)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing()
        }
        .frame(minHeight: MeterSpacing.minTap)
    }

    private func toggle(_ id: DashboardModuleID) -> some View {
        Toggle(isOn: Binding(
            get: { enabled.contains(id) },
            set: { model.setModule(id, enabled: $0) }
        )) {
            Text(id.title)
        }
        .labelsHidden()
        .accessibilityLabel(id.title)
    }

    /// 能不能往那个方向挪一格：越界不行，换到定槽的那块头上也不行
    /// （换了也白换——`resolvedOrder` 会把它拨回最前面）。
    private func canMove(_ id: DashboardModuleID, by delta: Int) -> Bool {
        guard !id.isFixedSlot, let index = enabled.firstIndex(of: id) else { return false }
        let target = index + delta
        guard enabled.indices.contains(target) else { return false }
        return !enabled[target].isFixedSlot
    }

    private func move(_ id: DashboardModuleID, by delta: Int) {
        guard canMove(id, by: delta) else { return }
        var order = enabled
        guard let index = order.firstIndex(of: id) else { return }
        order.swapAt(index, index + delta)
        model.setModuleOrder(order)
    }

    // MARK: - 侧栏底部

    private var sidebarCandidates: [DashboardModuleID] {
        enabled.filter(\.canSitInSidebar)
    }

    private var sidebarSection: some View {
        Section {
            Picker(selection: Binding(
                get: { model.layout.sidebarModule.flatMap(DashboardModuleID.init(rawValue:)) },
                set: { model.setSidebarModule($0) }
            )) {
                Text(L("不放")).tag(DashboardModuleID?.none)
                ForEach(sidebarCandidates) { id in
                    Text(id.title).tag(DashboardModuleID?.some(id))
                }
            } label: {
                Text(L("钉一块到侧栏底部"))
            }
            .moveDisabled(true)
        } header: {
            Text(L("侧栏"))
        } footer: {
            Text(L("钉过去的模块不再出现在主区。只有一格宽的能钉。"))
        }
    }

    // MARK: - 特别关心

    private struct PinnableAccount: Identifiable {
        var accountID: AccountID
        var title: String
        var colorKey: String
        var id: AccountID { accountID }
    }

    private var pinnableAccounts: [PinnableAccount] {
        let connections = model.connectionStates()
        return connections
            .filter(\.isLive)
            .sorted { $0.sortIndex < $1.sortIndex }
            .compactMap { state in
                guard let descriptor = ProviderCatalog.descriptor(id: state.providerID) else { return nil }
                return PinnableAccount(
                    accountID: state.accountID,
                    title: AccountTitle.context(
                        for: state.accountID,
                        connections: connections,
                        providerDisplayName: descriptor.displayName
                    ).visual,
                    colorKey: descriptor.colorKey
                )
            }
    }

    private var pinnedServicesSection: some View {
        Section {
            ForEach(pinnableAccounts) { account in
                Toggle(isOn: Binding(
                    get: { model.layout.pinnedAccounts.contains(account.accountID) },
                    set: { pin(account.accountID, $0) }
                )) {
                    HStack(spacing: MeterSpacing.sm) {
                        ProviderGlyph(colorKey: account.colorKey, accessibilityName: account.title)
                            .frame(width: MeterSpacing.providerGlyph)
                            // 开关的标签已经念名字，图标再念一遍就成「Neon、Neon」。
                            .accessibilityHidden(true)
                        Text(account.title)
                            .font(MeterFont.body)
                            .foregroundStyle(Color.meterLabel)
                    }
                }
                .moveDisabled(true)
            }
        } header: {
            Text(L("特别关心钉哪几家"))
        } footer: {
            Text(L("按打开的先后排。一家都没钉时这块不显示。"))
        }
    }

    private func pin(_ accountID: AccountID, _ pinned: Bool) {
        var accounts = model.layout.pinnedAccounts
        if pinned, !accounts.contains(accountID) {
            accounts.append(accountID)
        } else if !pinned {
            accounts.removeAll { $0 == accountID }
        }
        model.setPinnedAccounts(accounts)
    }

    // MARK: - 预算线

    private var budgetSection: some View {
        Section {
            HStack {
                Text(L("月预算"))
                    .foregroundStyle(Color.meterLabel)
                Spacer(minLength: MeterSpacing.sm)
                TextField(
                    L("金额"),
                    value: $budget,
                    format: .currency(code: ExchangeRates.usdCode).precision(.fractionLength(0...2))
                )
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .modifier(DecimalKeyboard())
                .meterKeyboardDismiss {}
                .frame(maxWidth: MeterSpacing.budgetField)
            }
            .moveDisabled(true)
        } header: {
            Text(L("预算线"))
        } footer: {
            Text(L("按美元记，和账本同一个口径。清空就关掉预算线。"))
        }
    }
}

/// 金额输入用数字小键盘。Mac 没有这回事。
private struct DecimalKeyboard: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.keyboardType(.decimalPad)
        #else
        content
        #endif
    }
}

#Preview("Light") {
    DashboardEditSheet(model: .preview)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    DashboardEditSheet(model: .preview)
        .preferredColorScheme(.dark)
}
