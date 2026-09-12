import Foundation
import MeterCore

/// M2 加远程源时只新增一个 conformance，调用方继续只认这个接口。
public protocol CatalogSource: Sendable {
    func load() async throws -> Catalog
}
