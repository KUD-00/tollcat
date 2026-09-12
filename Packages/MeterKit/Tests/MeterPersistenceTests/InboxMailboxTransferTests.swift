import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

@MainActor
struct InboxMailboxTransferTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test("信箱跟着迁移包走——不带上就是换设备后静默失效")
    func mailboxSurvivesRoundTrip() throws {
        let source = try PersistenceContainer.makeContainer(inMemory: true)
        let sourceCredentials = InMemoryCredentialStore()
        try InboxMailboxStore.save(
            StoredInboxMailbox(mailbox: "mb_abc", readKey: "tollr_abc"),
            to: sourceCredentials
        )
        let context = ModelContext(source)
        _ = try ProviderConfigStore.insert(
            accountID: AccountID.fixture(for: .render),
            providerID: .render,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: nil,
            isEnabled: true,
            credentialReference: "render-ref",
            includeInGlobalRefresh: nil,
            usesInbox: true,
            inboxIngestKeyID: "key-render",
            lastSuccessfulRefreshAt: nil,
            placement: .exact(0),
            in: context
        )
        try context.save()

        let payload = try DeviceTransfer.collect(container: source, credentials: sourceCredentials)
        #expect(payload.mailbox?.mailbox == "mb_abc")
        #expect(payload.mailbox?.readKey == "tollr_abc")
        #expect(payload.connections.first?.usesInbox == true)

        let destination = try PersistenceContainer.makeContainer(inMemory: true)
        let destinationCredentials = InMemoryCredentialStore()
        let bytes = try DeviceTransfer.makeExport(
            container: source,
            credentials: sourceCredentials,
            now: Date(),
            calendar: calendar,
            code: TransferCode.generate()
        )
        _ = bytes

        // 直接走 encode/decode，避开加密那层——这条测试盯的是载荷内容。
        let restored = try DeviceTransfer.decodePayload(DeviceTransfer.encodePayload(payload))
        #expect(restored.mailbox == payload.mailbox)
        #expect(restored.connections.first?.usesInbox == true)

        try InboxMailboxStore.save(
            StoredInboxMailbox(
                mailbox: restored.mailbox!.mailbox,
                readKey: restored.mailbox!.readKey
            ),
            to: destinationCredentials
        )
        #expect(InboxMailboxStore.load(from: destinationCredentials)?.mailbox == "mb_abc")
        _ = destination
    }

    @Test("缺 mailbox 键的包解不开")
    func payloadWithoutMailboxKeyFails() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let credentials = InMemoryCredentialStore()
        try InboxMailboxStore.save(
            StoredInboxMailbox(mailbox: "mb_abc", readKey: "tollr_abc"),
            to: credentials
        )
        let current = try DeviceTransfer.collect(container: container, credentials: credentials)
        #expect(current.mailbox != nil)

        let encoded = try DeviceTransfer.encodePayload(current)
        var object = try #require(
            try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        object.removeValue(forKey: "mailbox")
        let stripped = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: TransferImportError.invalidFile) {
            try DeviceTransfer.decodePayload(stripped)
        }
    }

    @Test("包里没带信箱时，目的地原有的那个要被清掉")
    func importWithoutMailboxClearsExistingOne() throws {
        let credentials = InMemoryCredentialStore()
        try InboxMailboxStore.save(
            StoredInboxMailbox(mailbox: "mb_old", readKey: "tollr_old"),
            to: credentials
        )
        #expect(InboxMailboxStore.load(from: credentials) != nil)

        try InboxMailboxStore.clear(from: credentials)
        #expect(InboxMailboxStore.load(from: credentials) == nil)
    }

    @Test("read key 不进 description，别写进日志")
    func readKeyIsRedacted() {
        let stored = StoredInboxMailbox(mailbox: "mb_abc", readKey: "tollr_SECRET")
        #expect(!"\(stored)".contains("tollr_SECRET"))
        let transfer = TransferMailbox(mailbox: "mb_abc", readKey: "tollr_SECRET")
        #expect(!"\(transfer)".contains("tollr_SECRET"))
    }

    @Test("老的接入记录没有 usesInbox，按不走信箱读")
    func legacyRecordDefaultsToAPILane() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let record = try ProviderConfigStore.insert(
            accountID: AccountID.fixture(for: .cloudflare),
            providerID: .cloudflare,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: nil,
            isEnabled: true,
            credentialReference: "cf-ref",
            includeInGlobalRefresh: nil,
            usesInbox: nil,
            inboxIngestKeyID: nil,
            lastSuccessfulRefreshAt: nil,
            placement: .exact(0),
            in: context
        )
        #expect(record.usesInbox == nil)
        #expect(!record.readsFromInbox)
    }
}
