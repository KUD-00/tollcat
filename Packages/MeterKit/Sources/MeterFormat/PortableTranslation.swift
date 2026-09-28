import Foundation

/// 一条文案的英、日译文。中文就是键本身。
public struct PortableTranslation: Sendable {
    public let en: String
    public let ja: String

    public init(en: String, ja: String) {
        self.en = en
        self.ja = ja
    }
}
