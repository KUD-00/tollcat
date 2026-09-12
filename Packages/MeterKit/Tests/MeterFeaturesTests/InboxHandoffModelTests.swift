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
}
