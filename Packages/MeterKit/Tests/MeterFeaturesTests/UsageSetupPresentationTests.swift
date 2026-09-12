import Foundation
import Testing

struct UsageSetupPresentationTests {
    @Test("连接参考按正文高度，不用 medium 锁死、也不用 fitted 撑成全屏")
    func usageSetupUsesContentHeightDetent() throws {
        let sheet = try GuardrailSourceScan.sourceText(named: "UsageSetupSheet.swift")
        let presentation = try GuardrailSourceScan.sourceText(named: "UsageSetupPresentation.swift")
        let detail = try GuardrailSourceScan.sourceText(named: "ProviderDetailView.swift")
        let guide = try GuardrailSourceScan.sourceText(named: "SetupGuideStepView.swift")
        #expect(sheet.contains("UsageSetupPresentation"))
        #expect(sheet.contains("reportedContentHeight"))
        #expect(!sheet.contains("reportedStep"))
        #expect(!sheet.contains("prefersExpanded"))
        #expect(sheet.contains("meterContainerChromeHeight"))
        #expect(presentation.contains("meterDrawerChrome"))
        #expect(presentation.contains(".expandable"))
        #expect(presentation.contains(".page"))
        #expect(presentation.contains("usesPadChrome ? .page"))
        #expect(!presentation.contains("prefersExpanded"))
        #expect(!presentation.contains("selection:"))
        #expect(detail.contains("UsageSetupSheet("))
        let management = try GuardrailSourceScan.sourceText(named: "CredentialManagementSheet.swift")
        #expect(management.contains("UsageSetupSheet("))
        #expect(!management.contains("meterDrawerChrome"))
        #expect(guide.contains("onScrollGeometryChange"))
        #expect(guide.contains("contentSize.height"))
    }

    @Test("连接参考的弹出状态钉在详情页 View 上，不跟每次新建的 Model 走")
    func usageSetupPresentationLivesOnTheView() throws {
        let detail = try GuardrailSourceScan.sourceText(named: "ProviderDetailView.swift")
        let model = try GuardrailSourceScan.sourceText(named: "ProviderDetailModel.swift")
        let services = try GuardrailSourceScan.sourceText(named: "ServicesView.swift")
        #expect(detail.contains("@State private var model: ProviderDetailModel"))
        #expect(detail.contains("@State private var isPresentingUsageSetup"))
        #expect(detail.contains("$isPresentingUsageSetup"))
        #expect(detail.contains("presentUsageSetup(attachExisting:"))
        #expect(!detail.contains("$model.isPresentingUsageSetup"))
        #expect(!detail.contains("presentInboxSetup"))
        #expect(!model.contains("isPresentingUsageSetup"))
        #expect(!model.contains("isPresentingTypedUsage"))
        #expect(!model.contains("presentInboxSetup"))
        #expect(model.contains("inboxAttachAccountID(attachExisting:"))
        #expect(services.contains(".id(selected)"))
    }

    @Test("凭据步拉开抽屉，测试连接不跟着键盘抬")
    func credentialsDoNotLiftThePrimaryActionForTheKeyboard() throws {
        let credentials = try GuardrailSourceScan.sourceText(named: "SetupCredentialsStepView.swift")
        let inbox = try GuardrailSourceScan.sourceText(named: "InboxHandoffStepView.swift")
        let wizard = try GuardrailSourceScan.sourceText(named: "SetupWizardView.swift")
        let chrome = try GuardrailSourceScan.sourceText(named: "ContainerChromeHeight.swift")
        #expect(credentials.contains("ignoresKeyboard: true"))
        #expect(inbox.contains("ignoresKeyboard: true"))
        #expect(!wizard.contains("reportedStep"))
        #expect(chrome.contains("ignoresSafeArea(.keyboard)"))
        #expect(chrome.contains("acceptedChromeHeight"))
    }
}
