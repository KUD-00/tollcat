import Foundation
import SwiftData
import MeterCore
import MeterPersistence
import MeterProviders

/// Preview / 演示种子：接入记录 + SPEC 第 04 节那组设计稿快照。
/// 运行时刷新和测试连接走真适配器，不经过这里。
public enum DashboardFixtureSeeder {
    /// 演示数据读哪一套。只有截图脚本会带 `-demo-fixtures=`，Release 里恒为 nil。
    /// 判据放在这里而不是让每个调用方多传一个参数：Preview、App 启动、测试
    /// 三条路都不该关心中国区那一套图的事。
    private static var overlay: FixtureOverlay? {
        FeatureLaunchArguments.demoFixtureOverlay
    }

    public static func seed(
        into container: ModelContainer,
        credentials: any CredentialStore,
        clock: MeterClock
    ) async throws {
        try seedBlocking(into: container, credentials: credentials, clock: clock)
    }

    /// Preview / App 启动不能 await。
    public static func seedBlocking(
        into container: ModelContainer,
        credentials: any CredentialStore,
        clock: MeterClock
    ) throws {
        let prepared = try prepareConnections(
            into: container,
            credentials: credentials,
            clock: clock
        )
        guard prepared else { return }
        try persistDesignSnapshots(into: container, clock: clock)
    }

    /// 只建接入和演示订阅，不写 Snapshot。已有 Snapshot 时整段跳过。
    @discardableResult
    public static func prepareConnections(
        into container: ModelContainer,
        credentials: any CredentialStore,
        clock: MeterClock
    ) throws -> Bool {
        let context = ModelContext(container)
        let existingSnapshots = try context.fetch(FetchDescriptor<SnapshotRecord>())
        guard existingSnapshots.isEmpty else { return false }

        let subscriptions = try FixtureLoader.designSubscriptions(
            now: clock.now,
            calendar: clock.calendar,
            overlay: overlay
        )
        for subscription in subscriptions {
            context.insert(SubscriptionRecord(domain: subscription, calendar: clock.calendar))
        }

        for (index, descriptor) in ProviderCatalog.offered.enumerated() {
            // 没有演示 fixture 的家跳过就好。目录里新加一家还没配 fixture 时，
            // `isConnected` 会 throw；照原样往外抛会让整个演示种子一条都不写，
            // 而调用方是 `try?`，失败还是静默的——排查起来是"演示模式忽然空了"。
            guard (try? FixtureLoader.isConnected(descriptor.id, overlay: overlay)) == true else { continue }
            let accountID = AccountID(rawValue: UUID())
            let reference = DemoSeedPolicy.credentialReference(for: accountID)
            try credentials.save(demoSecret(for: descriptor.id), reference: reference)
            _ = try ProviderConfigStore.insert(
                accountID: accountID,
                providerID: descriptor.id,
                nickname: nil,
                identityHint: nil,
                remoteIdentityFingerprint: nil,
                isEnabled: true,
                credentialReference: reference,
                includeInGlobalRefresh: !descriptor.costsMoneyToRefresh,
                usesInbox: false,
                inboxIngestKeyID: nil,
                lastSuccessfulRefreshAt: nil,
                placement: .exact(index),
                in: context
            )
            _ = try ProviderMembershipStore.ensure(descriptor.id, in: context)
        }

        try context.save()
        return true
    }

    private static func persistDesignSnapshots(into container: ModelContainer, clock: MeterClock) throws {
        let context = ModelContext(container)
        let records = (try? context.fetch(FetchDescriptor<ProviderConfigRecord>())) ?? []
        var accounts: [ProviderID: AccountID] = [:]
        for record in records {
            if accounts[record.providerID] == nil, let accountID = try? record.domainAccountID() {
                accounts[record.providerID] = accountID
            }
        }
        let snapshots = (try? FixtureLoader.designSnapshots(
            now: clock.now,
            calendar: clock.calendar,
            overlay: overlay
        )) ?? []
        let stamped = snapshots.compactMap { snapshot -> Snapshot? in
            guard let accountID = accounts[snapshot.providerID] else { return nil }
            var copy = snapshot
            copy.accountID = accountID
            return copy
        }
        guard !stamped.isEmpty else { return }
        _ = try SnapshotWriter.persist(contentsOf: stamped, into: container, calendar: clock.calendar)
    }

    private static func demoSecret(for id: ProviderID) -> String {
        (try? StoredCredentialFields.encode([
            CredentialField.apiToken.rawValue: "demo-token",
            CredentialField.accountID.rawValue: "demo-account",
        ])) ?? "demo-token.\(id.rawValue)"
    }
}
