import Foundation
import SwiftData
import Testing
import MeterCore
import MeterPersistence
import MeterProviders
@testable import MeterFeatures

@MainActor
struct DemoSeedPipelineTests {
    @Test("种子后 Snapshot 与 ProviderConfigRecord 一一对应")
    func seedAlignsSnapshotsWithConfigs() async throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let credentials = InMemoryCredentialStore()
        let clock = MeterClock.design

        try await DashboardFixtureSeeder.seed(
            into: container,
            credentials: credentials,
            clock: clock
        )

        let context = ModelContext(container)
        let snapshots = try context.fetch(FetchDescriptor<SnapshotRecord>())
        let configs = try context.fetch(FetchDescriptor<ProviderConfigRecord>())

        let snapshotIDs = Set(snapshots.map { ProviderID($0.providerIDRaw) })
        let configIDs = Set(configs.map(\.providerID))

        #expect(!snapshotIDs.isEmpty)
        #expect(snapshotIDs == configIDs)
        #expect(configs.filter(\.isEnabled).count == configs.count)
        let demoRefs = configs.filter { $0.credentialReference.hasPrefix(DemoSeedPolicy.referencePrefix) }
        #expect(demoRefs.count == configs.count)
        for config in configs {
            let suffix = String(config.credentialReference.dropFirst(DemoSeedPolicy.referencePrefix.count))
            #expect(UUID(uuidString: suffix) != nil, "\(config.credentialReference) 不是 demo.credential.<uuid>")
        }
        #expect(configs.map(\.providerID).allSatisfy { $0 != .fly && $0 != .anthropic })
    }

    @Test("DashboardModel.seedDemoData 写入设计稿快照")
    func dashboardSeedDemoDataWritesFixtures() async throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let credentials = InMemoryCredentialStore()
        let clock = MeterClock.design
        let model = DashboardModel(
            providers: [:],
            container: container,
            credentials: credentials,
            clock: clock,
            httpClient: StubHTTPClient()
        )
        try await model.seedDemoData()

        let connected = Set(model.connectionStates().filter(\.isEnabled).map(\.providerID))
        let snapshotIDs = Set(model.debugAllReadings().map(\.providerID))
        #expect(!connected.isEmpty)
        #expect(connected == snapshotIDs)
        #expect(model.containsDemoData())
    }
}
