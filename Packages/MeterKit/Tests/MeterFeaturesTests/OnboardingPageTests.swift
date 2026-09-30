import Foundation
import Testing
@testable import MeterFeatures

struct OnboardingPageTests {
    @Test("开场导航栏写第几页，不是只靠圆点")
    func onboardingShowsPageDigitsInToolbar() throws {
        let text = try GuardrailSourceScan.sourceText(named: "OnboardingView.swift")
        #expect(text.contains("progressDigits"))
        #expect(text.contains("page.displayNumber"))
        #expect(text.contains("OnboardingPage.allCases.count"))
        #expect(text.contains("ToolbarItem(placement: .principal)"))
    }

    @Test("开场是四页，顺序是这是什么、数字从哪来、凭据放哪、添加")
    func fourPagesInOrder() {
        #expect(OnboardingPage.allCases == [.number, .source, .keychain, .add])
        #expect(OnboardingPage.number.displayNumber == 1)
        #expect(OnboardingPage.add.displayNumber == 4)
        #expect(OnboardingPage.add.isLast)
        #expect(!OnboardingPage.keychain.isLast)
        #expect(OnboardingPage.number.next == .source)
        #expect(OnboardingPage.source.next == .keychain)
        #expect(OnboardingPage.keychain.next == .add)
        #expect(OnboardingPage.add.next == nil)
    }

    @Test("第一页先说这是什么，并且把预览标成示例")
    func firstPageIntroducesTheApp() throws {
        #expect(String(localized: OnboardingPage.number.title) == "把各家云账单，装进口袋")
        #expect(String(localized: OnboardingPage.number.body).contains("TollCat"))
        let view = try GuardrailSourceScan.sourceText(named: "OnboardingView.swift")
        #expect(view.contains("L(\"示例数字\")"))
        #expect(view.contains(".pickerStyle(.menu)"))
    }

    @Test("开场不讲小组件和通知")
    func noWidgetPage() {
        for page in OnboardingPage.allCases {
            let body = String(localized: page.body)
            #expect(!body.contains("小组件"))
            #expect(!body.contains("通知"))
        }
    }

    @Test("竖排时标本放进固定高的图区，四页标题钉在同一条线上")
    func phonePagesPinTitleBelowFixedStage() throws {
        let text = try GuardrailSourceScan.sourceText(named: "OnboardingView.swift")
        #expect(text.contains("minHeight: pageHeight * MeterSpacing.onboardingStageShare"))
    }

    @Test("分页初值要真的滚过去，不能只改计数")
    func pagerScrollsToInitialPage() throws {
        let text = try GuardrailSourceScan.sourceText(named: "OnboardingView.swift")
        #expect(text.contains("ScrollViewReader"))
        #expect(text.contains("proxy.scrollTo(page"))
    }

    @Test("分页宽高不走双向 containerRelativeFrame，避免和外层 ScrollView 互相量尺寸卡死")
    func pagerUsesExplicitPageSize() throws {
        let text = try GuardrailSourceScan.sourceText(named: "OnboardingView.swift")
        #expect(!text.contains(".containerRelativeFrame([.horizontal, .vertical])"))
        #expect(text.contains("GeometryReader"))
        #expect(text.contains("geo.size"))
    }

    @Test("宽壳开场走左右并排，标本限宽")
    func wideOnboardingUsesSideBySideSpecimen() throws {
        let view = try GuardrailSourceScan.sourceText(named: "OnboardingView.swift")
        let wide = try GuardrailSourceScan.sourceText(named: "OnboardingWidePage.swift")
        #expect(view.contains("OnboardingWidePage"))
        #expect(view.contains("usesWideOnboarding"))
        #expect(wide.contains("HStack"))
        #expect(wide.contains("readableMeasure"))
        #expect(wide.contains("previewWidth"))
        #expect(!wide.contains(".containerRelativeFrame"))
    }

    @Test("启动参数命名别名稳定，数字下标跟着页序")
    func launchArgumentMapping() {
        #expect(OnboardingPage.fromLaunchArgument(nil) == .number)
        #expect(OnboardingPage.fromLaunchArgument("number") == .number)
        #expect(OnboardingPage.fromLaunchArgument("source") == .source)
        #expect(OnboardingPage.fromLaunchArgument("1") == .source)
        #expect(OnboardingPage.fromLaunchArgument("keychain") == .keychain)
        #expect(OnboardingPage.fromLaunchArgument("2") == .keychain)
        #expect(OnboardingPage.fromLaunchArgument("add") == .add)
        #expect(OnboardingPage.fromLaunchArgument("3") == .add)
    }
}
