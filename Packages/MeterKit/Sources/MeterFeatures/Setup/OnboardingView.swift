import SwiftUI
import MeterCore
import MeterDesign
import MeterFormat
import MeterUsage

struct OnboardingView: View {
    var initialPage: OnboardingPage = .number
    var presentation: MoneyPresentation = .usd
    var availableCurrencies: [String] = [ExchangeRates.usdCode]
    var onDisplayCurrencyChange: (String) -> Void = { _ in }
    var onSkip: () -> Void
    var onAddFirstProvider: () -> Void

    @State private var page: OnboardingPage
    @State private var compositionRevealEpoch = 0
    @Environment(\.usesPadChrome) private var usesPadChrome
    @Environment(\.meterShell) private var shell
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        initialPage: OnboardingPage = .number,
        presentation: MoneyPresentation = .usd,
        availableCurrencies: [String] = [ExchangeRates.usdCode],
        onDisplayCurrencyChange: @escaping (String) -> Void = { _ in },
        onSkip: @escaping () -> Void,
        onAddFirstProvider: @escaping () -> Void
    ) {
        self.initialPage = initialPage
        self.presentation = presentation
        self.availableCurrencies = availableCurrencies
        self.onDisplayCurrencyChange = onDisplayCurrencyChange
        self.onSkip = onSkip
        self.onAddFirstProvider = onAddFirstProvider
        _page = State(initialValue: initialPage)
    }

    var body: some View {
        NavigationStack {
            pager
            .background(Color.meterGroupedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .recordsUsageScreen(.onboarding)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(progressDigits)
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .monospacedDigit()
                        // 系统玻璃胶囊会贴着文字裁。footnote 的「1 / 4」左右要留开，不然像被掐住。
                        .padding(.horizontal, MeterSpacing.sm)
                        .accessibilityHidden(true)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("跳过"), action: onSkip)
                        .accessibilityIdentifier(UITestID.onboardingSkip)
                }
            }
            .meterPrimaryActionBar {
                Button(action: advance) {
                    Text(page.isLast ? L("添加第一个服务") : L("继续"))
                        .frame(maxWidth: .infinity)
                }
                .meterPrimaryActionStyle()
                .accessibilityIdentifier(UITestID.onboardingNext)
                .frame(
                    maxWidth: usesPadChrome
                        ? MeterSpacing.onboardingActionWidth
                        : MeterSpacing.readableMeasure,
                    minHeight: usesPadChrome
                        ? MeterSpacing.onboardingActionHeight
                        : MeterSpacing.primaryActionMinHeight
                )
                .frame(maxWidth: .infinity)
            }
        }
        .environment(\.moneyPresentation, presentation)
        .environment(\.compositionRevealEpoch, compositionRevealEpoch)
        .onChange(of: page) { _, new in
            if new == .number {
                compositionRevealEpoch += 1
            }
        }
    }

    /// TabView `.page` 点「继续」会硬切，只有手势才轮换。
    /// 分页 ScrollView 让按钮和手势走同一条横向滑入。
    ///
    /// 每一页的宽高必须来自外层 GeometryReader，不能用
    /// `containerRelativeFrame([.horizontal, .vertical])`：横向 ScrollView
    /// 的高度问内容，内容高度又问容器，主线程会在量尺寸里卡死。
    /// 点「重放 onboarding」之后每次冷启动都走这里。
    private var pager: some View {
        GeometryReader { geo in
            let size = geo.size
            if size.width > 1, size.height > 1 {
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(OnboardingPage.allCases, id: \.self) { item in
                            pageView(item, size: size)
                                .frame(width: size.width, height: size.height)
                                .id(item)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: pageID)
                .scrollIndicators(.hidden)
                .overlay(alignment: .bottom) {
                    OnboardingPageControl(page: page, onChange: move)
                        .frame(minHeight: MeterSpacing.minTap)
                        .padding(.bottom, MeterSpacing.sm)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pageID: Binding<OnboardingPage?> {
        Binding(
            get: { page },
            set: { newValue in
                guard let newValue, newValue != page else { return }
                page = newValue
            }
        )
    }

    private var usesWideOnboarding: Bool {
        usesPadChrome && !dynamicTypeSize.isAccessibilitySize
    }

    private func pageView(_ item: OnboardingPage, size: CGSize) -> some View {
        Group {
            if usesWideOnboarding {
                OnboardingWidePage(
                    title: item.title,
                    bodyText: item.body(shell: shell),
                    spokenProgress: progressSpoken(for: item),
                    previewWidth: previewWidth(for: item),
                    minHeight: size.height
                ) {
                    stage(for: item)
                }
            } else {
                phonePageView(item)
            }
        }
    }

    /// 竖屏、窄分屏、超大字号：仍是上图下文。窗口比手机宽时标本和正文限宽居中，不拉成通栏。
    private func phonePageView(_ item: OnboardingPage) -> some View {
        ScrollView {
            VStack(spacing: MeterSpacing.lg) {
                Spacer(minLength: MeterSpacing.md)
                stage(for: item)
                    .frame(maxWidth: previewWidth(for: item))
                Text(item.title)
                    .font(MeterFont.title2)
                    .foregroundStyle(Color.meterLabel)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityValue(progressSpoken(for: item))
                Text(item.body(shell: shell))
                    .font(MeterFont.body)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: MeterSpacing.md)
            }
            .padding(.horizontal, MeterSpacing.pageHorizontal)
            .frame(maxWidth: MeterSpacing.readableMeasure)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .accessibilityElement(children: .contain)
    }

    private func previewWidth(for page: OnboardingPage) -> CGFloat {
        switch page {
        case .widget: MeterSpacing.onboardingWidgetWidth
        case .number, .keychain, .add: MeterSpacing.onboardingPreviewWidth
        }
    }

    @ViewBuilder
    private func stage(for item: OnboardingPage) -> some View {
        switch item {
        case .number:
            VStack(spacing: MeterSpacing.md) {
                OnboardingDashboardPreview(presentation: presentation)
                currencyPicker
            }
        case .keychain:
            OnboardingKeychainPreview()
        case .widget:
            // TODO: Mac 第 3 页标本要单独定制，见 OnboardingMacGlancePreview。
            if shell == .mac {
                OnboardingMacGlancePreview(presentation: presentation)
            } else {
                OnboardingWidgetPreview(presentation: presentation)
            }
        case .add:
            OnboardingAddProviderPreview()
        }
    }

    private var currencyPicker: some View {
        Picker(L("显示货币"), selection: currencyBinding) {
            ForEach(availableCurrencies, id: \.self) { code in
                Text(DisplayCurrencyCopy.pickerLabel(for: code)).tag(code)
            }
        }
        .pickerStyle(.menu)
        .accessibilityLabel(L("显示货币"))
        .accessibilityHint(L("账本按美元记。选别的货币时，按目录里的汇率换算显示，和厂商实际结算价会有出入。"))
    }

    private var currencyBinding: Binding<String> {
        Binding(
            get: { presentation.currencyCode },
            set: { code in
                onDisplayCurrencyChange(code)
            }
        )
    }

    private var progressDigits: String {
        "\(page.displayNumber) / \(OnboardingPage.allCases.count)"
    }

    private func progressSpoken(for item: OnboardingPage) -> String {
        String(localized: L("第 \(item.displayNumber) 页，共 \(OnboardingPage.allCases.count) 页"))
    }

    private func advance() {
        if let next = page.next {
            move(to: next)
        } else {
            onAddFirstProvider()
        }
    }

    private func move(to new: OnboardingPage) {
        guard new != page else { return }
        if reduceMotion {
            page = new
        } else {
            withAnimation(.smooth(duration: 0.45)) {
                page = new
            }
        }
    }
}

#Preview("Light") {
    OnboardingPreviewHost()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingPreviewHost()
        .preferredColorScheme(.dark)
}

#Preview("XXL") {
    OnboardingPreviewHost(initialPage: .keychain)
        .dynamicTypeSize(.accessibility3)
}

#Preview("Pad") {
    OnboardingPreviewHost()
        .environment(\.meterShell, .pad)
        .frame(width: 1194, height: 834)
}

#Preview("Pad · Widget") {
    OnboardingPreviewHost(initialPage: .widget)
        .environment(\.meterShell, .pad)
        .frame(width: 1194, height: 834)
}

#Preview("Mac") {
    OnboardingPreviewHost()
        .environment(\.meterShell, .pad)
        .frame(
            width: MeterSpacing.macWindowIdealWidth,
            height: MeterSpacing.macWindowIdealHeight
        )
}

#Preview("Widget") {
    OnboardingPreviewHost(initialPage: .widget)
        .preferredColorScheme(.light)
}

#Preview("Add") {
    OnboardingPreviewHost(initialPage: .add)
        .preferredColorScheme(.light)
}

private struct OnboardingPreviewHost: View {
    var initialPage: OnboardingPage = .number
    @State private var presentation = MoneyPresentation(
        currencyCode: ExchangeRates.usdCode,
        rates: ExchangeRates(usdPerUnit: ["CNY": Decimal(string: "0.14") ?? 0.14, "JPY": Decimal(string: "0.0067") ?? 0.0067])
    )

    var body: some View {
        OnboardingView(
            initialPage: initialPage,
            presentation: presentation,
            availableCurrencies: presentation.rates.displayCodes,
            onDisplayCurrencyChange: { code in
                presentation = MoneyPresentation(currencyCode: code, rates: presentation.rates)
            },
            onSkip: {},
            onAddFirstProvider: {}
        )
    }
}
