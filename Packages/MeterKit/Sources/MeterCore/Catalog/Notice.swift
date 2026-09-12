import Foundation

/// 向导里的提前提醒，例如某家个人账号根本调不通。
public struct Notice: Hashable, Sendable, Codable {
    public struct LocalizedCopy: Hashable, Sendable, Codable {
        public var message: String?

        public init(message: String? = nil) {
            self.message = message
        }
    }

    public var id: String
    public var providerID: ProviderID?
    public var message: String
    public var en: LocalizedCopy?
    public var ja: LocalizedCopy?

    public init(
        id: String,
        providerID: ProviderID? = nil,
        message: String,
        en: LocalizedCopy? = nil,
        ja: LocalizedCopy? = nil
    ) {
        self.id = id
        self.providerID = providerID
        self.message = message
        self.en = en
        self.ja = ja
    }

    public func localized(for language: CatalogLanguage) -> Notice {
        let copy = language.pick(en: en, ja: ja)
        return Notice(
            id: id,
            providerID: providerID,
            message: catalogOverlay(copy?.message, fallback: message)
        )
    }
}
