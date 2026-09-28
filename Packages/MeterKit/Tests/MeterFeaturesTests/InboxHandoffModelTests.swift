import Foundation
import SwiftData
import Testing
import MeterCore
import MeterInbox
import MeterPersistence
import MeterProviders
@testable import MeterFeatures

@MainActor
struct InboxHandoffModelTests {
    @Test("拿到 key 就能接入")
    func connectEnabledOnceKeyIssued() {
        #expect(InboxHandoffModel.preview(phase: .issued).canConnect)
    }

    @Test("还没拿到 key 之前接不了——按钮不该是可点的摆设")
    func cannotConnectBeforeKeyIsIssued() {
        for phase in [InboxHandoffModel.Phase.idle, .provisioning, .failed] {
            #expect(!InboxHandoffModel.preview(phase: phase).canConnect, "\(phase) 不该能接入")
        }
    }

    @Test("走信箱的家在向导里会切到任务书那一页")
    func wizardRoutesInboxProviders() {
        for id in [ProviderID.render, .expo, .clerk, .fly] {
            let model = SetupWizardModel.preview(providerID: id)
            #expect(model.usesInbox, "\(id.rawValue) 应该走信箱")
        }
        // 能正常用 API key 的家不该被切走。
        for id in [ProviderID.cloudflare, .vultr, .atlas] {
            let model = SetupWizardModel.preview(providerID: id)
            #expect(!model.usesInbox, "\(id.rawValue) 不该走信箱")
        }
    }

    @Test("任务书按当前 provider 生成，不是写死 Render")
    func promptFollowsProvider() {
        let expo = InboxHandoffModel.preview(providerID: .expo, phase: .issued)
        #expect(expo.prompt.contains("\"provider\":\"expo\""))
        #expect(expo.prompt.contains("Expo EAS"))
        let fly = InboxHandoffModel.preview(providerID: .fly, phase: .issued)
        #expect(fly.prompt.contains("\"provider\":\"fly\""))
        #expect(fly.prompt.contains("Fly.io"))
    }

    @Test("失败态没有 key，也没法接入")
    func failedPhaseHasNoKey() {
        let model = InboxHandoffModel.preview(phase: .failed)
        #expect(model.issuedKey == nil)
        #expect(model.failure != nil)
        #expect(!model.canConnect)
    }

    @Test("已有 mailbox 时 prepare 仍 mint，接入前可 copy")
    func prepareMintsWhenMailboxExists() async throws {
        let credentials = InMemoryCredentialStore()
        try InboxMailboxStore.save(
            StoredInboxMailbox(mailbox: "mb_existing", readKey: "tollr_existing"),
            to: credentials
        )
        let dashboard = DashboardModel(
            providers: [:],
            container: try PersistenceContainer.makeContainer(inMemory: true),
            credentials: credentials,
            clock: .design,
            inboxClient: .stub(),
            httpClient: StubHTTPClient()
        )
        let model = InboxHandoffModel(providerID: .render, dashboard: dashboard)
        await model.prepare()
        #expect(model.phase == .issued)
        #expect(model.issuedKey != nil)
        model.copyIngestKey()
        #expect(model.copyToken == 1)
        #expect(model.canConnect)
        try await model.connect()
        #expect(model.saveToken == 1)
        let state = try #require(dashboard.connectionStates().first { $0.providerID == .render })
        #expect(state.usesInbox)
        #expect(state.inboxIngestKeyID == model.issuedKey?.id)
        #expect(state.credentialReference.hasPrefix("credential."))
        #expect(UUID(uuidString: String(state.credentialReference.dropFirst("credential.".count))) != nil)
    }

    @Test("挂到已有账号时旧 key 吊销失败：不 attach、不报成功，重试成功后才换上新 key")
    func rotateRequiresOldKeyRevoked() async throws {
        let transport = ScriptedInboxTransport()
        let dashboard = try DashboardModelIngestKeyRevokeTests.makeDashboard(transport: transport)
        let accountID = try DashboardModelIngestKeyRevokeTests.seedInboxAccount(on: dashboard, keyID: "key_old")
        let model = InboxHandoffModel(providerID: .render, dashboard: dashboard, attachingAccountID: accountID)
        await model.prepare()
        #expect(model.phase == .issued)
        let newKey = try #require(model.issuedKey)

        transport.setRevokeStatus(503)
        await #expect(throws: InboxError.self) { try await model.connect() }
        #expect(model.saveToken == 0)
        #expect(model.issuedKey == newKey)
        #expect(dashboard.connectionStates().first { $0.accountID == accountID }?.inboxIngestKeyID == "key_old")

        transport.setRevokeStatus(200)
        try await model.connect()
        #expect(model.saveToken == 1)
        #expect(transport.revokedIDs == ["key_old"])
        #expect(dashboard.connectionStates().first { $0.accountID == accountID }?.inboxIngestKeyID == newKey.id)
    }

    @Test("取消时吊销失败：本地不忘这把 key，下次取消接着吊销")
    func discardKeepsKeyUntilRevoked() async throws {
        let transport = ScriptedInboxTransport()
        let dashboard = try DashboardModelIngestKeyRevokeTests.makeDashboard(transport: transport)
        let model = InboxHandoffModel(providerID: .render, dashboard: dashboard)
        await model.prepare()
        let key = try #require(model.issuedKey)

        transport.setRevokeStatus(503)
        await model.discardIfUnconnected()
        #expect(model.issuedKey == key)
        #expect(model.phase == .issued)

        transport.setRevokeStatus(200)
        await model.discardIfUnconnected()
        #expect(model.issuedKey == nil)
        #expect(model.phase == .idle)
        #expect(transport.revokedIDs == [key.id])
    }

    @Test("签 key 途中取消：回来的 key 立刻吊销，页面不推进到已签发")
    func discardDuringMintRevokesLateKey() async throws {
        let transport = ScriptedInboxTransport()
        transport.setMintGated(true)
        let dashboard = try DashboardModelIngestKeyRevokeTests.makeDashboard(transport: transport)
        let model = InboxHandoffModel(providerID: .render, dashboard: dashboard)
        let preparing = Task { await model.prepare() }
        while transport.mintRequests == 0 {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(model.phase == .provisioning)

        await model.discardIfUnconnected()
        transport.setMintGated(false)
        await preparing.value

        #expect(model.phase != .issued)
        #expect(model.issuedKey == nil)
        #expect(!model.canConnect)
        #expect(transport.revokedIDs == ["key_new_1"])
    }
}
