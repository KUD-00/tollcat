import Foundation
import Testing
import MeterCore
import MeterFeedback
import MeterPersistence
import MeterProviders
@testable import MeterFeatures

@MainActor
struct SetupWizardModelTests {
    init() {
        #if DEBUG
        DeveloperSession.shared.resetForTests()
        #endif
    }

    @Test("向导默认从连接参考开始，一步推进到凭据")
    func wizardAdvancesGuideThenCredentials() async {
        let model = SetupWizardModel(providerID: .cloudflare, dashboard: .preview)
        await model.prepare()
        #expect(model.step == .guide)
        #expect(!model.guide.summary.isEmpty)
        model.advanceFromGuide()
        #expect(model.step == .credentials)
        model.returnToGuide()
        #expect(model.step == .guide)
    }

    @Test("连接参考第一帧就有目录里的步骤，不等 prepare")
    func wizardSeedsGuideFromDashboardCatalog() {
        let model = SetupWizardModel(providerID: .cloudflare, dashboard: .preview)
        #expect(!model.guide.parts.isEmpty)
    }

    @Test("Cloudflare 简介：用量后付费，完全支持")
    func cloudflareIntroFacts() {
        let descriptor = ProviderCatalog.cloudflare
        #expect(SetupProviderFacts.kindTitle(for: descriptor) == String(localized: L("用量后付费")))
        #expect(SetupProviderFacts.supportLevel(for: descriptor) == .full)
        #expect(SetupProviderFacts.supportTitle(for: descriptor) == String(localized: L("完全支持")))
        #expect(SetupProviderFacts.supportBars(for: descriptor) == 3)
    }

    @Test("GitHub 连接参考是月费加超额，不是固定订阅")
    func githubIntroFacts() {
        #expect(
            SetupProviderFacts.kindTitle(for: ProviderCatalog.github)
                == String(localized: L("月费加超额"))
        )
        #expect(SetupProviderFacts.supportLevel(for: ProviderCatalog.github) == .full)
    }

    @Test("Twilio 已对过真账，是完全支持")
    func twilioIntroFacts() {
        #expect(SetupProviderFacts.supportLevel(for: ProviderCatalog.twilio) == .full)
        #expect(SetupProviderFacts.supportTitle(for: ProviderCatalog.twilio) == String(localized: L("完全支持")))
        #expect(SetupProviderFacts.supportBars(for: ProviderCatalog.twilio) == 3)
        #expect(SetupProviderFacts.kindTitle(for: ProviderCatalog.twilio) == String(localized: L("用量后付费")))
    }

    @Test("Sentry 已对过真账，是完全支持")
    func sentryIntroFacts() {
        #expect(SetupProviderFacts.supportLevel(for: ProviderCatalog.sentry) == .full)
        #expect(SetupProviderFacts.supportTitle(for: ProviderCatalog.sentry) == String(localized: L("完全支持")))
        #expect(SetupProviderFacts.supportBars(for: ProviderCatalog.sentry) == 3)
        #expect(SetupProviderFacts.kindTitle(for: ProviderCatalog.sentry) == String(localized: L("免费额度内")))
    }

    @Test("支持情况注释只写当前这一档")
    func supportCaptionMatchesLevel() {
        #expect(SetupProviderFacts.supportCaption(for: ProviderCatalog.cloudflare).isEmpty)
        #expect(
            SetupProviderFacts.supportCaption(for: ProviderCatalog.vercel)
                == String(localized: L("我们没正式测过，接入说明可能写错。能接上的话，试试看。"))
        )
        #expect(
            SetupProviderFacts.supportCaption(for: ProviderCatalog.aws)
                == String(localized: L("我们没正式测过，接入说明可能写错。能接上的话，试试看。"))
        )
        #expect(
            SetupProviderFacts.supportCaption(for: ProviderCatalog.clerk)
                == String(localized: L("不能自动取账单。你把数字取来，投进来给 App 读。"))
        )
        #expect(!SetupProviderFacts.supportCaption(for: ProviderCatalog.vercel).contains("花钱"))
        #expect(!SetupProviderFacts.supportCaption(for: ProviderCatalog.aws).contains("花钱"))
    }

    @Test("AWS 和 Vercel 是理论支持；Clerk 走读数信箱")
    func awsAndClerkIntroFacts() {
        #expect(SetupProviderFacts.supportLevel(for: ProviderCatalog.aws) == .theoretical)
        #expect(SetupProviderFacts.supportTitle(for: ProviderCatalog.aws) == String(localized: L("理论支持")))
        #expect(SetupProviderFacts.supportBars(for: ProviderCatalog.aws) == 2)
        #expect(SetupProviderFacts.supportLevel(for: ProviderCatalog.vercel) == .theoretical)
        #expect(SetupProviderFacts.supportTitle(for: ProviderCatalog.vercel) == String(localized: L("理论支持")))
        #expect(SetupProviderFacts.supportLevel(for: ProviderCatalog.clerk) == .inbox)
        #expect(SetupProviderFacts.supportTitle(for: ProviderCatalog.clerk) == String(localized: L("读数信箱")))
        #expect(SetupProviderFacts.supportBars(for: ProviderCatalog.clerk) == 1)
        #expect(SetupProviderFacts.supportLevel(for: ProviderCatalog.fly) == .inbox)
    }

    @Test("添加列表：只给例外注明刷新成本，免费的不注明")
    func listingCaptionOmitsFreeRefresh() {
        #expect(
            ProviderListingCopy.caption(for: ProviderCatalog.cloudflare)
                == String(localized: L("用量后付费"))
        )
        #expect(!ProviderListingCopy.caption(for: ProviderCatalog.cloudflare).contains("刷新免费"))
        #expect(ProviderListingCopy.caption(for: ProviderCatalog.aws).contains("刷新要花钱"))
        #expect(ProviderListingCopy.caption(for: ProviderCatalog.fly).contains("读数信箱"))
        #expect(!ProviderListingCopy.caption(for: ProviderCatalog.fly).contains("刷新免费"))
        #expect(ProviderListingCopy.caption(for: ProviderCatalog.clerk).contains("读数信箱"))
        #expect(ProviderListingCopy.caption(for: ProviderCatalog.cursor) == String(localized: L("固定订阅")))
        #expect(!ProviderListingCopy.caption(for: ProviderCatalog.cursor).contains("刷新免费"))
        #expect(!ProviderListingCopy.caption(for: ProviderCatalog.cursor).contains("读数信箱"))
    }

    @Test("没测通不能保存，主按钮还是测试连接")
    func saveBlockedUntilVerified() async {
        let model = SetupWizardModel(providerID: .cloudflare, dashboard: .preview)
        await model.prepare()
        #expect(!model.canSave)
        #expect(!model.showsSavePrimaryAction)
        #expect(!model.isCredentialPrimaryEnabled)
        #expect(model.saveBlockedReason == nil)
    }

    @Test("凭据空着时测试连接不可按")
    func emptyFieldsDisableTestButton() async {
        let model = SetupWizardModel(providerID: .cloudflare, dashboard: .preview)
        await model.prepare()
        #expect(!model.allFieldsFilled)
        #expect(!model.isCredentialPrimaryEnabled)
        model.updateField("apiToken", value: "token")
        #expect(!model.isCredentialPrimaryEnabled)
        model.updateField("accountID", value: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
        #expect(model.allFieldsFilled)
        #expect(model.isCredentialPrimaryEnabled)
    }

    @Test("测通之后主按钮变成保存")
    func primaryActionFlipsToSaveAfterTest() async {
        let model = SetupWizardModel(providerID: .cloudflare, dashboard: .previewEmpty)
        await model.prepare()
        model.applyLaunchOutcome("success")
        #expect(model.showsSavePrimaryAction)
        #expect(model.canSave)
        #expect(model.isCredentialPrimaryEnabled)
        model.updateField("apiToken", value: "changed-token-value")
        #expect(!model.showsSavePrimaryAction)
        #expect(model.isCredentialPrimaryEnabled)
    }

    @Test("测通之后能写入，saveToken 会加")
    func saveAfterSuccessfulTest() async throws {
        let model = SetupWizardModel(providerID: .cloudflare, dashboard: .previewEmpty)
        await model.prepare()
        model.applyLaunchOutcome("success")
        #expect(model.canSave)
        #expect(model.saveBlockedReason == nil)
        model.save()
        #expect(model.saveToken == 1)
        #expect(model.saveFailureCaption == nil)
        let config = try #require(model.dashboard.connectionStates().first { $0.providerID == .cloudflare })
        let snapshot = try #require(model.dashboard.debugAllReadings().last { $0.providerID == .cloudflare })
        #expect(snapshot.accountID == config.accountID)
    }

    @Test("第二份不预填凭据，昵称必填")
    func secondAccountDoesNotPrefillAndNeedsNickname() async throws {
        let first = SetupWizardModel(providerID: .cloudflare, dashboard: .previewEmpty)
        await first.prepare()
        first.applyLaunchOutcome("success")
        first.fieldValues = [
            CredentialField.accountID.rawValue: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            CredentialField.apiToken.rawValue: "token-one",
        ]
        first.save()
        #expect(first.saveToken == 1)

        let second = SetupWizardModel(providerID: .cloudflare, dashboard: first.dashboard)
        await second.prepare()
        #expect(second.fieldValues.values.allSatisfy { $0.isEmpty })
        #expect(second.showsNicknameFields)
        second.applyLaunchOutcome("success")
        #expect(second.showsSavePrimaryAction)
        #expect(!second.canSave)
        #expect(!second.isCredentialPrimaryEnabled)
        second.newNickname = "工作"
        #expect(second.canSave)
        #expect(second.isCredentialPrimaryEnabled)
    }

    @Test("指纹撞上已有账号就不能保存")
    func fingerprintCollisionBlocksSave() async throws {
        let first = SetupWizardModel(providerID: .cloudflare, dashboard: .previewEmpty)
        await first.prepare()
        first.fieldValues = [
            CredentialField.accountID.rawValue: "a1b2c3d4e5f6aabbccddeeff00112233",
            CredentialField.apiToken.rawValue: "token-one",
        ]
        first.applyLaunchOutcome("success")
        first.fieldValues = [
            CredentialField.accountID.rawValue: "a1b2c3d4e5f6aabbccddeeff00112233",
            CredentialField.apiToken.rawValue: "token-one",
        ]
        first.save()
        #expect(first.saveToken == 1)

        let second = SetupWizardModel(providerID: .cloudflare, dashboard: first.dashboard)
        await second.prepare()
        second.newNickname = "个人"
        second.fieldValues = [
            CredentialField.accountID.rawValue: "a1b2c3d4e5f6aabbccddeeff00112233",
            CredentialField.apiToken.rawValue: "token-two",
        ]
        second.applyLaunchOutcome("success")
        second.fieldValues = [
            CredentialField.accountID.rawValue: "a1b2c3d4e5f6aabbccddeeff00112233",
            CredentialField.apiToken.rawValue: "token-two",
        ]
        second.save()
        #expect(second.saveToken == 0)
        #expect(second.fingerprintCollisionReason != nil)
        #expect(!second.showsSavePrimaryAction)
    }

    @Test("旋转换远程身份不能保存")
    func rotateToDifferentRemoteIdentityIsRejected() async throws {
        let create = SetupWizardModel(providerID: .cloudflare, dashboard: .previewEmpty)
        await create.prepare()
        create.applyLaunchOutcome("success")
        create.fieldValues = [
            CredentialField.accountID.rawValue: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            CredentialField.apiToken.rawValue: "token-one",
        ]
        create.save()
        let accountID = try #require(create.dashboard.connectionStates().first?.accountID)

        let rotate = SetupWizardModel(mode: .rotate(accountID, .cloudflare), dashboard: create.dashboard)
        await rotate.prepare()
        rotate.applyLaunchOutcome("success")
        rotate.fieldValues = [
            CredentialField.accountID.rawValue: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            CredentialField.apiToken.rawValue: "token-two",
        ]
        rotate.save()
        #expect(rotate.saveToken == 0)
        #expect(
            rotate.fingerprintCollisionReason
                == String(localized: L("这不是换密钥，是换远程账号。请再加一份。"))
        )
    }

    @Test("测试失败会加 testFailureToken，给错误触觉")
    func testFailureBumpsToken() async {
        let model = SetupWizardModel(providerID: .cloudflare, dashboard: .previewEmpty)
        await model.prepare()
        #expect(model.testFailureToken == 0)
        model.applyLaunchOutcome("401")
        #expect(model.testFailureToken == 1)
        #expect(!model.showsSavePrimaryAction)
        model.applyLaunchOutcome("success")
        #expect(model.testFailureToken == 1)
        #expect(model.showsSavePrimaryAction)
    }

    @Test("改过凭据要再测，不能直接保存")
    func editingClearsVerification() async {
        let model = SetupWizardModel(providerID: .cloudflare, dashboard: .previewEmpty)
        await model.prepare()
        model.applyLaunchOutcome("success")
        #expect(model.canSave)
        model.updateField("apiToken", value: "changed-token-value")
        #expect(!model.canSave)
        #expect(
            model.saveBlockedReason
                == String(localized: L("凭据改过了，请再测一次再保存。"))
        )
    }

    @Test("点测试连接本身不算改过凭据")
    func startingATestDoesNotClaimCredentialsChanged() async {
        let model = SetupWizardModel(providerID: .cloudflare, dashboard: .previewEmpty)
        await model.prepare()
        fillPreviewFields(model)
        #expect(model.saveBlockedReason == nil)

        // 旧逻辑把「测过、还没结果」当成改过凭据。点测试的第一帧就是这个状态。
        model.didAttemptTest = true
        model.isTesting = true
        #expect(model.saveBlockedReason == nil)
        #expect(!model.needsRetest)
    }

    @Test("测完之后也不要把失败说成凭据改过了")
    func finishedTestDoesNotClaimCredentialsChanged() async {
        let model = SetupWizardModel(providerID: .cloudflare, dashboard: .previewEmpty)
        await model.prepare()
        fillPreviewFields(model)
        await model.testConnection()
        #expect(!model.needsRetest)
        #expect(
            model.saveBlockedReason
                != String(localized: L("凭据改过了，请再测一次再保存。"))
        )
    }

    @Test("同一字段写回原值不算改过凭据")
    func rewritingSameValueKeepsVerification() async {
        let model = SetupWizardModel(providerID: .cloudflare, dashboard: .previewEmpty)
        await model.prepare()
        model.applyLaunchOutcome("success")
        #expect(model.canSave)
        let token = model.fieldValues["apiToken"] ?? ""
        model.updateField("apiToken", value: token)
        #expect(model.canSave)
        #expect(model.saveBlockedReason == nil)
        #expect(!model.needsRetest)
    }

    #if DEBUG
    @Test("开发构建里测试连接会记下 HTTP 往返")
    func testConnectionRecordsDebugExchanges() async throws {
        let model = SetupWizardModel(providerID: .cloudflare, dashboard: .preview)
        await model.prepare()
        fillPreviewFields(model)
        await model.testConnection()
        #expect(!model.debugExchanges.isEmpty)
        let exchange = try #require(model.debugExchanges.first)
        #expect(exchange.summary.contains("cloudflare") || exchange.summary.contains("HTTP") || exchange.summary.contains("noStub"))
    }
    #endif

    @Test("测试连接带上目录汇率，国内站人民币能折成美元")
    func moonshotChinaConvertsWithCatalogRates() async throws {
        let rates = ExchangeRates(usdPerUnit: ["CNY": Decimal(string: "0.1404")!])
        let rateSource = SharedExchangeRates(rates)
        let body = Data(
            """
            {"code":0,"data":{"available_balance":15,"cash_balance":0,"voucher_balance":15},"scode":"0x0","status":true}
            """.utf8
        )
        let httpClient = StubHTTPClient(responses: [
            URL(string: "https://api.moonshot.cn/v1/users/me/balance")!: StubHTTPResponse(body: body),
        ])
        let clock = MeterClock.design
        let providers = ProviderAssembly.make(
            now: { clock.now },
            calendar: clock.calendar,
            httpClient: httpClient,
            rateSource: rateSource
        )
        let dashboard = DashboardModel(
            providers: providers,
            container: try PersistenceContainer.makeContainer(inMemory: true),
            credentials: InMemoryCredentialStore(),
            clock: clock,
            catalogResolver: .bundledOnly(),
            rateSource: rateSource,
            httpClient: httpClient
        )
        let model = SetupWizardModel(providerID: .moonshot, dashboard: dashboard)
        await model.prepare()
        model.updateField("apiKey", value: "sk-kimi-MUST-NOT-LEAK")
        await model.testConnection()
        let snapshot = try #require(model.verifiedSnapshot)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "2.11")!))
        #expect(snapshot.converted?.currency == "CNY")
        #expect(snapshot.converted?.amount == 15)
        guard case .success = model.outcome else {
            Issue.record("expected success, got \(String(describing: model.outcome))")
            return
        }
    }

    @Test("Keychain 失败写在按钮底下，不能静默")
    func saveFailureIsVisible() async throws {
        let dashboard = DashboardModel(
            providers: [:],
            container: try PersistenceContainer.makeContainer(inMemory: true),
            credentials: ThrowingCredentialStore(),
            clock: .design,
            httpClient: StubHTTPClient()
        )
        let model = SetupWizardModel(providerID: .cloudflare, dashboard: dashboard)
        await model.prepare()
        model.applyLaunchOutcome("success")
        #expect(model.canSave)
        model.save()
        #expect(model.saveToken == 0)
        #expect(
            model.saveFailureCaption
                == String(localized: L("没法写进 Keychain。设备解锁后再试一次。"))
        )
    }

    @Test("教程小标题是如何获取字段名")
    func guidePartHeadingIsHowToGet() throws {
        let token = SetupPart(
            fields: [SetupField(key: "apiToken", label: "API Token", isSecret: true)],
            steps: []
        )
        let heading = try #require(SetupPartHeading.resource(for: token))
        #expect(String(localized: heading).contains("API Token"))
        #expect(SetupPartHeading.resource(for: SetupPart(fields: [], steps: [])) == nil)
    }

    @Test("Cloudflare Account ID 步骤打开官方文档，不是控制台")
    func cloudflareAccountIDOpensDocs() async throws {
        let model = SetupWizardModel(providerID: .cloudflare, dashboard: .preview)
        await model.prepare()
        let step = try #require(model.guide.parts[1].steps.first)
        #expect(step.linkTarget == "findAccountAndZoneIDs")
        let url = try #require(model.descriptor?.setupLinkURL(target: step.linkTarget))
        #expect(url.host == "developers.cloudflare.com")
        #expect(url != model.credentialSetupURL)
    }

    @Test("可点片段标成链接，加粗仍在")
    func setupStepLinkAndEmphasis() throws {
        let step = SetupStep(
            text: "打开 Cloudflare 控制台的 API Tokens 页面，点 Create Token。",
            emphasized: ["API Tokens", "Create Token"],
            linkPhrases: ["Cloudflare 控制台"]
        )
        let url = URL(string: "https://dash.cloudflare.com/profile/api-tokens")!
        let text = SetupStepMarkup.attributed(step, linkURL: url)

        let linkRange = try #require(text.range(of: "Cloudflare 控制台"))
        #expect(text[linkRange].link == url)
        #expect(!String(text.characters).contains("\u{FFFC}"))
        #expect(
            SetupStepMarkup.pieces(step).contains(.link("Cloudflare 控制台"))
        )

        let boldRange = try #require(text.range(of: "API Tokens"))
        #expect(text[boldRange].inlinePresentationIntent == .stronglyEmphasized)
        #expect(text[boldRange].link == nil)
    }

    @Test("没有创建页地址就只加粗，不成链接")
    func setupStepWithoutURLHasNoLink() throws {
        let step = SetupStep(
            text: "打开 Cloudflare 控制台。",
            linkPhrases: ["Cloudflare 控制台"]
        )
        let text = SetupStepMarkup.attributed(step, linkURL: nil)
        let range = try #require(text.range(of: "Cloudflare 控制台"))
        #expect(text[range].link == nil)
        #expect(!String(text.characters).contains("\u{FFFC}"))
    }

    @Test("只有还没对过账、且不是读数信箱的家出反馈节")
    func setupFeedbackEligibility() {
        #expect(SetupProviderFacts.offersSetupFeedback(for: ProviderCatalog.vercel))
        #expect(SetupProviderFacts.offersSetupFeedback(for: ProviderCatalog.aws))
        #expect(!SetupProviderFacts.offersSetupFeedback(for: ProviderCatalog.cloudflare))
        #expect(!SetupProviderFacts.offersSetupFeedback(for: ProviderCatalog.twilio))
        #expect(!SetupProviderFacts.offersSetupFeedback(for: ProviderCatalog.clerk))
        #expect(!SetupProviderFacts.offersSetupFeedback(for: nil))
    }

    @Test("向导：测完才出反馈节；完全支持不出")
    func wizardShowsFeedbackAfterTest() {
        let vercel = SetupWizardModel.preview(providerID: .vercel, outcome: .network)
        #expect(vercel.showsSetupFeedback)

        let idle = SetupWizardModel.preview(providerID: .vercel, step: .credentials)
        #expect(!idle.showsSetupFeedback)

        let cloudflare = SetupWizardModel.preview(providerID: .cloudflare, outcome: .network)
        #expect(!cloudflare.showsSetupFeedback)
    }

    @Test("成功预填不含金额；失败预填带 HTTP 状态、不含密钥")
    func setupFeedbackDraftsStayClean() {
        let success = SetupFeedbackCopy.draftMessage(
            providerName: "Vercel",
            outcome: .success(title: "本周期至今 $11.05", detail: "周期")
        )
        #expect(success.contains("Vercel"))
        #expect(!success.contains("11.05"))
        #expect(!success.contains("$"))

        let failure = SetupFeedbackCopy.draftMessage(
            providerName: "Vercel",
            outcome: .http(
                ErrorCase(
                    httpStatus: 403,
                    explanation: "缺权限",
                    nextStep: "回去改"
                )
            )
        )
        #expect(failure.contains("Vercel"))
        #expect(failure.contains("403"))
        #expect(!failure.contains("缺权限"))
    }

    @Test("连接向导的反馈钉死这一家，成功走 other，失败走 bug")
    func setupReportPinsProvider() async throws {
        let stub = StubFeedbackSubmitter()
        let failed = FeedbackModel.setupReport(
            providerName: "Vercel",
            outcome: .network,
            submitter: stub,
            environment: .preview,
            makeID: { "fixed-id" }
        )
        #expect(failed.category == .bug)
        #expect(failed.includesProviderList)
        #expect(failed.attachedProviderNames == ["Vercel"])
        #expect(!failed.message.isEmpty)

        await failed.submit()
        let sent = try #require(stub.received.first)
        #expect(sent.providers == ["Vercel"])
        #expect(sent.category == .bug)
        #expect(!sent.message.contains("$"))

        let succeeded = FeedbackModel.setupReport(
            providerName: "Vercel",
            outcome: .success(title: "$11.05", detail: ""),
            submitter: StubFeedbackSubmitter()
        )
        #expect(succeeded.category == .other)
    }

    @Test("HTTP 摘要默认不带；打开才进 payload，金额打码")
    func setupReportExchangeIsOptIn() async throws {
        let stub = StubFeedbackSubmitter()
        let model = FeedbackModel.setupReport(
            providerName: "Vercel",
            outcome: .network,
            submitter: stub,
            environment: .preview,
            makeID: { "fixed-id" }
        )
        let dump = SetupFeedbackExchange.outboundText([
            HTTPExchange(
                summary: "GET https://api.vercel.com/v2/user\nHTTP 200",
                body: #"{"spend": 11.05, "name": "hobby"}"#
            ),
        ])
        await model.submit(exchange: dump)
        #expect(try #require(stub.received.first).exchange == nil)

        let again = StubFeedbackSubmitter()
        let opted = FeedbackModel.setupReport(
            providerName: "Vercel",
            outcome: .network,
            submitter: again,
            environment: .preview,
            makeID: { "fixed-id-2" }
        )
        opted.includesExchange = true
        await opted.submit(exchange: dump)
        let sent = try #require(again.received.first).exchange
        let text = try #require(sent)
        #expect(text.contains("HTTP 200"))
        #expect(text.contains("***"))
        #expect(!text.contains("11.05"))
        #expect(text.contains("hobby"))
    }

    @Test("出站 HTTP 摘要把金额字段打码，用量 token 计数留下")
    func outboundExchangeRedactsMoneyNotTokenCounts() {
        let redacted = SetupFeedbackExchange.redactMoney(
            in: #"{"currentSpendUSD": 21.4, "total_tokens": 12, "error": "forbidden"}"#
        )
        #expect(redacted.contains("***"))
        #expect(!redacted.contains("21.4"))
        #expect(redacted.contains("12"))
        #expect(redacted.contains("forbidden"))
    }

    private func fillPreviewFields(_ model: SetupWizardModel) {
        for (key, value) in SetupFieldPreviewValue.dictionary(for: model.guide.fields) {
            model.updateField(key, value: value)
        }
    }
}

private struct ThrowingCredentialStore: CredentialStore {
    func save(_ secret: String, reference: String) throws {
        throw CredentialStoreError.saveFailed(-1)
    }

    func read(reference: String) throws -> String? { nil }

    func delete(reference: String) throws {}

    func deleteAll() throws {}
}
