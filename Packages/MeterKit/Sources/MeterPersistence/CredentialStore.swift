import Foundation

public protocol CredentialStore: Sendable {
    func save(_ secret: String, reference: String) throws
    func read(reference: String) throws -> String?
    func delete(reference: String) throws
    /// 清除全部数据时用。按 reference 删完仍可能留下历史 orphan。
    func deleteAll() throws
}
