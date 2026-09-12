import SwiftUI
import MeterDesign

struct ManualUsageEntrySheet: View {
    @State private var model: ManualUsageEntryModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var amountFocused: Bool
    @Environment(\.usesPadChrome) private var usesPadChrome
    /// 月份行加上之后，* 2 会把页脚和主按钮切掉。
    @State private var contentHeight: CGFloat =
        MeterSpacing.catDashboard * 3
        + MeterSpacing.primaryActionBarHeight
    @State private var chromeHeight: CGFloat = MeterSpacing.xxl

    init(model: ManualUsageEntryModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(L("月份"))
                        Spacer(minLength: MeterSpacing.sm)
                        YearMonthPicker(
                            selection: periodBinding,
                            calendar: model.calendar,
                            now: model.now,
                            lowerBound: model.earliestPeriod,
                            upperBound: model.latestPeriod
                        )
                    }
                    TextField("0.00", text: $model.amountText)
                        .keyboardType(.decimalPad)
                        .focused($amountFocused)
                    if let url = model.billingURL {
                        SafariLink(L("在官网查看账单"), destination: url)
                    }
                } header: {
                    Text(verbatim: model.amountHeader)
                } footer: {
                    Text(verbatim: model.footer)
                }
            }
            .formStyle(.grouped)
        .meterGroupedRowButtons()
        .meterGroupedSectionCard()
            .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentSize.height }) { _, height in
                guard height.isFinite else { return }
                let snapped = height.rounded()
                guard snapped > contentHeight + MeterSpacing.xs else { return }
                contentHeight = snapped
            }
            .meterSheetTitle(Text(model.navigationTitle))
            .meterSheetClose { dismiss() }
            .meterKeyboardDismiss {
                amountFocused = false
            }
            .meterPrimaryActionBar(ignoresKeyboard: true) {
                Button {
                    try? model.save()
                } label: {
                    Text(L("保存"))
                        .frame(maxWidth: .infinity)
                }
                .meterPrimaryActionStyle()
                .disabled(!model.canSave)
            }
            .sensoryFeedback(.success, trigger: model.saveToken)
            .onChange(of: model.saveToken) { _, token in
                if token > 0 { dismiss() }
            }
        }
        .meterContainerChromeHeight($chromeHeight)
        .meterDrawerChrome(
            .expandable(contentHeight + chromeHeight),
            usesPadChrome: usesPadChrome
        )
    }

    private var periodBinding: Binding<Date> {
        Binding(
            get: { model.periodDate },
            set: { model.setPeriod($0) }
        )
    }
}

#Preview("Light") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ManualUsageEntrySheet(
                model: ManualUsageEntryModel(
                    providerID: .fly,
                    accountID: nil,
                    dashboard: .preview
                )
            )
        }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ManualUsageEntrySheet(
                model: ManualUsageEntryModel(
                    providerID: .fly,
                    accountID: nil,
                    dashboard: .preview
                )
            )
        }
        .preferredColorScheme(.dark)
}
