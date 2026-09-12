import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ProviderSearchTests {
    @Test("搜 claude 能命中 Anthropic")
    func claudeFindsAnthropic() {
        let hits = ProviderCatalog.all.filter { $0.matchesSearchQuery("claude") }
        #expect(hits.map(\.id).contains(.anthropic))
    }

    @Test("搜大写 S3 能命中 AWS")
    func uppercaseS3FindsAWS() {
        let hits = ProviderCatalog.all.filter { $0.matchesSearchQuery("S3") }
        #expect(hits.map(\.id).contains(.aws))
    }

    @Test("搜克劳德能命中 Anthropic")
    func chineseAliasFindsAnthropic() {
        let hits = ProviderCatalog.all.filter { $0.matchesSearchQuery("克劳德") }
        #expect(hits.map(\.id).contains(.anthropic))
    }

    @Test("搜 kimi 或月之暗面能命中 Moonshot (China)")
    func kimiFindsMoonshot() {
        let kimiHits = ProviderCatalog.all.filter { $0.matchesSearchQuery("kimi") }
        #expect(kimiHits.map(\.id).contains(.moonshot))
        let brandHits = ProviderCatalog.all.filter { $0.matchesSearchQuery("月之暗面") }
        #expect(brandHits.map(\.id) == [.moonshot])
    }

    @Test("搜海外能命中 Moonshot (Overseas)，国内站不混进去")
    func overseasFindsMoonshotAI() {
        let hits = ProviderCatalog.all.filter { $0.matchesSearchQuery("海外") }
        #expect(hits.map(\.id).contains(.moonshotAI))
        #expect(!hits.map(\.id).contains(.moonshot))
    }

    @Test("搜不存在的词返回空")
    func unknownQueryIsEmpty() {
        let hits = ProviderCatalog.all.filter { $0.matchesSearchQuery("zzzz-not-a-provider") }
        #expect(hits.isEmpty)
    }

    @Test("搜 cursor 命中 Cursor，搜 SuperGrok 命中 xAI")
    func cursorAndSuperGrokAliases() {
        let cursorHits = ProviderCatalog.all.filter { $0.matchesSearchQuery("cursor") }
        #expect(cursorHits.map(\.id) == [.cursor])
        let grokHits = ProviderCatalog.all.filter { $0.matchesSearchQuery("supergrok") }
        #expect(grokHits.map(\.id).contains(.xai))
        #expect(!grokHits.map(\.id).contains(.cursor))
    }
}
