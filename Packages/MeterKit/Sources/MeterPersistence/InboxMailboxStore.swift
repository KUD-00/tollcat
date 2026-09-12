import Foundation

/// 读数信箱的凭据。**一个用户一份，不挂在任何一家 provider 名下。**
///
/// 为什么不复用 `ProviderConfigRecord.credentialReference`：那条引用是一家一个，
/// 而 `deleteTogetherWithCredentials` 会按引用删 Keychain。三家信箱 provider 若都
/// 指向同一份凭据，删掉其中一家就会把另外两家的信箱一起弄没。
///
/// 所以信箱单独占一条固定引用，provider 的接入记录只留一个 `usesInbox` 标记。
public struct StoredInboxMailbox: Codable, Hashable, Sendable {
    public var mailbox: String
    /// 取回读数用。投递 key 永远不存——它在设备上没有用途，只是多一个泄露面。
    public var readKey: String

    public init(mailbox: String, readKey: String) {
        self.mailbox = mailbox
        self.readKey = readKey
    }
}

public enum InboxMailboxStore: Sendable {
    /// 固定引用。换了它等于所有人的信箱一起失联，不要改。
    public static let credentialReference = "inbox.mailbox"

    public static func load(from credentials: any CredentialStore) -> StoredInboxMailbox? {
        // `try?` 会把 `String??` 摊平成 `String?`，所以这里绑出来就是非可选。
        guard let raw = try? credentials.read(reference: credentialReference) else {
            return nil
        }
        return try? JSONDecoder().decode(StoredInboxMailbox.self, from: Data(raw.utf8))
    }

    public static func save(
        _ mailbox: StoredInboxMailbox,
        to credentials: any CredentialStore
    ) throws {
        let data = try JSONEncoder().encode(mailbox)
        guard let raw = String(data: data, encoding: .utf8) else {
            throw TransferExportError.encodingFailed
        }
        try credentials.save(raw, reference: credentialReference)
    }

    public static func clear(from credentials: any CredentialStore) throws {
        try credentials.delete(reference: credentialReference)
    }
}

extension StoredInboxMailbox: CustomStringConvertible, CustomDebugStringConvertible {
    /// read key 不许进日志。
    public var description: String { "StoredInboxMailbox(\(mailbox))" }
    public var debugDescription: String { description }
}
