import Foundation

/// 先看 `schemaVersion` 再决定解不解。超版本整份忽略，避免新字段把解析打挂。
public enum CatalogCodec: Sendable {
    public static let supportedSchemaVersion = 2

    /// schema 太新直接抛。打包副本的版本不可能超过本次构建，真抛了就是打包错了；
    /// 远程和缓存抛掉即「当没这回事」，不要把任何兜底写进缓存。
    public static func decode(_ data: Data) throws -> Catalog {
        let catalog = try makeDecoder().decode(Catalog.self, from: data)
        guard catalog.schemaVersion <= supportedSchemaVersion else {
            throw CatalogError.unsupportedSchema
        }
        return catalog
    }

    public static func encode(_ catalog: Catalog) throws -> Data {
        try makeEncoder().encode(catalog)
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
