import Foundation

/// 向导要填的字段。`key` 与取数侧的字段名对齐，这里只是字符串。
///
/// `validation` 是文字和数字（长度、前缀、允许的字符），可以进 catalog：
/// 远程改坏最多让一次合法输入过不了。URL 不行——远程可改的跳转地址等于钓鱼页。
public struct SetupField: Hashable, Sendable, Codable {
    public struct LocalizedCopy: Hashable, Sendable, Codable {
        public var label: String?
        public var hint: String?

        public init(label: String? = nil, hint: String? = nil) {
            self.label = label
            self.hint = hint
        }
    }

    public var key: String
    public var label: String
    public var isSecret: Bool
    public var hint: String?
    public var validation: SetupFieldValidation?
    public var en: LocalizedCopy?
    public var ja: LocalizedCopy?

    public init(
        key: String,
        label: String,
        isSecret: Bool,
        hint: String? = nil,
        validation: SetupFieldValidation? = nil,
        en: LocalizedCopy? = nil,
        ja: LocalizedCopy? = nil
    ) {
        self.key = key
        self.label = label
        self.isSecret = isSecret
        self.hint = hint
        self.validation = validation
        self.en = en
        self.ja = ja
    }

    public func localized(for language: CatalogLanguage) -> SetupField {
        let copy = language.pick(en: en, ja: ja)
        return SetupField(
            key: key,
            label: catalogOverlay(copy?.label, fallback: label),
            isSecret: isSecret,
            hint: catalogOverlay(copy?.hint, fallback: hint),
            validation: validation?.localized(for: language)
        )
    }
}
