import Foundation

/// 为拿到某一组凭据要做的事。
///
/// 一段对应「你要准备的一样（或一起诞生的几样）东西」。
/// Cloudflare 的 API Token 和 Account ID 不是同一次操作，所以是两段。
/// AWS 的 Access Key ID 和 Secret 是一次创建出来的，所以在同一段。
public struct SetupPart: Hashable, Sendable, Codable {
    public var fields: [SetupField]
    public var steps: [SetupStep]

    public init(fields: [SetupField], steps: [SetupStep]) {
        self.fields = fields
        self.steps = steps
    }

    public func localized(for language: CatalogLanguage) -> SetupPart {
        SetupPart(
            fields: fields.map { $0.localized(for: language) },
            steps: steps.map { $0.localized(for: language) }
        )
    }

    /// 分段标题。没有凭据字段的说明（信箱）为空。
    public var title: String {
        fields.map(\.label).joined(separator: " · ")
    }
}
