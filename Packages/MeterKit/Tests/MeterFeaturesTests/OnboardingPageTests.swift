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

    @Test("开场是四页，顺序是数字、钥匙、小组件、添加")
    func fourPagesInOrder() {
        #expect(OnboardingPage.allCases == [.number, .keychain, .widget, .add])
        #expect(OnboardingPage.number.displayNumber == 1)
        #expect(OnboardingPage.add.displayNumber == 4)
        #expect(OnboardingPage.add.isLast)
        #expect(!OnboardingPage.widget.isLast)
        #expect(OnboardingPage.number.next == .keychain)
        #expect(OnboardingPage.keychain.next == .widget)
        #expect(OnboardingPage.widget.next == .add)
        #expect(OnboardingPage.add.next == nil)
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
        #expect(OnboardingPage.fromLaunchArgument("keychain") == .keychain)
        #expect(OnboardingPage.fromLaunchArgument("1") == .keychain)
        #expect(OnboardingPage.fromLaunchArgument("widget") == .widget)
        #expect(OnboardingPage.fromLaunchArgument("2") == .widget)
        #expect(OnboardingPage.fromLaunchArgument("add") == .add)
        #expect(OnboardingPage.fromLaunchArgument("3") == .add)
    }
}
