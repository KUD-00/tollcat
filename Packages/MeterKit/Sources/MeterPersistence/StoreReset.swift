import Foundation
import SwiftData

/// 设置页「清除全部数据」。普通路径里 Snapshot 永不删除；这是用户明确要抹掉本机记录的出口。
public enum StoreReset: Sendable {
    /// 清除时保留的模型。打赏记录不是账单：清除凭据不该抹掉已经付过的感谢，
    /// 也别把还没发出去的留言一起丢掉。
    static let preservedModels: [any PersistentModel.Type] = [
        TipRecord.self,
    ]

    /// 清除时删掉的模型。往 `PersistenceContainer.schema` 加模型时必须把它归进
    /// 这两张名单之一——`StoreResetTests` 会拿 schema 对账，漏归就红。
    static let purgedModels: [any PersistentModel.Type] = [
        ProviderConfigRecord.self,
        ProviderMembershipRecord.self,
        SnapshotRecord.self,
        SubscriptionRecord.self,
        ManualUsageRecord.self,
        AppPreferencesRecord.self,
        // 账本是快照的派生物。快照都清了还留着它，界面上会出现一笔查无源头的钱。
        MonthlyRollupRecord.self,
        AccountLatestRecord.self,
        // 账本的戳必须和账本行一起走。留着它，下一次读会拿一个对不上的指纹去比，
        // 结论仍然是"重折"，但那是碰巧对——戳和行本来就该同生共死。
        LedgerStampRecord.self,
    ]

    /// 两张名单必须恰好盖住整个 schema。
    static var unclassifiedModelNames: Set<String> {
        let classified = Set((purgedModels + preservedModels).map { String(describing: $0) })
        let actual = Set(PersistenceContainer.schema.entities.map(\.name))
        return actual.symmetricDifference(classified)
    }

    public static func clearAll(
        container: ModelContainer,
        credentials: any CredentialStore
    ) throws {
        let context = ModelContext(container)

        for record in try context.fetch(FetchDescriptor<ProviderConfigRecord>()) {
            try credentials.delete(reference: record.credentialReference)
        }

        // 按 reference 删完再清整个 service，避免历史 orphan 留在 Keychain。
        try credentials.deleteAll()

        for model in purgedModels {
            try purge(model, in: context)
        }

        try context.save()
    }

    private static func purge<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws {
        for record in try context.fetch(FetchDescriptor<T>()) {
            context.delete(record)
        }
    }
}
