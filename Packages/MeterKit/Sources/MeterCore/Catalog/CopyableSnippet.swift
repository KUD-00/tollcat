import Foundation

/// 这一步里要粘贴到控制台的原文（IAM JSON）。
/// 贴在对应步骤下面，不单独成节。
public struct CopyableSnippet: Hashable, Sendable, Codable {
    public struct LocalizedCopy: Hashable, Sendable, Codable {
        public var label: String?

        public init(label: String? = nil) {
            self.label = label
        }
    }

    public var label: String
    public var value: String
    public var en: LocalizedCopy?
    public var ja: LocalizedCopy?

    public init(
        label: String,
        value: String,
        en: LocalizedCopy? = nil,
        ja: LocalizedCopy? = nil
    ) {
        self.label = label
        self.value = value
        self.en = en
        self.ja = ja
    }

    public func localized(for language: CatalogLanguage) -> CopyableSnippet {
        let copy = language.pick(en: en, ja: ja)
        return CopyableSnippet(
            label: catalogOverlay(copy?.label, fallback: label),
            value: value
        )
    }
}
