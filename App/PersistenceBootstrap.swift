import SwiftData
import MeterFeatures
import MeterPersistence

/// 生产路径：先 App Group，失败再退内存。Preview / 测试不走这里。
enum PersistenceBootstrap {
    struct Outcome {
        var container: ModelContainer
        var credentials: any CredentialStore
        var storage: PersistenceStorage
        var containsDemoData: Bool
        var isDemoBannerDismissed: Bool
        var shouldSeed: Bool
    }

    static func makeLive() -> Outcome {
        let credentials = KeychainCredentialStore()
        let prepared = makeContainer()
        let context = ModelContext(prepared.container)
        let preferences = (try? AppPreferencesRecord.load(from: context)) ?? .default
        return Outcome(
            container: prepared.container,
            credentials: credentials,
            storage: prepared.storage,
            containsDemoData: DemoSeedPolicy.storeContainsDemoData(prepared.container),
            isDemoBannerDismissed: preferences.isDemoBannerDismissed,
            // 库打不开的时候**绝不铺演示种子**：磁盘上那份真数据还在原地，
            // 往内存库里塞一批假账单只会让人以为数据被换掉了。
            shouldSeed: prepared.storage != .memoryStoreUnreadable
                && DemoSeedPolicy.shouldSeedEmptyStore(demoModeEnabled: preferences.isDemoModeEnabled)
        )
    }

    private static func makeContainer() -> (container: ModelContainer, storage: PersistenceStorage) {
        // SwiftData 在没有 App Group entitlement 时是 Fatal error，不是 throw。
        // 未签名的测试宿主、以及刚换过 group id 还没注册的设备都会走这里。
        var storeExisted = false
        if PersistenceContainer.appGroupContainerURL() != nil {
            storeExisted = PersistenceContainer.storeFileExists()
            do {
                return (try PersistenceContainer.makeContainer(), .disk)
            } catch {
                // 有 group 路径但建库失败，再退内存。**但是退成哪一种要分清楚**：
                // 库文件本来就不存在（第一次装）和库文件在却打不开（迁移推不动、
                // 文件损坏）在界面上必须是两句不同的话，见 `PersistenceStorage`。
            }
        }
        do {
            return (
                try PersistenceContainer.makeContainer(inMemory: true),
                storeExisted ? .memoryStoreUnreadable : .memoryWithoutAppGroup
            )
        } catch let fallback {
            // 内存库也起不来才停：没有 ModelContainer 就没有任何可展示的状态。
            preconditionFailure("Unable to create persistence: \(fallback)")
        }
    }
}
