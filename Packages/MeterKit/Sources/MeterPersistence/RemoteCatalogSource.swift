import Foundation
import MeterCore

/// 打编译死的目录地址，解开一份可用的 `Catalog`。
///
/// schema 太新、host 被重定向走、正文不是 JSON，一律当这次没拉到。
/// 调用方（`CatalogResolver`）负责静默回退，这里不猜一份假目录。
public struct RemoteCatalogSource: CatalogSource, Sendable {
    public var transport: any CatalogTransport
    public var url: URL

    public init(
        transport: any CatalogTransport = LiveCatalogTransport(),
        url: URL = CatalogEndpoint.catalogURL
    ) {
        self.transport = transport
        self.url = url
    }

    public func load() async throws -> Catalog {
        let (data, _) = try await transport.get(url)
        let catalog = try CatalogCodec.decode(data)
        guard CatalogAcceptance.isUsable(catalog) else {
            throw CatalogError.unsupportedSchema
        }
        return catalog
    }
}
