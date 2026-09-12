import Foundation
import MeterCore
import MeterInbox
import MeterPersistence

/// 读数信箱的账号面：mailbox 凭据 + 投递 key 的签 / 列 / 吊销 / 删。
///
/// 只是 `InboxClient` + `InboxMailboxStore` 的组合，零仪表状态。
/// 信箱设置页和接入交接页要的就是这一小块，不必抓着整个 DashboardModel。
@MainActor
final class InboxAccount {
    private let client: InboxClient
    private let credentials: any CredentialStore

    init(client: InboxClient, credentials: any CredentialStore) {
        self.client = client
        self.credentials = credentials
    }

    func mailbox() -> StoredInboxMailbox? {
        InboxMailboxStore.load(from: credentials)
    }

    /// 懒建：第一次真正进信箱流程时才建，之后所有服务复用同一个。
    ///
    /// **不在启动路径上。** 启动即建等于给每个装机用户在服务器上留一行永远
    /// 不会被读的记录，还凭空造出一个装机级别的稳定标识符——那要改隐私披露。
    ///
    /// 已经有信箱就只签一把新的投递 key，一个脚本一把。
    func provisionKey(label: String) async throws -> IssuedIngestKey {
        if let existing = mailbox() {
            return try await client.mintIngestKey(readKey: existing.readKey, label: label)
        }
        let provisioning = try await client.createInbox()
        try InboxMailboxStore.save(
            StoredInboxMailbox(
                mailbox: provisioning.credentials.mailbox,
                readKey: provisioning.credentials.readKey
            ),
            to: credentials
        )
        return provisioning.ingestKey
    }

    func ingestKeys() async throws -> [IngestKeyInfo] {
        guard let stored = mailbox() else { return [] }
        return try await client.listIngestKeys(readKey: stored.readKey)
    }

    func revokeKey(id: String) async throws {
        guard let stored = mailbox() else { return }
        try await client.revokeIngestKey(readKey: stored.readKey, id: id)
    }

    /// 删信箱。服务端那份删掉，本机凭据也一起清 —— 留着等于留一把打不开门的钥匙。
    ///
    /// 走信箱的那几家会立刻断供，所以调用方必须先确认。
    func deleteInbox() async throws {
        guard let stored = mailbox() else { return }
        try await client.deleteInbox(readKey: stored.readKey)
        try InboxMailboxStore.clear(from: credentials)
    }
}
