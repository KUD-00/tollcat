import SwiftUI
import MeterCore
import MeterDesign
import MeterProviders
import MeterUsage
import MeterModules

/// 订阅编辑的唯一表单。两个入口共用：
/// - 详情页「固定订阅」→ `SubscriptionEditorSheet`（自带导航栈和可拉开抽屉）
/// - 服务页「手动订阅」→ 直接用 `SubscriptionEditorForm`（推入服务页的导航栈，
///   编辑时由 ServicesView 自己包 sheet + `.meterDrawerChrome(.large)`）
struct SubscriptionEditorForm: View {
    @Bindable var model: SubscriptionEditorModel
    /// 以 sheet 呈现才有系统关闭按钮；推入导航栈时靠返回。
    var showsClose: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.macColumnStack) private var macColumnStack
    @Environment(\.moneyPresentation) private var moneyPresentation
    @State private var isConfirmingDelete = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name
        case amount
    }

    var body: some View {
        Form {
            productSection
            quantitySection
            if let total = model.total {
                totalSection(total)
            }
            if model.showsAffiliationPicker {
                affiliationSection
            }
            if model.isEditing {
                endSection
                deleteSection
            }
        }
        .formStyle(.grouped)
        .meterGroupedRowButtons()
        .meterGroupedSectionCard()
        .contentMargins(.top, MeterSpacing.xs, for: .scrollContent)
        .meterSheetTitle(title)
        .recordsUsageScreen(.servicesSubscription)
        .meterSheetClose(isActive: showsClose) { dismiss() }
        .meterKeyboardDismiss {
            focusedField = nil
        }
        .meterPrimaryActionBar(ignoresKeyboard: true) {
            Button {
                // 不带动画写回。改了结束月之后这一行要从「固定订阅」跳到「历史订阅」，
                // 那是跨 section 的移动——SwiftUI 只能演成一段乱窜的位移，
                // 而这时抽屉正在关，用户看到的是一团糊。直接换位反而干净。
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    try? model.save()
                }
            } label: {
                Text(L("保存"))
                    .frame(maxWidth: .infinity)
            }
            .meterPrimaryActionStyle()
            .disabled(!model.canSave)
        }
        .task { await model.prepare() }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: model.saveToken)
        .onChange(of: model.saveToken) { _, token in
            if token > 0 { leave() }
        }
    }

    /// sheet 里就关抽屉；推在 Mac 列内栈里时 `dismiss` 没有可关的东西，弹回上一页。
    private func leave() {
        if !showsClose, let macColumnStack, macColumnStack.canPop {
            macColumnStack.pop()
        } else {
            dismiss()
        }
    }

    private var title: Text {
        if model.isEditing {
            Text(verbatim: model.navigationTitle)
        } else if model.providerID == nil {
            Text(L("手动订阅"))
        } else {
            Text(L("加一笔固定订阅"))
        }
    }

    private var periodBinding: Binding<SubscriptionPeriod> {
        Binding(
            get: { model.period },
            set: { period in
                withAnimation(DashboardMotion.expand) {
                    model.setPeriod(period)
                }
            }
        )
    }

    private var yearMonthBinding: Binding<Date> {
        Binding(
            get: { model.anchorDate },
            set: { model.setAnchorDate($0) }
        )
    }

    private var productSection: some View {
        Section {
            Picker(selection: periodBinding) {
                Text(L("月付")).tag(SubscriptionPeriod.monthly)
                Text(L("年付")).tag(SubscriptionPeriod.annual)
            } label: {
                Text(L("周期"))
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityLabel(L("周期"))

            if model.showsAnchorDate {
                // 开始时间选不到未来的月份：那种订阅在账本上是纯 0，只会让人以为记错了。
                // 当月内的未来日期留着——年付的首次扣款日常常就在这个月的后几天。
                if model.usesYearMonthAnchor {
                    HStack {
                        Text(model.anchorLabel)
                        Spacer(minLength: MeterSpacing.sm)
                        YearMonthPicker(
                            selection: yearMonthBinding,
                            calendar: model.clockCalendar,
                            now: model.dashboard.clock.now,
                            upperBound: model.anchorUpperBound
                        )
                    }
                } else if let upperBound = model.anchorUpperBound {
                    DatePicker(
                        model.anchorLabel,
                        selection: anchorBinding,
                        in: ...upperBound,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .environment(\.calendar, model.clockCalendar)
                    .environment(\.timeZone, model.clockCalendar.timeZone)
                } else {
                    DatePicker(
                        model.anchorLabel,
                        selection: anchorBinding,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .environment(\.calendar, model.clockCalendar)
                    .environment(\.timeZone, model.clockCalendar.timeZone)
                }
            }

            if model.showsTierPicker {
                ForEach(model.visiblePlans, id: \.name) { plan in
                    planRow(
                        title: "\(plan.name) · \(plan.amount.formatted(using: moneyPresentation))",
                        isSelected: {
                            if case .catalog(let name) = model.planChoice {
                                return name == plan.name
                            }
                            return false
                        }()
                    ) {
                        model.selectPlan(plan.name)
                    }
                }
                planRow(title: String(localized: L("自定义")), isSelected: model.isCustom) {
                    model.selectPlan(nil)
                }
            }

            if model.showsIdentityFields {
                identityFields
            }
        }
    }

    private func planRow(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(DashboardMotion.expand, action)
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(Color.meterLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var identityFields: some View {
        TextField(L("名称"), text: $model.name)
            .focused($focusedField, equals: .name)
        HStack {
            Text(L("单价"))
            Spacer()
            TextField("0.00", text: $model.amountText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .focused($focusedField, equals: .amount)
                .accessibilityLabel(L("单价"))
        }
    }

    private var quantitySection: some View {
        Section {
            Stepper(value: $model.quantity, in: 1...200) {
                LabeledContent(L("份数")) {
                    Text("×\(model.quantity)").monospacedDigit()
                }
            }
        }
    }

    private func totalSection(_ total: Money) -> some View {
        Section {
            LabeledContent(L("每期合计")) {
                Text(total.formatted(using: moneyPresentation))
                    .font(MeterFont.bodyEmphasized)
                    .monospacedDigit()
            }
        } footer: {
            if model.quantity > 1, let unit = model.unitAmount {
                Text(L("\(unit.formatted(using: moneyPresentation)) × \(model.quantity)"))
            }
        }
    }

    private var affiliationSection: some View {
        Section {
            Picker(L("归属"), selection: $model.affiliation) {
                Text(L("不归属")).tag(SubscriptionAffiliation.none)
                ForEach(model.dashboard.memberships(), id: \.providerID) { membership in
                    Text(
                        ProviderCatalog.descriptor(id: membership.providerID)?.displayName
                            ?? membership.providerID.rawValue
                    )
                    .tag(SubscriptionAffiliation.vendor(membership.providerID))
                }
                ForEach(model.connectedAffiliationOptions, id: \.accountID) { state in
                    let vendor = ProviderCatalog.descriptor(id: state.providerID)?.displayName
                        ?? state.providerID.rawValue
                    Text(
                        AccountTitle.context(
                            for: state.accountID,
                            connections: model.connectedAffiliationOptions,
                            providerDisplayName: vendor
                        ).visual
                    )
                    .tag(SubscriptionAffiliation.account(state.accountID))
                }
            }
        }
    }

    /// 结束时间是一个**字段**，不是一个动作。
    ///
    /// 订阅是一段区间「开始 → 结束」。1–3 月用了 Pro、5 月又订回来，那是**两段**，
    /// 要在列表里新加一笔——所以这里没有「恢复」：恢复只会把没付钱的 4 月一起补上。
    /// 这里能做的只是填一个结束月、或者把填错的那个清掉。
    ///
    /// 结束月可以填在未来：这个月取消、服务用到 11 月底，那几个月照常计入。
    private var endSection: some View {
        Section {
            Toggle(isOn: hasEndBinding) {
                Text(L("已经退订"))
            }
            if model.hasEnd {
                HStack {
                    Text(L("结束时间"))
                    Spacer(minLength: MeterSpacing.sm)
                    YearMonthPicker(
                        selection: endBinding,
                        calendar: model.clockCalendar,
                        now: model.dashboard.clock.now,
                        lowerBound: model.endLowerBound,
                        upperBound: model.endUpperBound
                    )
                }
            }
        } footer: {
            Text(model.endFooter)
        }
    }

    private var hasEndBinding: Binding<Bool> {
        Binding(
            get: { model.hasEnd },
            set: { model.setHasEnd($0) }
        )
    }

    private var endBinding: Binding<Date> {
        Binding(
            get: { model.endDate ?? model.endLowerBound },
            set: { model.setEndDate($0) }
        )
    }

    private var anchorBinding: Binding<Date> {
        Binding(
            get: { model.anchorDate },
            set: { model.setAnchorDate($0) }
        )
    }

    private var deleteSection: some View {
        Section {
            Button(L("删除这笔订阅"), role: .destructive) {
                isConfirmingDelete = true
            }
            .confirmationDialog(
                L("删除这笔订阅？"),
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button(L("删除这笔订阅"), role: .destructive) {
                    try? model.delete()
                }
                Button(L("取消"), role: .cancel) {}
            } message: {
                Text(L("过去每个月的合计都会少掉这笔钱。只是不订了的话，填一个结束月。"))
            }
        } footer: {
            Text(L("删除是「我根本录错了」。不订了填结束月，历史留着。"))
        }
    }
}

/// 详情页入口：自带导航栈，量内容高度、走可拉开抽屉。
struct SubscriptionEditorSheet: View {
    @State private var model: SubscriptionEditorModel
    @Environment(\.usesPadChrome) private var usesPadChrome
    /// 首帧几何还没到。从更矮的档起，Form 量不到商品列表的真高度，抽屉会卡在半截。
    @State private var contentHeight: CGFloat =
        MeterSpacing.catDashboard * 4
        + MeterSpacing.primaryActionBarHeight
    @State private var chromeHeight: CGFloat = MeterSpacing.xxl

    init(model: SubscriptionEditorModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationStack {
            SubscriptionEditorForm(model: model, showsClose: true)
                .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentSize.height }) { _, height in
                    guard height.isFinite else { return }
                    let snapped = height.rounded()
                    guard snapped > contentHeight + MeterSpacing.xs else { return }
                    contentHeight = snapped
                }
        }
        .meterContainerChromeHeight($chromeHeight)
        .meterDrawerChrome(
            .expandable(contentHeight + chromeHeight),
            usesPadChrome: usesPadChrome
        )
    }
}

#Preview("挂厂商 · Light") {
    SubscriptionEditorSheet(model: .preview())
        .preferredColorScheme(.light)
}

#Preview("挂厂商 · Dark · 自定义") {
    SubscriptionEditorSheet(model: {
        let model = SubscriptionEditorModel.preview()
        model.selectPlan(nil)
        model.name = "Cursor Pro"
        model.amountText = "20"
        model.quantity = 3
        model.setPeriod(.annual)
        return model
    }())
    .preferredColorScheme(.dark)
}

#Preview("挂厂商 · Edit") {
    SubscriptionEditorSheet(model: .previewEditing())
}

#Preview("手动订阅 · 新建") {
    NavigationStack {
        SubscriptionEditorForm(model: .manualPreview(), showsClose: false)
    }
}

#Preview("手动订阅 · Edit") {
    NavigationStack {
        SubscriptionEditorForm(model: .manualPreviewEditing(), showsClose: true)
    }
}

#Preview("XXL") {
    SubscriptionEditorSheet(model: .preview())
        .dynamicTypeSize(.accessibility3)
}
