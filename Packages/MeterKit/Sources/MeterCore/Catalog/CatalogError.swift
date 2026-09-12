import Foundation

public enum CatalogError: Error, Equatable, Sendable {
    case bundleResourceMissing
    /// 远程或缓存的 schema 比 App 认得的新。整份丢掉，继续用手里那份。
    case unsupportedSchema
    case transportFailed
    case emptyResponse
    case hostMismatch
    case tooLarge
    case invalidContentType
}
