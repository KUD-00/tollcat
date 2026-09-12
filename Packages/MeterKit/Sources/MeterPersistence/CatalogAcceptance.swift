import Foundation
import MeterCore

/// 一份目录能不能当真用。打包副本永远该过；远程和缓存过不了就当没这回事。
enum CatalogAcceptance: Sendable {
    static func isUsable(_ catalog: Catalog) -> Bool {
        catalog.schemaVersion <= CatalogCodec.supportedSchemaVersion
    }
}
