import Foundation
import SwiftData
import MeterCore

/// 只读 App Group 里主 App 写下的 store。Widget 没有别的数据来源。
public enum SharedStoreReader: Sendable {
    /// `now` **没有默认值**。有默认值的话调用方一疏忽就落回墙钟，而这一层折的是
    /// 「本月至今」——Widget 的时间线本来就要按未来某一刻预渲染，用错时刻不会报错，
    /// 只会让主屏上的数字对不上 App 里的。
    public static func load(
        from container: ModelContainer,
        calendar: Calendar,
        now: Date
    ) throws -> SharedStoreContents {
        let context = ModelContext(container)

        let subscriptionRecords = try context.fetch(FetchDescriptor<SubscriptionRecord>())
        let subscriptions = subscriptionRecords.compactMap { record in
            try? record.toDomain(calendar: calendar)
        }

        let configRecords = try context.fetch(FetchDescriptor<ProviderConfigRecord>())
        let membershipRecords = try context.fetch(FetchDescriptor<ProviderMembershipRecord>())
        // 结束过的接入也算「认得出来的账号」：它的历史快照必须留在集合里，
        // 否则过去几个月的柱子会跟着塌。「本月不再计入」那一步由折算侧的
        // `endedAccounts` 负责（`DashboardContentsBuilder` 从 connections 推）。
        let knownIDs = Set(
            configRecords.filter(\.isEnabled).compactMap { try? $0.domainAccountID() }
        )
        let liveRecords = configRecords.filter { $0.isEnabled && $0.archivedAt == nil }
        let liveIDs = Set(liveRecords.compactMap { try? $0.domainAccountID() })
        // 有金额当且仅当认得出账号：真删掉接入后历史行还在库里，展示层不能再拿来加总。
        // 未盖章的行丢掉，不当 $0。订阅列表不过滤接入集——无主仍进 Widget 合计。
        // 读模型直接从库里取——它和主 App 写的是同一份 App Group 容器。
        // 「有金额当且仅当认得出账号」那条规矩在这里变成对行的筛选。
        var ledger = (try? MonthlyLedgerStore.view(subscriptions: subscriptions, calendar: calendar, in: context))
            ?? LedgerView(subscriptions: subscriptions)
        // 库里还没有账本、但已经有读数：当场折一份。
        //
        // 折叠归主 App 负责，可它是异步的——主 App 刚落完盘就喊 Widget 重载的话，
        // 中间有一小段账本还没写好。少了这个兜底，主屏会在那一瞬变成空态，
        // 而"偶尔空一下"是最难复现、也最难被相信的那种 bug。
        //
        // **快照只在这条路上读。**它是全库最大的一张表，每条还要解三个 JSON blob，
        // 而 Widget 每次刷时间线都要走一遍这里——放在外面就等于让小组件的代价
        // 跟着刷新次数一直涨，为的却是一段几乎从不发生的窗口。
        if ledger.rollups.isEmpty, let owned = ownedSnapshots(knownIDs: knownIDs, calendar: calendar, in: context) {
            ledger = LedgerView(
                rollups: LedgerSelfCheck.foldAll(
                    snapshots: owned,
                    now: now,
                    calendar: calendar
                ),
                latest: AccountLatest
                    .reduceAll(snapshots: owned, calendar: calendar)
                    .values
                    .sorted { $0.accountID.rawValue.uuidString < $1.accountID.rawValue.uuidString },
                subscriptions: subscriptions
            )
        }
        let view = LedgerView(
            rollups: ledger.rollups.filter { knownIDs.contains($0.accountID) },
            latest: ledger.latest.filter { knownIDs.contains($0.accountID) },
            subscriptions: subscriptions
        )
        // 「上次刷新」只看还在跑的那几份：结束掉的那份最后一次成功是历史，
        // 拿它当作 widget 的新鲜度会让主屏显示一个永远不再更新的时间。
        let lastSuccessfulRefreshAt = [
            view.latest.filter { liveIDs.contains($0.accountID) }.map(\.fetchedAt).max(),
            liveRecords.compactMap(\.lastSuccessfulRefreshAt).max(),
        ].compactMap { $0 }.max()

        let preferences = (try? AppPreferencesRecord.load(from: context)) ?? .default
        return SharedStoreContents(
            view: view,
            subscriptions: subscriptions,
            lastSuccessfulRefreshAt: lastSuccessfulRefreshAt,
            connectedAccountCount: liveIDs.count,
            connectedVendorCount: membershipRecords.count,
            displayCurrency: preferences.displayCurrency,
            includesSubscriptions: preferences.dashboardFilter.includesSubscriptions,
            connections: configRecords.compactMap { $0.connectionState(calendar: calendar) },
            layout: preferences.dashboardLayout
        )
    }

    /// 兜底那条路要的读数：认得出账号的那些。
    ///
    /// **有一行解不出来就整个作废（回 nil）。**这条路本来就只服务
    /// 「账本还没写好」那一小段窗口，缺几行折出来的是一个偏低的总数——
    /// 而偏低的总数在主屏上和真的花了那么多长得一模一样。
    /// 宁可这一瞬什么都不显示，也不能显示一个错的数。
    private static func ownedSnapshots(
        knownIDs: Set<AccountID>,
        calendar: Calendar,
        in context: ModelContext
    ) -> [Snapshot]? {
        let records = (try? context.fetch(
            FetchDescriptor<SnapshotRecord>(sortBy: [SortDescriptor(\.fetchedAt)])
        )) ?? []
        var owned: [Snapshot] = []
        owned.reserveCapacity(records.count)
        for record in records {
            guard let snapshot = try? record.toDomain(calendar: calendar) else { return nil }
            guard let id = snapshot.accountID, knownIDs.contains(id) else { continue }
            owned.append(snapshot)
        }
        return owned.isEmpty ? nil : owned
    }
}
