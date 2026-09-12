import Foundation

/// 目录传输层。测试塞 stub，生产用 `LiveCatalogTransport`。
public protocol CatalogTransport: Sendable {
    func get(_ url: URL) async throws -> (Data, URL)
}
