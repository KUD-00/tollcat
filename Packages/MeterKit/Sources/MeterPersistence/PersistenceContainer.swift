import Foundation
import SwiftData

/// 库的第 1 版。
///
/// **每一张表都要列在这里。**SwiftData 没有"自动发现"——漏一张的表现是那张表
/// 在真机上根本不存在，而 Debug 下往往正常（内存库按 `schema` 建），
/// 于是漏写只会在装到设备上之后暴露。
///
/// 以后加字段 / 改字段：
/// - **纯增量**（新表、带默认值的新字段）继续留在这一版里，轻量迁移自己会推；
/// - **改语义**（字段换类型、拆表、主键变了）必须开 `SchemaV2`，
///   把 V1 原样冻住，在 `TollCatMigrationPlan.stages` 里写一条 custom stage。
///   把旧版本就地改掉等于告诉 SwiftData"这一版一直长这样"，
///   老库拿着新 schema 去开，轻量迁移推不动就是**开不了库**。
public enum TollCatSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [
            SnapshotRecord.self,
            SubscriptionRecord.self,
            ManualUsageRecord.self,
            ProviderConfigRecord.self,
            ProviderMembershipRecord.self,
            AppPreferencesRecord.self,
            TipRecord.self,
            // 物化账本三张表。**纯增量**：它们是缓存，旧库里没有就是空的，
            // 折一遍就有了——所以加它们不需要任何数据迁移。
            MonthlyRollupRecord.self,
            AccountLatestRecord.self,
            LedgerStampRecord.self,
        ]
    }
}

/// 迁移计划。现在只有一版，`stages` 是空的。
///
/// 它现在就得在：容器一旦不带迁移计划建起来，将来第一次真需要迁移时
/// 没有地方挂那一步，只能靠轻量迁移碰运气。这条现在是零成本，
/// 发布之后就变成"改不动了"。
public enum TollCatMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [TollCatSchemaV1.self]
    }

    public static var stages: [MigrationStage] { [] }
}

/// SwiftData 容器。从第一天就建在 App Group 里——Widget 只能读主 App 写下的数据，
/// 后期再搬 store 会留下两份对不上的历史（SPEC 第 09 节）。
public enum PersistenceContainer: Sendable {
    /// iOS / 小组件：`group.` 前缀。Mac 原生壳必须用 Team ID 前缀，见 `appGroupIdentifier`。
    public static let iOSAppGroupIdentifier = "group.com.zhechengqi.tollcat"

    public static var appGroupIdentifier: String {
        #if os(macOS)
        macAppGroupIdentifier
        #else
        iOSAppGroupIdentifier
        #endif
    }

    #if os(macOS)
    /// 原生 Mac 的 App Group 是 `$(TeamIdentifierPrefix)com.zhechengqi.tollcat`。
    /// iOS 风格的 `group.` 容器在开发期 Widget 读不到。
    private static var macAppGroupIdentifier: String {
        let prefix = Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? String ?? ""
        return "\(prefix)com.zhechengqi.tollcat"
    }
    #endif

    /// App Group 里 store 文件的名字。改名等于弃库重建，别随手动。
    private static let configurationName = "TollCat"

    public static let schema = Schema(versionedSchema: TollCatSchemaV1.self)

    public static func appGroupContainerURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    /// 磁盘上**已经有**一份库。
    ///
    /// 「建库失败」有两种，处理方式相反：没有 App Group entitlement（未签名的
    /// 测试宿主、刚换过 group id）时退内存是对的，本来就没有数据；而库文件在、
    /// 却打不开（迁移推不动、文件损坏）时退内存是**灾难**——用户看到的是一个空
    /// App，会以为数据没了，然后重新接一遍，而这一遍写下去的东西退出就没。
    /// 两者必须分开，见 `PersistenceBootstrap`。
    public static func storeFileExists() -> Bool {
        guard appGroupContainerURL() != nil else { return false }
        return FileManager.default.fileExists(atPath: makeConfiguration().url.path)
    }

    /// 生产配置走 App Group，不进 iCloud / CloudKit。测试和 Preview 用内存库。
    public static func makeConfiguration(inMemory: Bool = false) -> ModelConfiguration {
        if inMemory {
            return ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        }
        return ModelConfiguration(
            configurationName,
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier),
            cloudKitDatabase: .none
        )
    }

    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            migrationPlan: TollCatMigrationPlan.self,
            configurations: [makeConfiguration(inMemory: inMemory)]
        )
    }
}
