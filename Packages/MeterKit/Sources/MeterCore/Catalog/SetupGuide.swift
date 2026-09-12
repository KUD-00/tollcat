import Foundation

/// 一家的接入说明。只有文字和数字——创建页 / 账单页 URL 不在这里。
///
/// 向导三步：简介读 `summary` 和凭据名，教程按 `parts` 分段，连接页按 `fields` 填。
/// 计费模式和支持情况是编译进 App 的 `ProviderDescriptor`，不进目录。
public struct SetupGuide: Hashable, Sendable, Codable {
    public struct LocalizedCopy: Hashable, Sendable, Codable {
        public var summary: String?
        public var verifyHint: String?

        public init(summary: String? = nil, verifyHint: String? = nil) {
            self.summary = summary
            self.verifyHint = verifyHint
        }
    }

    /// 这家是什么。简介页的正文，不是步骤。
    public var summary: String
    public var parts: [SetupPart]
    public var verifyHint: String
    public var troubleshooting: [ErrorCase]
    public var en: LocalizedCopy?
    public var ja: LocalizedCopy?

    public init(
        parts: [SetupPart],
        verifyHint: String,
        troubleshooting: [ErrorCase],
        summary: String = "",
        en: LocalizedCopy? = nil,
        ja: LocalizedCopy? = nil
    ) {
        self.summary = summary
        self.parts = parts
        self.verifyHint = verifyHint
        self.troubleshooting = troubleshooting
        self.en = en
        self.ja = ja
    }

    /// 展示用。overlay 剥掉，缺的键回落中文。
    public func localized(for language: CatalogLanguage) -> SetupGuide {
        let copy = language.pick(en: en, ja: ja)
        return SetupGuide(
            parts: parts.map { $0.localized(for: language) },
            verifyHint: catalogOverlay(copy?.verifyHint, fallback: verifyHint),
            troubleshooting: troubleshooting.map { $0.localized(for: language) },
            summary: catalogOverlay(copy?.summary, fallback: summary)
        )
    }

    /// 凭据表单的顺序，跟着分段走。
    public var fields: [SetupField] {
        parts.flatMap(\.fields)
    }

    public var steps: [SetupStep] {
        parts.flatMap(\.steps)
    }

    /// 简介里「需要」那一行。多项写在同一句，不拆成列表行。
    public var needsLine: String {
        fields.map(\.label).joined(separator: " · ")
    }

    enum CodingKeys: String, CodingKey {
        case summary
        case parts
        case verifyHint
        case troubleshooting
        case en
        case ja
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        parts = try container.decodeIfPresent([SetupPart].self, forKey: .parts) ?? []
        verifyHint = try container.decodeIfPresent(String.self, forKey: .verifyHint) ?? ""
        troubleshooting = try container.decodeIfPresent([ErrorCase].self, forKey: .troubleshooting) ?? []
        en = try container.decodeIfPresent(LocalizedCopy.self, forKey: .en)
        ja = try container.decodeIfPresent(LocalizedCopy.self, forKey: .ja)
    }
}

