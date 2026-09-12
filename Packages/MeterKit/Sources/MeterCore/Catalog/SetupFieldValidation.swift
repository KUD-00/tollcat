import Foundation

/// 字段校验规则。用长度 / 前缀 / 允许字符这类数据表达，不要按 provider 写 if-else。
///
/// 这些是文字和数字，放 catalog 不违反安全红线：远程改坏最多拦下一次合法输入。
/// URL 不能进 catalog——远程可改的跳转地址等于钓鱼登录页。
public struct SetupFieldValidation: Hashable, Sendable, Codable {
    public struct LocalizedCopy: Hashable, Sendable, Codable {
        public var message: String?

        public init(message: String? = nil) {
            self.message = message
        }
    }

    public var exactLength: Int?
    public var minLength: Int?
    public var prefix: String?
    /// 允许出现的字符，逐字列出，例如十六进制写 `0123456789abcdefABCDEF`。
    public var allowedCharacters: String?
    /// 失败时给用户看的那句。要具体，不要「格式不正确」。
    public var message: String
    public var en: LocalizedCopy?
    public var ja: LocalizedCopy?

    public init(
        message: String,
        exactLength: Int? = nil,
        minLength: Int? = nil,
        prefix: String? = nil,
        allowedCharacters: String? = nil,
        en: LocalizedCopy? = nil,
        ja: LocalizedCopy? = nil
    ) {
        self.exactLength = exactLength
        self.minLength = minLength
        self.prefix = prefix
        self.allowedCharacters = allowedCharacters
        self.message = message
        self.en = en
        self.ja = ja
    }

    public func localized(for language: CatalogLanguage) -> SetupFieldValidation {
        let copy = language.pick(en: en, ja: ja)
        return SetupFieldValidation(
            message: catalogOverlay(copy?.message, fallback: message),
            exactLength: exactLength,
            minLength: minLength,
            prefix: prefix,
            allowedCharacters: allowedCharacters
        )
    }

    public func errorMessage(for value: String) -> String? {
        if let exactLength, value.count != exactLength {
            return message
        }
        if let minLength, value.count < minLength {
            return message
        }
        if let prefix, !value.hasPrefix(prefix) {
            return message
        }
        if let allowedCharacters {
            let allowed = CharacterSet(charactersIn: allowedCharacters)
            if value.unicodeScalars.contains(where: { !allowed.contains($0) }) {
                return message
            }
        }
        return nil
    }
}
