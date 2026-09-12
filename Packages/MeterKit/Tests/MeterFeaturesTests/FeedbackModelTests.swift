import Foundation
import Testing
import MeterFeedback
@testable import MeterFeatures

@MainActor
struct FeedbackModelTests {
    private func model(
        submitter: StubFeedbackSubmitter,
        providers: [String] = ["AWS", "OpenAI"]
    ) -> FeedbackModel {
        FeedbackModel(
            submitter: submitter,
            environment: FeedbackEnvironmentInfo(
                appVersion: "0.1.0 (1)",
                osVersion: "iOS 26.0",
                deviceModel: "iPhone17,1",
                locale: "zh-Hans_CN"
            ),
            connectedProviderNames: { providers },
            makeID: { "fixed-id" }
        )
    }

    // MARK: - 提交

    @Test("空正文按不动发送")
    func blankMessageCannotSubmit() {
        let model = model(submitter: StubFeedbackSubmitter())
        #expect(!model.canSubmit)
        model.message = "   \n  "
        #expect(!model.canSubmit)
        model.message = "有内容"
        #expect(model.canSubmit)
    }

    @Test("发送前 trim，前后空白不进 payload")
    func messageIsTrimmed() async throws {
        let stub = StubFeedbackSubmitter()
        let model = model(submitter: stub)
        model.message = "  登录页转圈  \n"
        await model.submit()
        let sent = try #require(stub.received.first)
        #expect(sent.message == "登录页转圈")
        #expect(model.outcome == .sent)
    }

    @Test("成功之后清空输入框——这个 App 没有回信通道，留副本会让人以为能追进度")
    func successClearsTheDraft() async {
        let model = model(submitter: StubFeedbackSubmitter())
        model.message = "内容"
        model.contact = "a@b.c"
        await model.submit()
        #expect(model.message.isEmpty)
        #expect(model.contact.isEmpty)
    }

    @Test("失败保留输入框，重试不用重写")
    func failureKeepsTheDraft() async {
        let model = model(submitter: StubFeedbackSubmitter(error: .transport))
        model.message = "内容"
        await model.submit()
        #expect(model.message == "内容")
        #expect(model.outcome == .failed)
    }

    @Test("429 报成「提得太密」，不是失败")
    func rateLimitIsItsOwnOutcome() async {
        let model = model(submitter: StubFeedbackSubmitter(error: .rateLimited))
        model.message = "内容"
        await model.submit()
        #expect(model.outcome == .rateLimited)
        // 限流也算没发出去，草稿必须留着。
        #expect(model.message == "内容")
    }

    // MARK: - 服务名单

    @Test("默认不带服务名单")
    func providerListIsOptOut() async throws {
        let stub = StubFeedbackSubmitter()
        let model = model(submitter: stub)
        #expect(!model.includesProviderList)
        model.message = "内容"
        await model.submit()
        #expect(try #require(stub.received.first).providers == nil)
    }

    @Test("开了开关才带，而且只带名字")
    func providerListRidesAlongWhenEnabled() async throws {
        let stub = StubFeedbackSubmitter()
        let model = model(submitter: stub)
        model.includesProviderList = true
        model.message = "内容"
        await model.submit()
        #expect(try #require(stub.received.first).providers == ["AWS", "OpenAI"])
    }

    @Test("界面上那句预览和真正会发出去的名单一致")
    func previewMatchesWhatIsSent() async throws {
        let stub = StubFeedbackSubmitter()
        let model = model(submitter: stub)
        #expect(model.attachedProviderNames.isEmpty)
        model.includesProviderList = true
        #expect(model.attachedProviderNames == ["AWS", "OpenAI"])
        model.message = "内容"
        await model.submit()
        #expect(try #require(stub.received.first).providers == model.attachedProviderNames)
    }

    // MARK: - 环境信息

    @Test("环境信息原样进 payload，界面展示的就是发出去的")
    func environmentTravelsVerbatim() async throws {
        let stub = StubFeedbackSubmitter()
        let model = model(submitter: stub)
        model.message = "内容"
        await model.submit()
        let sent = try #require(stub.received.first)
        #expect(sent.appVersion == model.environment.appVersion)
        #expect(sent.osVersion == model.environment.osVersion)
        #expect(sent.deviceModel == model.environment.deviceModel)
        #expect(sent.locale == model.environment.locale)
    }

    @Test("系统名跟着编译目标走，版本号来自 ProcessInfo")
    func osVersionUsesCompileTargetName() {
        let os = FeedbackEnvironmentInfo.current().osVersion
        let version = ProcessInfo.processInfo.operatingSystemVersion
        #if os(macOS)
        #expect(os.hasPrefix("macOS "))
        #else
        #expect(os.hasPrefix("iOS ") || os.hasPrefix("iPadOS "))
        #endif
        let digits = version.patchVersion == 0
            ? "\(version.majorVersion).\(version.minorVersion)"
            : "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #expect(os.hasSuffix(digits))
    }

    @Test("系统名按编译目标取，禁止写死 iOS")
    func osNameIsNotHardcodedToIOS() throws {
        let text = try GuardrailSourceScan.sourceText(named: "FeedbackEnvironmentInfo.swift")
        #expect(text.contains("#if os(macOS)"))
        #expect(text.contains("\"macOS\""))
        #expect(!text.contains("let name = \"iOS\""))
    }

    @Test("重复按发送只发一条")
    func submitIsGuardedWhileInFlight() async {
        let stub = StubFeedbackSubmitter()
        let model = model(submitter: stub)
        model.message = "内容"
        await model.submit()
        // 第一次成功后正文被清空，再按一次应当什么都不发。
        await model.submit()
        #expect(stub.received.count == 1)
    }

    @Test("字数提示只在接近上限时出现")
    func remainingCountAppearsLate() {
        let model = model(submitter: StubFeedbackSubmitter())
        model.message = "短"
        #expect(!model.showsRemainingCharacters)
        model.message = String(repeating: "字", count: FeedbackFieldLimits.message - 10)
        #expect(model.showsRemainingCharacters)
        #expect(model.remainingCharacters == 10)
    }
}
