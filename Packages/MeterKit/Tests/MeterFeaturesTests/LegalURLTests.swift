import Foundation
import Testing
import MeterProviders
@testable import MeterFeatures

struct LegalURLTests {
    @Test("中文走站点根路径")
    func chineseUsesRootPath() {
        #expect(LegalURL.page("privacy", languageCode: "zh") == URL(string: "https://tollcat.app/privacy/")!)
        #expect(LegalURL.page("support", languageCode: "zh-Hans") == URL(string: "https://tollcat.app/support/")!)
    }

    @Test("英文和日文走对应前缀")
    func localizedPrefixes() {
        #expect(LegalURL.page("privacy", languageCode: "en") == URL(string: "https://tollcat.app/en/privacy/")!)
        #expect(LegalURL.page("support", languageCode: "ja") == URL(string: "https://tollcat.app/ja/support/")!)
    }

    @Test("源码指向 GitHub 仓库")
    func sourcePointsAtGitHub() {
        #expect(LegalURL.source == URL(string: "https://github.com/KUD-00/tollcat")!)
        #expect(OutboundHosts.contains(LegalURL.source))
    }

    @Test("关于页挂着源码链接和 MIT 许可")
    func aboutShowsSourceAndLicense() throws {
        let text = try GuardrailSourceScan.sourceText(named: "AboutView.swift")
        #expect(text.contains("LegalURL.source"))
        #expect(text.contains("L(\"源代码\")"))
        #expect(text.contains("L(\"开源许可\")"))
        #expect(text.contains("\"MIT\""))
    }
}
