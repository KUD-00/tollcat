import Foundation
import MeterCore

/// 测试用。不碰磁盘。
public final class InMemoryCatalogCache: CatalogCaching, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Catalog?

    public init(_ catalog: Catalog? = nil) {
        stored = catalog
    }

    public func load() -> Catalog? {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    public func save(_ catalog: Catalog) throws {
        guard CatalogAcceptance.isUsable(catalog) else {
            throw CatalogError.unsupportedSchema
        }
        lock.lock()
        stored = catalog
        lock.unlock()
    }
}
