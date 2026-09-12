import Foundation
import SwiftData
import MeterCore
import MeterPersistence
import MeterProviders

enum BillingRefreshJobs {
    /// 钥匙串读取和整表 fetch 都在 `make` 里面，几家账号就是几次同步 Keychain 调用。
    /// 放在主线程上做会把刚上屏的那一帧压住（冷启动的自动刷新正好撞在进场动画上），
    /// 所以刷新路径一律走这个后台版本。
    static func makeOffMain(
        ids: [AccountID],
        container: ModelContainer,
        credentials: any CredentialStore,
        providers: [ProviderID: any BillingProvider]
    ) async -> [BillingRefreshJob] {
        await Task.detached(priority: .userInitiated) {
            make(ids: ids, container: container, credentials: credentials, providers: providers)
        }.value
    }

    static func make(
        ids: [AccountID],
        container: ModelContainer,
        credentials: any CredentialStore,
        providers: [ProviderID: any BillingProvider]
    ) -> [BillingRefreshJob] {
        let wanted = Set(ids)
        let context = ModelContext(container)
        guard let records = try? context.fetch(FetchDescriptor<ProviderConfigRecord>()) else {
            return []
        }

        var jobs: [BillingRefreshJob] = []
        // 走信箱的家不在这条泳道里。两条泳道同时喂一家会互相覆盖。
        // accountID 解不出的坏行不出 job（读侧同 connectionStates 丢行口径）。
        for record in records {
            guard let accountID = try? record.domainAccountID(),
                  record.isEnabled, record.archivedAt == nil, wanted.contains(accountID), !record.readsFromInbox else {
                continue
            }
            let providerID = record.providerID
            guard let provider = providers[providerID] else { continue }
            let raw = (try? credentials.read(reference: record.credentialReference)) ?? "{}"
            guard let credential = try? StoredCredentialFields.credential(
                providerID: providerID,
                raw: raw
            ) else {
                continue
            }
            jobs.append(
                BillingRefreshJob(
                    id: accountID,
                    providerID: providerID,
                    provider: provider,
                    credential: credential
                )
            )
        }
        return jobs
    }
}
