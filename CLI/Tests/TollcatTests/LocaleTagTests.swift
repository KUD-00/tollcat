import Testing
@testable import TollcatCore

struct LocaleTagTests {
    @Test func langJa() {
        #expect(LocaleTag.resolve(explicit: nil, environment: ["LANG": "ja_JP.UTF-8"]) == "ja")
    }

    @Test func langEn() {
        #expect(LocaleTag.resolve(explicit: nil, environment: ["LANG": "en_US.UTF-8"]) == "en")
    }

    @Test func langZh() {
        #expect(LocaleTag.resolve(explicit: nil, environment: ["LANG": "zh_CN.UTF-8"]) == "zh-Hans")
    }

    @Test func explicitOverrides() {
        #expect(
            LocaleTag.resolve(explicit: "en", environment: ["LANG": "ja_JP.UTF-8"]) == "en"
        )
    }

    @Test func cFallsBackToChinese() {
        #expect(LocaleTag.resolve(explicit: nil, environment: ["LANG": "C"]) == "zh-Hans")
    }
}
