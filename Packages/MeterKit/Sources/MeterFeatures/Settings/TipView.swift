import SwiftUI
import MeterDesign
import MeterTips

struct TipView: View {
    @Bindable var model: TipModel
    @FocusState private var focusedField: Field?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private enum Field: Hashable {
        case name
        case message
    }

    var body: some View {
        MeterGroupedList {
            catSection
            if model.composerVisible {
                composerSection
            } else {
                productsSection
                historySection
            }
        }
        .navigationTitle(L("请猫猫吃点东西"))
        .navigationBarTitleDisplayMode(.large)
        .meterKeyboardDismiss {
            focusedField = nil
        }
        .meterPrimaryActionBar(
            isVisible: model.composerVisible,
            ignoresKeyboard: true
        ) {
            Button {
                Task { await model.submitComposer() }
            } label: {
                Text(L("写好了"))
                    .frame(maxWidth: .infinity)
            }
            .meterPrimaryActionStyle()
        }
        .animation(reduceMotion ? nil : .snappy, value: model.composerVisible)
        .task {
            await model.load()
        }
        .task {
            await model.observeTransactions()
        }
        .onDisappear {
            Task { await model.abandonComposerIfNeeded() }
        }
    }

    private var catSection: some View {
        Section {
            VStack(spacing: MeterSpacing.sm) {
                CatView(
                    parts: catParts,
                    size: catSize,
                    accessibilityLabel: catLabel,
                    isAnimated: true,
                    motion: .idle
                )
                .frame(maxWidth: .infinity)

                if model.composerVisible {
                    thanks(model.thanks)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    /// 标题那行是这一页此刻的主角，给到 title2；下面一句按档位说猫拿到了什么。
    private func thanks(_ copy: TipThanks) -> some View {
        VStack(spacing: MeterSpacing.xxs) {
            Text(copy.headline)
                .font(MeterFont.title2)
                .foregroundStyle(Color.meterLabel)
            Text(copy.note)
                .font(MeterFont.subheadline)
                .foregroundStyle(Color.meterSecondaryLabel)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    private var catParts: CatParts {
        (model.composerVisible ? CatMood.saved : CatMood.normal).parts
    }

    private var catSize: CGFloat {
        model.composerVisible ? MeterSpacing.catTipCelebrating : MeterSpacing.catTip
    }

    private var catLabel: LocalizedStringResource {
        model.composerVisible
            ? L("猫猫收到了吃的，很高兴")
            : L("猫猫在等吃的")
    }

    @ViewBuilder
    private var productsSection: some View {
        Section {
            switch model.catalogState {
            case .loading:
                EmptyView()
            case .unavailable:
                ContentUnavailableView {
                    Label(L("暂时无法连接 App Store"), systemImage: "storefront")
                } description: {
                    Text(L("过一会儿再打开这页。价格由 App Store 按地区显示。"))
                } actions: {
                    Button(L("再试一次")) {
                        Task { await model.load() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .ready:
                offeringsGrid
            }
        } footer: {
            VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                Text(productsFooter)
                    .fixedSize(horizontal: false, vertical: true)
                if let notice = model.purchaseNotice {
                    Text(notice.copy)
                        .foregroundStyle(notice.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private var offeringsGrid: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: MeterSpacing.md) {
                ForEach(model.offerings) { offering in
                    offeringButton(offering, layout: .row)
                }
            }
        } else {
            HStack(alignment: .bottom, spacing: MeterSpacing.xs) {
                ForEach(model.offerings) { offering in
                    offeringButton(offering, layout: .column)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func offeringButton(
        _ offering: TipOffering,
        layout: TipOfferingLabel.Layout
    ) -> some View {
        Button {
            Task { await model.buy(offering) }
        } label: {
            TipOfferingLabel(
                offering: offering,
                kind: treatKind(for: offering),
                layout: layout
            )
            .meterListRowHitTarget()
        }
        .buttonStyle(.plain)
        .disabled(model.isPurchasing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(offering.displayName)，\(offering.displayPrice)")
        .accessibilityHint(L("购买这一档"))
        .accessibilityAddTraits(.isButton)
    }

    /// 只留必要的一句：价格每档下面都写着，不用再解释；「不解锁」得说清楚。
    private var productsFooter: String {
        if model.isPurchasing {
            return String(localized: L("正在向 App Store 确认。"))
        }
        switch model.catalogState {
        case .loading:
            return String(localized: L("正在从 App Store 读取价格。"))
        case .unavailable:
            return String(localized: L("暂时连不上 App Store，价格出不来。"))
        case .ready:
            return String(localized: L("这是打赏，不解锁任何功能。"))
        }
    }

    private var composerSection: some View {
        Section {
            TextField(L("名字（可不填）"), text: $model.draftName)
                .focused($focusedField, equals: .name)
                .onChange(of: model.draftName) { _, newValue in
                    if newValue.count > TipFieldLimits.name {
                        model.draftName = String(newValue.prefix(TipFieldLimits.name))
                    }
                }
            TextField(L("一句话（可不填）"), text: $model.draftMessage, axis: .vertical)
                .lineLimit(3...6)
                .focused($focusedField, equals: .message)
                .onChange(of: model.draftMessage) { _, newValue in
                    if newValue.count > TipFieldLimits.message {
                        model.draftMessage = String(newValue.prefix(TipFieldLimits.message))
                    }
                }
        } footer: {
            VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                Text(L("名字和留言都可以空着。退出这页就当没留。"))
                    .fixedSize(horizontal: false, vertical: true)
                if model.willRetryMessage {
                    Text(L("留言稍后会重发。"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private var historySection: some View {
        Section {
            if model.records.isEmpty {
                Text(L("还没有记录"))
                    .foregroundStyle(Color.meterSecondaryLabel)
            } else {
                ForEach(model.records) { item in
                    VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.productTitle)
                                .font(MeterFont.body)
                                .foregroundStyle(Color.meterLabel)
                            Spacer(minLength: MeterSpacing.sm)
                            Text(item.displayPrice)
                                .font(MeterFont.body)
                                .foregroundStyle(Color.meterSecondaryLabel)
                                .monospacedDigit()
                        }
                        Text(item.purchasedAt, format: .dateTime.month().day().hour().minute())
                            .font(MeterFont.footnote)
                            .foregroundStyle(Color.meterSecondaryLabel)
                            .monospacedDigit()
                        if let name = item.name, !name.isEmpty {
                            Text(name)
                                .font(MeterFont.footnote)
                                .foregroundStyle(Color.meterSecondaryLabel)
                        }
                        if let message = item.message, !message.isEmpty {
                            Text(message)
                                .font(MeterFont.footnote)
                                .foregroundStyle(Color.meterSecondaryLabel)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if !item.isSubmitted {
                            Text(L("留言稍后会重发"))
                                .font(MeterFont.footnote)
                                .foregroundStyle(Color.meterTertiaryLabel)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        } header: {
            Text(L("记录"))
        }
    }

    private func treatKind(for offering: TipOffering) -> TipTreatKind {
        switch offering.productID {
        case .small: .candy
        case .medium: .coffee
        case .large: .pizza
        case nil: .candy
        }
    }
}

private extension TipModel.PurchaseNotice {
    var copy: String {
        switch self {
        case .cancelled: String(localized: L("已取消。"))
        case .pending: String(localized: L("这笔购买正在等待批准。"))
        case .failed: String(localized: L("购买没能完成，请再试一次。"))
        }
    }

    var color: Color {
        switch self {
        case .cancelled: Color.meterSecondaryLabel
        case .pending, .failed: MeterColor.warn
        }
    }
}

#Preview("Light") {
    NavigationStack {
        TipView(model: .preview)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        TipView(model: .preview)
    }
    .preferredColorScheme(.dark)
}

#Preview("Unavailable") {
    NavigationStack {
        TipView(model: .previewUnavailable)
    }
}

#Preview("Composer") {
    NavigationStack {
        TipView(model: .previewComposer)
    }
}

#Preview("History") {
    NavigationStack {
        TipView(model: .previewHistory)
    }
}

#Preview("XXL") {
    NavigationStack {
        TipView(model: .previewHistory)
    }
    .dynamicTypeSize(.accessibility3)
}
