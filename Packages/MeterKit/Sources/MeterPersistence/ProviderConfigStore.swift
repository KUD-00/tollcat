import Foundation
import SwiftData
import MeterCore

/// 接入记录只有这一条写入路径。向导保存和演示种子都走这里。
public enum ProviderConfigStore: Sendable {
    @discardableResult
    public static func insert(
        accountID: AccountID,
        providerID: ProviderID,
        nickname: String?,
        identityHint: String?,
        remoteIdentityFingerprint: String?,
        isEnabled: Bool,
        /// 已经结束的接入。迁移导入是唯一会带着它进来的路：包里存的是瞬间，
        /// 落到本机要按本机日历重记「结束那一天」，两种形状由 `ArchivedStamp` 一起算。
        archived: ArchivedStamp? = nil,
        credentialReference: String,
        includeInGlobalRefresh: Bool?,
        usesInbox: Bool?,
        inboxIngestKeyID: String?,
        lastSuccessfulRefreshAt: Date?,
        placement: AccountInsertPlacement,
        in context: ModelContext
    ) throws -> ProviderConfigRecord {
        let existing = try context.fetch(FetchDescriptor<ProviderConfigRecord>())
        let sortIndex = try resolveSortIndex(
            providerID: providerID,
            placement: placement,
            existing: existing
        )
        let record = ProviderConfigRecord(
            accountID: accountID,
            providerID: providerID,
            nickname: nickname,
            identityHint: identityHint,
            remoteIdentityFingerprint: remoteIdentityFingerprint,
            isEnabled: isEnabled,
            archived: archived,
            sortIndex: sortIndex,
            lastSuccessfulRefreshAt: lastSuccessfulRefreshAt,
            credentialReference: credentialReference,
            includeInGlobalRefresh: includeInGlobalRefresh,
            usesInbox: usesInbox,
            inboxIngestKeyID: inboxIngestKeyID
        )
        context.insert(record)
        return record
    }

    @discardableResult
    public static func update(
        accountID: AccountID,
        _ fields: ProviderConfigUpdate,
        in context: ModelContext
    ) throws -> ProviderConfigRecord {
        let target = accountID.rawValue.uuidString
        var descriptor = FetchDescriptor<ProviderConfigRecord>(
            predicate: #Predicate { $0.accountIDRaw == target }
        )
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else {
            throw ProviderConfigStoreError.accountNotFound(accountID)
        }
        if let nickname = fields.nickname {
            record.nickname = nickname
        }
        if let identityHint = fields.identityHint {
            record.identityHint = identityHint
        }
        if let remoteIdentityFingerprint = fields.remoteIdentityFingerprint {
            record.remoteIdentityFingerprint = remoteIdentityFingerprint
        }
        if let isEnabled = fields.isEnabled {
            record.isEnabled = isEnabled
        }
        if let lastSuccessfulRefreshAt = fields.lastSuccessfulRefreshAt {
            record.lastSuccessfulRefreshAt = lastSuccessfulRefreshAt
        }
        if let includeInGlobalRefresh = fields.includeInGlobalRefresh {
            record.includeInGlobalRefresh = includeInGlobalRefresh
        }
        if let usesInbox = fields.usesInbox {
            record.usesInbox = usesInbox
        }
        if let inboxIngestKeyID = fields.inboxIngestKeyID {
            record.inboxIngestKeyID = inboxIngestKeyID
        }
        return record
    }

    private static func resolveSortIndex(
        providerID: ProviderID,
        placement: AccountInsertPlacement,
        existing: [ProviderConfigRecord]
    ) throws -> Int {
        switch placement {
        case .exact(let value):
            return value
        case .afterSiblings:
            let siblings = existing.filter { $0.providerID == providerID }
            if siblings.isEmpty {
                let maxIndex = existing.map(\.sortIndex).max() ?? -1
                return maxIndex + 1
            }
            let newIndex = (siblings.map(\.sortIndex).max() ?? -1) + 1
            for record in existing where record.sortIndex >= newIndex {
                record.sortIndex += 1
            }
            return newIndex
        }
    }
}
