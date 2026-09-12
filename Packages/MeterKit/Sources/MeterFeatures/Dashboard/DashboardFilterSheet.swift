import SwiftUI
import MeterCore
import MeterDesign

/// 筛选抽屉。两维各占一节：时间、服务。
/// 订阅口径不在这里——它是首屏大数字旁边那颗分段控件（`SubscriptionScopeControl`）。
///
/// 顶上钉着**草稿生效后的数字**——「翻回七月」「排掉 AWS」都很抽象，
/// 只有看到数字才有感觉。它也顺便让「按下去会怎样」变成一件不需要试的事。
///
/// ## 时间那一节为什么是两行 chip 加一层折叠
///
/// 三种问法在这里是三种东西，不该混在一排里：
/// - **哪个月**——本月、八月、七月……（第一行）
/// - **多长一段**——近 3 个月、今年至今、全期间（第二行）
/// - **哪一段**——五月到七月（折叠起来的自定义）
///
/// 前两行语义不重叠，所以选中态永远只落在其中一行，不会出现「本月」和
/// 「近 1 个月」两颗同时亮。第三种是少数人偶尔要的，收进折叠层——把它摊平成
/// 第三行 chip 会挤掉前两行一眼可数的好处，而那正是这一节最有用的地方：
/// 你能看见自己到底攒了几个月数据。
struct DashboardFilterSheet: View {
    @State private var model: DashboardFilterModel
    @State private var isCustomExpanded = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.usesPadChrome) private var usesPadChrome

    init(model: DashboardFilterModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationStack {
            MeterGroupedList {
                previewSection
                periodSection
                providerSection
            }
            .meterSheetTitle(Text(L("筛选")))
            .meterSheetClose {
                model.discard()
                dismiss()
            }
            .meterPrimaryActionBar {
                Button {
                    model.apply()
                    dismiss()
                } label: {
                    Text(L("用这个"))
                        .frame(maxWidth: .infinity)
                }
                .meterPrimaryActionStyle()
                .disabled(!model.hasUnappliedChanges)
            }
        }
        .meterPhoneDrawerChrome(.large, usesPadChrome: usesPadChrome)
        // 已经选着自定义区间就先展开：折叠着会让当前生效的选择在面板上无处可见。
        .onAppear { isCustomExpanded = model.isCustomRange }
    }

    /// 草稿生效后的数字。不是「当前」的数字——这里显示当前值会让人以为没生效。
    private var previewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(model.previewAmountText)
                    .meterAmountStyle()
                    .foregroundStyle(Color.meterLabel)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: model.previewAmountText)
                Text(model.previewNote)
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L("筛选后 \(model.previewAmountText)，\(model.previewNote)"))
        } footer: {
            if model.isEverythingExcluded {
                Text(L("一个账号都没留，总数会是 $0。"))
                    .foregroundStyle(MeterColor.warn)
            }
        }
    }

    private var periodSection: some View {
        Section {
            monthRow
            if !model.spanOptions.isEmpty {
                spanRow
            }
            customRow
        } header: {
            Text(L("时间"))
        } footer: {
            Text(L("一律按整月算。多个月就是把每个月各算一遍再加起来——订阅也跟着乘对月数。"))
        }
    }

    /// 单月。只列真的有数的月份，横向排，一眼能看到有几个月可翻。
    private var monthRow: some View {
        MeterSelectionChipRow {
            ForEach(model.monthOptions) { option in
                MeterSelectionChip(
                    title: option.title,
                    isSelected: model.isSelected(.months(back: option.monthsBack, count: 1))
                ) {
                    model.select(.months(back: option.monthsBack, count: 1))
                }
            }
        }
    }

    /// 跨月。近 N 个月 / 今年至今 / 全期间。
    private var spanRow: some View {
        MeterSelectionChipRow {
            ForEach(model.spanOptions) { option in
                MeterSelectionChip(title: option.title, isSelected: model.isSelected(option.period)) {
                    model.select(option.period)
                }
            }
        }
    }

    /// 自定义区间。**起讫都是月**，不是日。
    ///
    /// 按日在这个数据模型里算不出诚实的数（见 `DashboardPeriod`），所以这里
    /// 干脆不给日期选择器——给了再在脚注里解释「这段数字是估的」，是把一个
    /// 本可以不存在的坑先挖好再立牌子。
    @ViewBuilder
    private var customRow: some View {
        DisclosureGroup(isExpanded: $isCustomExpanded) {
            monthPickerRow(
                title: L("起"),
                selection: Binding(
                    get: { model.customStartMonth },
                    set: { model.customStartMonth = $0 }
                )
            )
            monthPickerRow(
                title: L("止"),
                selection: Binding(
                    get: { model.customEndMonth },
                    set: { model.customEndMonth = $0 }
                )
            )
        } label: {
            HStack {
                Text(L("自定义区间"))
                    .foregroundStyle(Color.meterLabel)
                Spacer(minLength: MeterSpacing.sm)
                if model.isCustomRange {
                    Text(L("共 \(model.customMonthCount) 个月"))
                        .font(MeterFont.subheadline)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private func monthPickerRow(
        title: LocalizedStringResource,
        selection: Binding<Date>
    ) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: MeterSpacing.sm)
            YearMonthPicker(
                selection: selection,
                calendar: model.calendar,
                now: model.now,
                lowerBound: model.customLowerBound,
                upperBound: model.customUpperBound
            )
        }
    }

    @ViewBuilder
    private var providerSection: some View {
        Section {
            if model.availableAccounts.isEmpty {
                Text(L("还没有接入任何服务。"))
                    .foregroundStyle(Color.meterSecondaryLabel)
            }
            ForEach(model.flatAccounts) { option in
                accountRow(option)
            }
        } header: {
            HStack {
                Text(L("服务"))
                Spacer()
                if model.isDraftActive, !model.availableAccounts.isEmpty {
                    Button(L("全选")) {
                        model.includeAllProviders()
                    }
                    .font(MeterFont.footnote)
                    .textCase(nil)
                }
            }
        } footer: {
            Text(L("新接入的账号默认算在里面，不会悄悄看不见。"))
        }

        ForEach(model.siblingVendorGroups) { group in
            Section(group.displayName) {
                ForEach(group.accounts) { option in
                    accountRow(option)
                }
            }
        }
    }

    private func accountRow(_ option: DashboardFilterModel.AccountOption) -> some View {
        let isIncluded = model.isIncluded(option.id)
        return Button {
            model.setIncluded(!isIncluded, for: option.id)
        } label: {
            HStack(spacing: MeterSpacing.sm) {
                ProviderGlyph(colorKey: option.colorKey)
                    .opacity(isIncluded ? 1 : 0.35)
                Text(option.displayName)
                    .foregroundStyle(isIncluded ? Color.meterLabel : Color.meterSecondaryLabel)
                Spacer()
                Image(systemName: isIncluded ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isIncluded ? Color.accentColor : Color.meterTertiaryLabel)
            }
            .meterListRowHitTarget()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.displayName)
        .accessibilityValue(isIncluded ? L("算在内") : L("已排除"))
        .accessibilityAddTraits(.isButton)
        .contextMenu {
            Button(L("只看 \(option.displayName)")) {
                model.onlyAccount(option.id)
            }
        }
    }
}

#Preview("Light") {
    DashboardFilterSheet(model: DashboardFilterModel(dashboard: .preview))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    DashboardFilterSheet(model: DashboardFilterModel(dashboard: .preview))
        .preferredColorScheme(.dark)
}

#Preview("XXL") {
    DashboardFilterSheet(model: DashboardFilterModel(dashboard: .preview))
        .dynamicTypeSize(.accessibility3)
}

#Preview("Pad") {
    DashboardFilterSheet(model: DashboardFilterModel(dashboard: .preview))
        .environment(\.meterShell, .pad)
}
