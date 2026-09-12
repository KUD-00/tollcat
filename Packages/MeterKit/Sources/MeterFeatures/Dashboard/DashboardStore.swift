import Foundation
import SwiftData
import MeterCore
import MeterPersistence
import MeterProviders

/// 仪表的 SwiftData 读写层。零 `@Observable` 状态：每个方法自己开 context、
/// 自己 save。「写完之后仪表要重读、Widget 要重画」是 `DashboardModel` 的事，
/// 这里不碰任何展示状态。
///
/// **读一律 `throws`，不在这一层吞。** 以前这里 `try? … ?? []`：一次 fetch 失败
/// 读出来是「没有服务」「没有订阅」，上面那层再拿这份空的去筛快照、折账本，
/// 一个读错误在三层里被三次转成「空」。读失败长什么样由 `DashboardModel` 一处决定
/// （保留上一份 + 亮 `didFailToRead`），这里只如实抛。
///
/// 快照日志不从这里读——那是 `LedgerCache` / `SnapshotLog` 的事。
@MainActor
struct DashboardStore {
    let container: ModelContainer
    let credentials: any CredentialStore

    // MARK: - 读

    /// `calendar` 是读日历：结束那一天存的是分量，还原成哪一刻要按它算
    /// （见 `ProviderConfigRecord.archivedDay`）。
    func connectionStates(calendar: Calendar) throws -> [ProviderConnectionState] {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<ProviderConfigRecord>())
        // accountID 解不出的坏行丢掉，和快照对 toDomain 失败的口径一致。
        return records.compactMap { $0.connectionState(calendar: calendar) }
    }

    func memberships() throws -> [ProviderMembership] {
        let context = ModelContext(container)
        return try ProviderMembershipStore.all(in: context)
    }

    func subscriptionItems(now: Date, calendar: Calendar) throws -> [ManualSubscriptionItem] {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<SubscriptionRecord>())
        // 解不出来的订阅**抛**，不是少一行：文件头刚说完「读一律 throws，不在这一层吞」。
        // 一条 `periodRaw` 不认识的订阅悄悄消失，界面上就是少了那一行、总数少一笔，
        // 而且完全正常。
        return try records.map { record in
            let domain = try record.toDomain(calendar: calendar)
            return ManualSubscriptionItem(
                id: record.persistentModelID,
                name: domain.name,
                amount: domain.amount,
                period: domain.period,
                anchorDate: domain.anchorDate,
                endDate: domain.endDate,
                hasEnded: domain.hasEnded(by: now, calendar: calendar),
                accountID: domain.accountID,
                providerID: domain.providerID,
                quantity: domain.quantity
            )
        }
    }

    func fetchSubscriptions(calendar: Calendar) throws -> [MonthlySubscription] {
        let context = ModelContext(container)
        // 同上：坏行抛出去，让 `DashboardModel` 一处决定「读不出来」长什么样。
        return try context.fetch(FetchDescriptor<SubscriptionRecord>()).map { record in
            try record.toDomain(calendar: calendar)
        }
    }

    // MARK: - 写

    /// 写失败**抛**。吞掉的话开关在界面上已经翻过去了（内存副本变了），
    /// 而磁盘上还是旧的——退出再进来它自己弹回来，没有任何提示。
    func setIncludeInGlobalRefresh(_ enabled: Bool, for accountID: AccountID) throws {
        let context = ModelContext(container)
        _ = try ProviderConfigStore.update(
            accountID: accountID,
            ProviderConfigUpdate(includeInGlobalRefresh: .some(.some(enabled))),
            in: context
        )
        try context.save()
    }

    func applyConnection(
        accountID: AccountID,
        providerID: ProviderID,
        nickname: String?,
        identityHint: String?,
        remoteIdentityFingerprint: String?,
        fields: [String: String],
        snapshots incoming: [Snapshot],
        mode: ConnectionWriteMode,
        calendar: Calendar
    ) throws {
        let context = ModelContext(container)
        let lastSuccess = incoming.last(where: \.hasBillableMetrics)?.fetchedAt
            ?? incoming.last?.fetchedAt
        switch mode {
        case .create:
            let reference = "credential.\(accountID.rawValue.uuidString)"
            try credentials.save(StoredCredentialFields.encode(fields), reference: reference)
            let include = !(ProviderCatalog.descriptor(id: providerID)?.costsMoneyToRefresh ?? false)
            _ = try ProviderConfigStore.insert(
                accountID: accountID,
                providerID: providerID,
                nickname: nickname,
                identityHint: identityHint,
                remoteIdentityFingerprint: remoteIdentityFingerprint,
                isEnabled: true,
                credentialReference: reference,
                includeInGlobalRefresh: include,
                usesInbox: false,
                inboxIngestKeyID: nil,
                lastSuccessfulRefreshAt: lastSuccess,
                placement: .afterSiblings,
                in: context
            )
            _ = try ProviderMembershipStore.ensure(providerID, in: context)
        case .rotate:
            guard let existing = try connectionStates(calendar: calendar)
                .first(where: { $0.accountID == accountID })
            else {
                throw ProviderConfigStoreError.accountNotFound(accountID)
            }
            try credentials.save(StoredCredentialFields.encode(fields), reference: existing.credentialReference)
            _ = try ProviderConfigStore.update(
                accountID: accountID,
                ProviderConfigUpdate(
                    nickname: nickname.map { .some($0) },
                    identityHint: .some(identityHint),
                    remoteIdentityFingerprint: .some(remoteIdentityFingerprint),
                    lastSuccessfulRefreshAt: lastSuccess
                ),
                in: context
            )
        }
        for snapshot in incoming {
            try SnapshotWriter.apply(snapshot, to: context, calendar: calendar)
        }
        try context.save()
    }

    /// 接入一份走信箱的账号。调用方已经生成 AccountID；本函数禁止 UUID()。
    func applyInboxConnection(
        accountID: AccountID,
        providerID: ProviderID,
        nickname: String?,
        identityHint: String?,
        ingestKeyID: String,
        credentialReference: String
    ) throws {
        try credentials.save(StoredCredentialFields.encode([:]), reference: credentialReference)

        let context = ModelContext(container)
        _ = try ProviderConfigStore.insert(
            accountID: accountID,
            providerID: providerID,
            nickname: nickname,
            identityHint: identityHint,
            remoteIdentityFingerprint: nil,
            isEnabled: true,
            credentialReference: credentialReference,
            includeInGlobalRefresh: true,
            usesInbox: true,
            inboxIngestKeyID: ingestKeyID,
            lastSuccessfulRefreshAt: nil,
            placement: .afterSiblings,
            in: context
        )
        _ = try ProviderMembershipStore.ensure(providerID, in: context)
        try context.save()
    }

    /// 把刚签的投递 key 接到已经手填过的那份用量上，不要再开一份账号。
    func attachInbox(accountID: AccountID, ingestKeyID: String) throws {
        let context = ModelContext(container)
        _ = try ProviderConfigStore.update(
            accountID: accountID,
            ProviderConfigUpdate(
                includeInGlobalRefresh: true,
                usesInbox: true,
                inboxIngestKeyID: .some(ingestKeyID)
            ),
            in: context
        )
        try context.save()
    }

    /// 手填某个月的花费。每次写一条 Snapshot；合计取该月最新。没有用量身份就建一份：
    /// 没有 API，也不走信箱，不参与刷新。
    /// 返回落到的 AccountID（新建时是新生成的那份）。
    func applyManualUsage(
        providerID: ProviderID,
        amount: Money,
        to accountID: AccountID?,
        periodYear: Int,
        periodMonth: Int,
        now: Date,
        calendar: Calendar
    ) throws -> AccountID {
        let year = periodYear
        let month = periodMonth
        let context = ModelContext(container)
        let id: AccountID
        if let accountID {
            id = accountID
            _ = try ProviderConfigStore.update(
                accountID: id,
                ProviderConfigUpdate(lastSuccessfulRefreshAt: now),
                in: context
            )
        } else {
            id = AccountID(rawValue: UUID())
            let reference = "credential.\(id.rawValue.uuidString)"
            try credentials.save(StoredCredentialFields.encode([:]), reference: reference)
            _ = try ProviderConfigStore.insert(
                accountID: id,
                providerID: providerID,
                nickname: nil,
                identityHint: nil,
                remoteIdentityFingerprint: nil,
                isEnabled: true,
                credentialReference: reference,
                includeInGlobalRefresh: false,
                usesInbox: false,
                inboxIngestKeyID: nil,
                lastSuccessfulRefreshAt: now,
                placement: .afterSiblings,
                in: context
            )
            _ = try ProviderMembershipStore.ensure(providerID, in: context)
        }
        // 手填只有 `currentSpendUSD` 一格，装不下的 kind 一律降成 `.usage`——
        // 照目录原样落 `.subscription`（Notion / Figma / Slack / Linear）
        // 会写出一条永远不算数的快照：保存成功，仪表显示 $0 并标「取数失败」。
        // 规则在 `ProviderKind.manualEntryKind`，信箱那条路问的是同一份。
        let kind = (ProviderCatalog.descriptor(id: providerID)?.kind ?? .usage).manualEntryKind
        let record = try ManualUsageStore.upsert(
            accountID: id,
            providerID: providerID,
            periodYear: year,
            periodMonth: month,
            amount: amount,
            enteredAt: now,
            kind: kind,
            in: context
        )
        try SnapshotWriter.apply(record.snapshot(calendar: calendar), to: context, calendar: calendar)
        try context.save()
        return id
    }

    func updateAccountNickname(_ nickname: String?, for accountID: AccountID) throws {
        let context = ModelContext(container)
        _ = try ProviderConfigStore.update(
            accountID: accountID,
            ProviderConfigUpdate(nickname: .some(nickname)),
            in: context
        )
        try context.save()
    }

    func addMembership(_ providerID: ProviderID) throws {
        let context = ModelContext(container)
        _ = try ProviderMembershipStore.ensure(providerID, in: context)
        try context.save()
    }

    /// 结束这家：接入归档、订阅停在本月，成员关系和历史全留着。
    ///
    /// **这不是删除。** 过去几个月的账单是拿当前这几张表现算出来的
    /// （`MonthSpendHistoryCalculator` 逐月重跑折算），把行删掉就等于把
    /// 真付过的钱从历史里抹掉。结束只是给每条记录盖一个终点，
    /// 于是「本月」不再算它，而过去的每一个月照旧算得出来。
    ///
    /// 信箱投递 key 的吊销是调用方的事（要走网络，且失败只记日志）。
    func archiveMembership(_ providerID: ProviderID, at date: Date, calendar: Calendar) throws {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<ProviderConfigRecord>())
        for record in records where record.providerID == providerID {
            try record.archive(at: date, calendar: calendar, credentials: credentials)
        }
        let subscriptions = try context.fetch(FetchDescriptor<SubscriptionRecord>())
        for subscription in subscriptions where subscription.providerIDRaw == providerID.rawValue {
            Self.end(subscription, at: date, calendar: calendar)
        }
        try context.save()
    }

    /// 真删：连历史快照一起。设置页那条「清空本机《服务名》相关账单数据」走这里。
    ///
    /// 快照必须跟着走。留下来它们就是孤儿——`accountID` 找不到对应的接入行，
    /// 展示层认不出属于谁，既进不了总额也进不了历史服务，只是白占库。
    func purgeMembershipRecords(_ providerID: ProviderID) throws {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<ProviderConfigRecord>())
        var purgedAccounts: Set<String> = []
        for record in records where record.providerID == providerID {
            purgedAccounts.insert(record.accountIDRaw)
            try record.deleteTogetherWithCredentials(in: context, credentials: credentials)
        }
        let subscriptions = try context.fetch(FetchDescriptor<SubscriptionRecord>())
        for subscription in subscriptions where subscription.providerIDRaw == providerID.rawValue {
            context.delete(subscription)
        }
        for snapshot in try context.fetch(FetchDescriptor<SnapshotRecord>())
        where snapshot.providerIDRaw == providerID.rawValue
            || purgedAccounts.contains(snapshot.accountIDRaw) {
            context.delete(snapshot)
        }
        // 账本行跟着快照走，**同一个 save**：中间那一帧不能还显示着这家的钱。
        MonthlyLedgerStore.removeWithoutSaving(
            accountIDs: Set(purgedAccounts.compactMap { UUID(uuidString: $0).map(AccountID.init(rawValue:)) }),
            in: context
        )
        try ManualUsageStore.delete(providerID: providerID, in: context)
        try ProviderMembershipStore.remove(providerID, in: context)
        try context.save()
    }

    /// 结束一份用量身份。凭据删掉，行和快照留着。同上，投递 key 的吊销在调用方。
    func archiveConnectionRecord(accountID: AccountID, at date: Date, calendar: Calendar) throws {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<ProviderConfigRecord>())
        let target = accountID.rawValue.uuidString
        guard let record = records.first(where: { $0.accountIDRaw == target }) else { return }
        try record.archive(at: date, calendar: calendar, credentials: credentials)
        try context.save()
    }

    func applySubscription(_ subscription: MonthlySubscription, calendar: Calendar) throws {
        let context = ModelContext(container)
        context.insert(SubscriptionRecord(domain: subscription, calendar: calendar))
        try context.save()
    }

    func updateSubscription(
        id: PersistentIdentifier,
        _ subscription: MonthlySubscription,
        calendar: Calendar
    ) throws {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<SubscriptionRecord>())
        guard let record = records.first(where: { $0.persistentModelID == id }) else { return }
        record.apply(domain: subscription, calendar: calendar)
        try context.save()
    }

    /// 真删。**会改写历史**——这笔钱从过去每一个月里一起消失，
    /// 所以界面上它只该是「我根本录错了」那条路，不是「我不订了」。
    func removeSubscription(id: PersistentIdentifier) throws {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<SubscriptionRecord>())
        guard let record = records.first(where: { $0.persistentModelID == id }) else { return }
        context.delete(record)
        try context.save()
    }

    private static func end(_ record: SubscriptionRecord, at date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        record.endYear = components.year
        record.endMonth = components.month
        record.endDay = components.day
    }

}
