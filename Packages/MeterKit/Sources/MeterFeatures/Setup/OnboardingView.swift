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
                ScrollViewReader { proxy in
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
                    // `scrollPosition` 的初值在 ScrollView 头一次出现时不生效：
                    // 从第 3 页起步时计数和圆点写着 3 / 4，画面却停在第一页。
                    .onAppear { proxy.scrollTo(page, anchor: .leading) }
                    .overlay(alignment: .bottom) {
                        OnboardingPageControl(page: page, onChange: move)
                            .frame(minHeight: MeterSpacing.minTap)
                            .padding(.bottom, MeterSpacing.sm)
                    }
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
                    bodyText: item.body,
                    spokenProgress: progressSpoken(for: item),
                    previewWidth: MeterSpacing.onboardingPreviewWidth,
                    minHeight: size.height
                ) {
                    stage(for: item)
                }
            } else {
                phonePageView(item, pageHeight: size.height)
            }
        }
    }

    /// 竖屏、窄分屏、超大字号：仍是上图下文。窗口比手机宽时标本和正文限宽居中，不拉成通栏。
    ///
    /// 标本放在一块固定高的图区里居中，标题从图区下沿开始：四页的标本高矮不一，
    /// 标题和正文却钉在同一条线上，翻页时文字不跳。第一页的标本最高，图区按它留够；
    /// 超大字号下标本比图区高，就把图区撑开，退回自然排布。
    private func phonePageView(_ item: OnboardingPage, pageHeight: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: MeterSpacing.lg) {
                stage(for: item)
                    .frame(maxWidth: MeterSpacing.onboardingPreviewWidth)
                    .frame(maxWidth: .infinity, minHeight: pageHeight * MeterSpacing.onboardingStageShare)
                Text(item.title)
                    .font(MeterFont.title2)
                    .foregroundStyle(Color.meterLabel)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityValue(progressSpoken(for: item))
                Text(item.body)
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

    @ViewBuilder
    private func stage(for item: OnboardingPage) -> some View {
        switch item {
        case .number:
            VStack(spacing: MeterSpacing.xs) {
                OnboardingDashboardPreview(presentation: presentation)
                // 新用户会把 $43.20 当成自己的账单：「示例数字」和货币下拉挤一行，不另占一段。
                HStack(spacing: MeterSpacing.sm) {
                    Text(L("示例数字"))
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                    Spacer(minLength: MeterSpacing.sm)
                    currencyPicker
                }
                .padding(.leading, MeterSpacing.md)
            }
        case .source:
            OnboardingSourcePreview(shell: shell)
        case .keychain:
            OnboardingKeychainPreview()
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

#Preview("Pad · Source") {
    OnboardingPreviewHost(initialPage: .source)
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

#Preview("Source") {
    OnboardingPreviewHost(initialPage: .source)
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
