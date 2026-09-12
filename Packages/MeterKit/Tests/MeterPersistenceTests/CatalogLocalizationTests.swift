import Foundation
import Testing
import MeterCore
@testable import MeterPersistence

struct CatalogLocalizationTests {
    @Test("语言标签：en / ja 认出，其余回落中文")
    func resolvingLocaleTags() {
        #expect(CatalogLanguage.resolving(localeTag: "en") == .en)
        #expect(CatalogLanguage.resolving(localeTag: "en-US") == .en)
        #expect(CatalogLanguage.resolving(localeTag: "en_US") == .en)
        #expect(CatalogLanguage.resolving(localeTag: "EN") == .en)
        #expect(CatalogLanguage.resolving(localeTag: "ja") == .ja)
        #expect(CatalogLanguage.resolving(localeTag: "ja-JP") == .ja)
        #expect(CatalogLanguage.resolving(localeTag: "ja_JP") == .ja)
        #expect(CatalogLanguage.resolving(localeTag: "zh") == .zh)
        #expect(CatalogLanguage.resolving(localeTag: "zh-Hans") == .zh)
        #expect(CatalogLanguage.resolving(localeTag: "zh_CN") == .zh)
        #expect(CatalogLanguage.resolving(localeTag: "fr-FR") == .zh)
        #expect(CatalogLanguage.resolving(localeTag: "") == .zh)
    }

    @Test("旧步骤没有 en / ja 也能解")
    func stepWithoutLocaleOverlaysDecodes() throws {
        let json = Data(#"{ "text": "打开控制台。", "emphasized": ["控制台"] }"#.utf8)
        let step = try JSONDecoder().decode(SetupStep.self, from: json)
        #expect(step.en == nil)
        #expect(step.ja == nil)
        #expect(step.localized(for: .en).text == "打开控制台。")
    }

    @Test("步骤 overlay 有 text 时，加粗和可点片段不跟中文混拼")
    func stepOverlayDoesNotMixPhrases() throws {
        let json = Data(
            """
            {
              "text": "打开 Cloudflare 控制台。",
              "linkPhrases": ["Cloudflare 控制台"],
              "en": {
                "text": "Open the Cloudflare dashboard.",
                "linkPhrases": ["Cloudflare dashboard"]
              }
            }
            """.utf8
        )
        let step = try JSONDecoder().decode(SetupStep.self, from: json)
        let english = step.localized(for: .en)
        #expect(english.text == "Open the Cloudflare dashboard.")
        #expect(english.linkPhrases == ["Cloudflare dashboard"])
        #expect(english.en == nil)
        #expect(step.localized(for: .zh).linkPhrases == ["Cloudflare 控制台"])
    }

    @Test("旧缓存缺列时运行时才回落中文；打包目录不许靠这个")
    func independentFallback() throws {
        let json = Data(
            """
            {
              "summary": "中文简介",
              "verifyHint": "中文提示",
              "parts": [],
              "troubleshooting": [],
              "en": { "summary": "English summary" }
            }
            """.utf8
        )
        let guide = try JSONDecoder().decode(SetupGuide.self, from: json)
        let english = guide.localized(for: .en)
        #expect(english.summary == "English summary")
        #expect(english.verifyHint == "中文提示")
        #expect(english.en == nil)
    }

    @Test("打包目录 en / ja 列齐")
    func bundledCatalogHasCompleteLocales() async throws {
        let catalog = try await BundledCatalogSource().load()
        for (id, guide) in catalog.guides {
            assertCopy(guide.en?.summary, matching: guide.summary, at: "\(id.rawValue).summary")
            assertCopy(guide.en?.verifyHint, matching: guide.verifyHint, at: "\(id.rawValue).verifyHint")
            assertCopy(guide.ja?.summary, matching: guide.summary, at: "\(id.rawValue).summary.ja")
            assertCopy(guide.ja?.verifyHint, matching: guide.verifyHint, at: "\(id.rawValue).verifyHint.ja")
            for (partIndex, part) in guide.parts.enumerated() {
                for (fieldIndex, field) in part.fields.enumerated() {
                    let at = "\(id.rawValue).p\(partIndex).f\(fieldIndex)"
                    assertCopy(field.en?.label, matching: field.label, at: "\(at).label")
                    assertCopy(field.ja?.label, matching: field.label, at: "\(at).label.ja")
                    if let hint = field.hint, !hint.isEmpty {
                        assertCopy(field.en?.hint, matching: hint, at: "\(at).hint")
                        assertCopy(field.ja?.hint, matching: hint, at: "\(at).hint.ja")
                    }
                    if let message = field.validation?.message, !message.isEmpty {
                        assertCopy(field.validation?.en?.message, matching: message, at: "\(at).validation")
                        assertCopy(field.validation?.ja?.message, matching: message, at: "\(at).validation.ja")
                    }
                }
                for (stepIndex, step) in part.steps.enumerated() {
                    let at = "\(id.rawValue).p\(partIndex).s\(stepIndex)"
                    assertCopy(step.en?.text, matching: step.text, at: at)
                    assertCopy(step.ja?.text, matching: step.text, at: "\(at).ja")
                    if let copyable = step.copyable {
                        assertCopy(copyable.en?.label, matching: copyable.label, at: "\(at).copyable")
                        assertCopy(copyable.ja?.label, matching: copyable.label, at: "\(at).copyable.ja")
                    }
                }
            }
            for (caseIndex, item) in guide.troubleshooting.enumerated() {
                let at = "\(id.rawValue).t\(caseIndex)"
                assertCopy(item.en?.explanation, matching: item.explanation, at: "\(at).explanation")
                assertCopy(item.en?.nextStep, matching: item.nextStep, at: "\(at).nextStep")
                assertCopy(item.ja?.explanation, matching: item.explanation, at: "\(at).explanation.ja")
                assertCopy(item.ja?.nextStep, matching: item.nextStep, at: "\(at).nextStep.ja")
            }
        }
        for (index, plan) in catalog.plans.enumerated() {
            assertCopy(plan.en?.name, matching: plan.name, at: "plans[\(index)]")
            assertCopy(plan.ja?.name, matching: plan.name, at: "plans[\(index)].ja")
        }
        for (index, notice) in catalog.notices.enumerated() {
            assertCopy(notice.en?.message, matching: notice.message, at: "notices[\(index)]")
            assertCopy(notice.ja?.message, matching: notice.message, at: "notices[\(index)].ja")
        }
    }

    @Test("打包目录：Cloudflare 英文 / 日文教程完整")
    func bundledCloudflareLocales() async throws {
        let catalog = try await BundledCatalogSource().load()
        let cloudflare = try #require(catalog.guides[.cloudflare])

        #expect(cloudflare.summary.contains("CDN"))
        #expect(cloudflare.steps[0].linkPhrases == ["Cloudflare 控制台"])

        let english = cloudflare.localized(for: .en)
        #expect(english.en == nil)
        #expect(english.steps[0].en == nil)
        #expect(english.summary.contains("edge compute"))
        #expect(english.steps[0].text.contains("Cloudflare dashboard"))
        #expect(english.steps[0].linkPhrases == ["Cloudflare dashboard"])
        #expect(english.steps[0].emphasized == ["API Tokens", "Create Token"])
        #expect(english.steps[1].text.contains("Custom token"))
        #expect(english.steps[1].text.contains("Account · Billing · Read"))
        let account = try #require(english.parts[1].steps.first)
        #expect(account.text.contains("Find account and zone IDs"))
        #expect(account.linkPhrases == ["Find account and zone IDs"])
        #expect(account.linkTarget == "findAccountAndZoneIDs")
        #expect(english.verifyHint.contains("don’t save yet"))
        let accountField = try #require(english.fields.first { $0.key == "accountID" })
        #expect(accountField.hint == "In the dashboard sidebar")
        #expect(accountField.validation?.message == "Account ID should be 32 hexadecimal characters")
        #expect(english.troubleshooting.contains { $0.httpStatus == 401 && $0.nextStep.contains("copy it right away") })
        #expect(english.troubleshooting.contains { $0.httpStatus == 403 && $0.nextStep.contains("Account · Billing · Read") })

        let japanese = cloudflare.localized(for: .ja)
        #expect(japanese.summary.contains("エッジコンピューティング"))
        #expect(japanese.steps[0].linkPhrases == ["Cloudflare ダッシュボード"])
        #expect(japanese.steps[0].text.contains("API Tokens"))
        #expect(japanese.verifyHint.contains("まだ保存せず"))
        #expect(japanese.fields.first { $0.key == "accountID" }?.hint == "ダッシュボードのサイドバーにあります")

        let openai = try #require(catalog.guides[.openai])
        #expect(openai.en != nil)
        #expect(openai.localized(for: .en).summary != openai.summary)
        #expect(openai.localized(for: .en).steps[0].text.contains("Admin Key"))
    }

    @Test("overlay 的可点 / 加粗片段是那一句自己的字")
    func overlayPhrasesAreSubstrings() async throws {
        let catalog = try await BundledCatalogSource().load()
        for (id, guide) in catalog.guides {
            for step in guide.steps {
                assertPhrases(step.en, belongTo: id)
                assertPhrases(step.ja, belongTo: id)
            }
        }
        let cloudflare = try #require(catalog.guides[.cloudflare])
        #expect(cloudflare.steps[0].en != nil)
        #expect(cloudflare.steps[0].ja != nil)
    }

    private func assertCopy(_ overlay: String?, matching source: String, at path: String) {
        if source.isEmpty { return }
        #expect(overlay != nil && overlay?.isEmpty == false, "\(path) 缺列")
    }

    private func assertPhrases(_ copy: SetupStep.LocalizedCopy?, belongTo id: ProviderID) {
        guard let copy, let text = copy.text, !text.isEmpty else { return }
        for phrase in (copy.emphasized ?? []) + (copy.linkPhrases ?? []) {
            #expect(text.contains(phrase), "\(id.rawValue) overlay 找不到 \(phrase)")
            #expect(!phrase.contains("://"), "\(id.rawValue) overlay 片段里出现了 URL")
        }
    }
}
