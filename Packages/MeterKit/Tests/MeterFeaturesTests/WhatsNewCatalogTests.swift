import Foundation
import Testing
@testable import MeterFeatures

/// 生成物本身的形状。结构由 `scripts/generate-shared.py` 的 `verify_changelog` 把关，
/// 这里守的是**装进 App 之后**还成立的那几条——生成器换了写法也不能破。
struct WhatsNewCatalogTests {
    @Test("版本号唯一、新的在上")
    func entriesAreUniqueAndDescending() {
        let versions = WhatsNewCatalog.entries.map(\.version)
        #expect(Set(versions).count == versions.count)
        let parsed = versions.compactMap(ReleaseVersion.init)
        #expect(parsed.count == versions.count, "每条 version 都要能解成 X.Y.Z")
        #expect(parsed == parsed.sorted(by: >), "新的在上")
    }

    @Test("每条 item 的 id 全局唯一：那是以后文本 overlay 的钥匙")
    func itemIDsAreGloballyUnique() {
        let ids = WhatsNewCatalog.entries.flatMap { $0.items.map(\.id) }
        #expect(Set(ids).count == ids.count)
    }

    @Test("三语都不空，也没有漏译回落成中文")
    func everyStringIsTranslated() {
        var gaps: [String] = []
        for entry in WhatsNewCatalog.entries {
            check(entry.title, at: "\(entry.version).title", into: &gaps)
            for item in entry.items {
                check(item.title, at: "\(entry.version).\(item.id).title", into: &gaps)
                check(item.body, at: "\(entry.version).\(item.id).body", into: &gaps)
            }
        }
        #expect(gaps.isEmpty, Comment(rawValue: gaps.joined(separator: "\n")))
    }

    @Test("至少一条 item：标题撑不起一整张抽屉")
    func everyEntryHasItems() {
        for entry in WhatsNewCatalog.entries {
            #expect(!entry.items.isEmpty, "\(entry.version) 的 items 是空的")
        }
    }

    @Test("只有最新一条能带截图：包体要恒定")
    func onlyTheNewestEntryCarriesAShot() {
        for entry in WhatsNewCatalog.entries.dropFirst() {
            if case .shot = entry.hero {
                Issue.record("\(entry.version) 带了 shot，老条目该退化成纯文字")
            }
        }
    }

    private func check(_ text: WhatsNewText, at path: String, into gaps: inout [String]) {
        for (language, value) in [("zh", text.zh), ("en", text.en), ("ja", text.ja)] {
            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                gaps.append("[\(language)] \(path) 是空的")
            }
        }
        if !text.zh.isEmpty, text.en == text.zh {
            gaps.append("[en] \(path) 还是中文")
        }
        if !text.zh.isEmpty, text.ja == text.zh {
            gaps.append("[ja] \(path) 还是中文")
        }
    }
}
