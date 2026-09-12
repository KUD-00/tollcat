import Foundation
import MeterCore

/// 把解开的目录写成一个 JSON 文件。不是 SwiftData：整份替换，没有行的概念。
public struct CatalogFileCache: CatalogCaching, Sendable {
    public static let fileName = "catalog-cache.json"

    private let fileURL: URL?

    public init(fileURL: URL?) {
        self.fileURL = fileURL
    }

    /// 和生产 SwiftData 同一个 App Group。Widget 才能读到主 App 刚拉下来的汇率。
    public static func appGroup() -> CatalogFileCache {
        let url = PersistenceContainer.appGroupContainerURL()?
            .appending(path: fileName)
        return CatalogFileCache(fileURL: url)
    }

    public func load() -> Catalog? {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        guard let catalog = try? CatalogCodec.decode(data) else { return nil }
        return CatalogAcceptance.isUsable(catalog) ? catalog : nil
    }

    public func save(_ catalog: Catalog) throws {
        guard CatalogAcceptance.isUsable(catalog) else {
            throw CatalogError.unsupportedSchema
        }
        guard let fileURL else { return }
        let data = try CatalogCodec.encode(catalog)
        try data.write(to: fileURL, options: .atomic)
    }
}
