import Foundation

/// 向导一步。加粗和可点范围单独给出，避免 Persistence 解析 markdown。
///
/// `linkPhrases` 只是这句话里的一段字。默认打开编译死的
/// `credentialSetupURL`；`linkTarget` 非空时打开 descriptor 里同名的
/// `guideURLs` 条目。目录里不许出现 URL。
///
/// `copyable` 是这一步里要粘贴到控制台的原文（IAM JSON）。
/// 编号不进目录，按它所在分段的顺序现算。
public struct SetupStep: Hashable, Sendable, Codable {
    /// 这一语言自己的句子和可点/加粗片段。有 `text` 就不跟中文混拼。
    public struct LocalizedCopy: Hashable, Sendable, Codable {
        public var text: String?
        public var emphasized: [String]?
        public var linkPhrases: [String]?

        public init(
            text: String? = nil,
            emphasized: [String]? = nil,
            linkPhrases: [String]? = nil
        ) {
            self.text = text
            self.emphasized = emphasized
            self.linkPhrases = linkPhrases
        }
    }

    public var text: String
    public var emphasized: [String]
    public var linkPhrases: [String]
    /// 对应 `ProviderDescriptor.guideURLs` 的键。空则走创建 token 那页。
    public var linkTarget: String
    public var copyable: CopyableSnippet?
    public var en: LocalizedCopy?
    public var ja: LocalizedCopy?

    public init(
        text: String,
        emphasized: [String] = [],
        linkPhrases: [String] = [],
        linkTarget: String = "",
        copyable: CopyableSnippet? = nil,
        en: LocalizedCopy? = nil,
        ja: LocalizedCopy? = nil
    ) {
        self.text = text
        self.emphasized = emphasized
        self.linkPhrases = linkPhrases
        self.linkTarget = linkTarget
        self.copyable = copyable
        self.en = en
        self.ja = ja
    }

    public func localized(for language: CatalogLanguage) -> SetupStep {
        let copy = language.pick(en: en, ja: ja)
        if let text = copy?.text, !text.isEmpty {
            return SetupStep(
                text: text,
                emphasized: copy?.emphasized ?? [],
                linkPhrases: copy?.linkPhrases ?? [],
                linkTarget: linkTarget,
                copyable: copyable?.localized(for: language)
            )
        }
        return SetupStep(
            text: text,
            emphasized: emphasized,
            linkPhrases: linkPhrases,
            linkTarget: linkTarget,
            copyable: copyable?.localized(for: language)
        )
    }

    private enum CodingKeys: String, CodingKey {
        case text
        case emphasized
        case linkPhrases
        case linkTarget
        case copyable
        case en
        case ja
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        emphasized = try container.decodeIfPresent([String].self, forKey: .emphasized) ?? []
        linkPhrases = try container.decodeIfPresent([String].self, forKey: .linkPhrases) ?? []
        linkTarget = try container.decodeIfPresent(String.self, forKey: .linkTarget) ?? ""
        copyable = try container.decodeIfPresent(CopyableSnippet.self, forKey: .copyable)
        en = try container.decodeIfPresent(LocalizedCopy.self, forKey: .en)
        ja = try container.decodeIfPresent(LocalizedCopy.self, forKey: .ja)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        if !emphasized.isEmpty {
            try container.encode(emphasized, forKey: .emphasized)
        }
        if !linkPhrases.isEmpty {
            try container.encode(linkPhrases, forKey: .linkPhrases)
        }
        if !linkTarget.isEmpty {
            try container.encode(linkTarget, forKey: .linkTarget)
        }
        if let copyable {
            try container.encode(copyable, forKey: .copyable)
        }
        if let en {
            try container.encode(en, forKey: .en)
        }
        if let ja {
            try container.encode(ja, forKey: .ja)
        }
    }
}

