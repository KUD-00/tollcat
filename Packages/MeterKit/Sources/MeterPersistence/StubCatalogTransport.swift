import Foundation
import MeterCore

/// 测试用。按 URL 返回罐装正文，或直接抛。
public struct StubCatalogTransport: CatalogTransport, Sendable {
    public var result: Result<(Data, URL), CatalogError>

    public init(result: Result<(Data, URL), CatalogError>) {
        self.result = result
    }

    public init(data: Data, url: URL = CatalogEndpoint.catalogURL) {
        self.result = .success((data, url))
    }

    public func get(_ url: URL) async throws -> (Data, URL) {
        _ = url
        return try result.get()
    }
}
