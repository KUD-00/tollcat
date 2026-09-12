import Foundation
import SwiftData
import MeterCore

/// 快照日志的**读口**。整个 App 里只有这里会把 `SnapshotRecord` 变成 `Snapshot`。
///
/// ## 为什么日志不再住在内存里
///
/// 以前 `DashboardModel` 攥着一份全量 `[Snapshot]`：每次写库全表重读、每条解三个
/// JSON blob，内存和读的代价都正比于刷新次数——而账本这一层存在的理由恰恰是把
/// 代价和刷新次数脱钩。日志留在库里，谁要问什么就按范围取：折账本取一个账号的，
/// 详情页取几个账号最近一段的，指纹只取几列标量。没有人需要整份。
///
/// `calendar` 是**读日历**：日表的键存的是日历上的那一天（`DayKey`），还原成零点
/// 那一刻要知道用哪本日历。传此刻界面用的那本，读出来就是此刻的那一天。
public enum SnapshotLog: Sendable {
    /// 按账号（可选）和时间下界取读数，按 `fetchedAt` 升序。
    ///
    /// `accountIDs` 给 nil 取全部**盖过章**的行。解不出来的行跳过——这条路服务折叠和
    /// 详情图，一行坏掉不该让整屏空掉；坏行本身在开发页的 dump 里能看见。
    public static func snapshots(
        accountIDs: Set<AccountID>?,
        since: Date? = nil,
        calendar: Calendar,
        in context: ModelContext
    ) throws -> [Snapshot] {
        var descriptor = FetchDescriptor<SnapshotRecord>(
            sortBy: [SortDescriptor(\.fetchedAt)]
        )
        descriptor.predicate = predicate(accountIDs: accountIDs, since: since)
        return try context.fetch(descriptor).compactMap { record in
            guard let snapshot = try? record.toDomain(calendar: calendar) else { return nil }
            // 未盖章的行不进任何计算：不当 $0，也不当别人的。
            guard let id = snapshot.accountID else { return nil }
            if let accountIDs, !accountIDs.contains(id) { return nil }
            return snapshot
        }
    }

    /// 指纹要的那几列。**不读 blob**——这是它便宜到能每次开门都算一遍的原因。
    ///
    /// `calendar` 只服务旧行：账期端点的分量列是后加的，加它之前写下的行
    /// 只有瞬间，得按读日历翻回分量才能和新行落在同一把尺上。
    public static func fingerprintEntries(
        accountIDs: Set<AccountID>?,
        calendar: Calendar,
        in context: ModelContext
    ) throws -> [LedgerFingerprint.Entry] {
        var descriptor = FetchDescriptor<SnapshotRecord>()
        descriptor.predicate = predicate(accountIDs: accountIDs, since: nil)
        descriptor.propertiesToFetch = [
            \.accountIDRaw, \.providerIDRaw, \.kindRaw, \.sourceRaw,
            \.fetchedAt, \.periodStart, \.periodEnd,
            \.periodStartDay, \.periodEndDay,
            \.currentSpendUSD, \.balanceUSD, \.committedMonthlyUSD,
            \.chargeDayOfMonth, \.freeQuotaUsedRatio, \.convertedCurrency,
        ]
        return try context.fetch(descriptor).compactMap { record in
            guard let uuid = UUID(uuidString: record.accountIDRaw) else { return nil }
            if let accountIDs, !accountIDs.contains(AccountID(rawValue: uuid)) { return nil }
            return LedgerFingerprint.Entry(
                accountID: uuid,
                providerID: record.providerIDRaw,
                kind: record.kindRaw,
                source: record.sourceRaw,
                fetchedAt: record.fetchedAt,
                periodStart: DayKey(storageString: record.periodStartDay)
                    ?? DayKey(record.periodStart, calendar: calendar),
                periodEnd: DayKey(storageString: record.periodEndDay)
                    ?? DayKey(record.periodEnd, calendar: calendar),
                chargeDayOfMonth: record.chargeDayOfMonth,
                freeQuotaUsedRatio: record.freeQuotaUsedRatio,
                hasCurrentSpend: record.currentSpendUSD != nil,
                hasBalance: record.balanceUSD != nil,
                hasCommitted: record.committedMonthlyUSD != nil,
                hasConverted: record.convertedCurrency != nil
            )
        }
    }

    /// 下界**之前**最近的那一条读数。折叠的下界会切掉更早的历史，而
    /// 「月初余额锚点」「最近一条带明细的」各自只用得上一条——补的就是这一条。
    /// 解不出来的行按「没有」处理，和 `snapshots(...)` 同一口径。
    public static func latestBefore(
        accountID: AccountID,
        before: Date,
        calendar: Calendar,
        in context: ModelContext
    ) throws -> Snapshot? {
        let raw = accountID.rawValue.uuidString
        var descriptor = FetchDescriptor<SnapshotRecord>(
            predicate: #Predicate { $0.accountIDRaw == raw && $0.fetchedAt < before },
            sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else { return nil }
        guard let snapshot = try? record.toDomain(calendar: calendar) else { return nil }
        return snapshot.accountID == nil ? nil : snapshot
    }

    public static func count(in context: ModelContext) throws -> Int {
        try context.fetchCount(FetchDescriptor<SnapshotRecord>())
    }

    /// 这个账号有没有过**读到数**的读数。刷新失败时决定标「陈旧」还是「失败」。
    ///
    /// 一次带 predicate 的 `fetchCount`，**不解 blob、不建域对象**。以前它是
    /// 「把这家的全部历史解出来再 `contains`」——每次刷新每家都要问一次，
    /// 代价正比于这个账号刷过多少回，而答案只是一个 Bool。
    ///
    /// predicate 是 `hasBillableMetrics` 的**列级近似**，而且比它**宽**：不看 kind，
    /// 任何一格有值就算。这里要的语义只是「有没有过任何读数」，宽一点无害——
    /// 窄了才会出事（把读到过数的账号标成「取数失败」）。真按 kind 判的地方
    /// 仍然只有 `Snapshot.hasBillableMetrics` 一处。
    public static func hasBillableReading(
        accountID: AccountID,
        in context: ModelContext
    ) throws -> Bool {
        let raw = accountID.rawValue.uuidString
        // 拆成两条再各数一次，不是为了好看：五个 `!= nil` 写在一条 `#Predicate` 里
        // 会让类型检查器爆炸（编译超时）。两次 `fetchCount` 走的都是
        // `accountIDRaw` 那个索引，比解一遍这家的全部历史便宜得多。
        let money = #Predicate<SnapshotRecord> { record in
            record.accountIDRaw == raw
                && (record.currentSpendUSD != nil
                    || record.balanceUSD != nil
                    || record.committedMonthlyUSD != nil)
        }
        if try context.fetchCount(FetchDescriptor<SnapshotRecord>(predicate: money)) > 0 {
            return true
        }
        let rest = #Predicate<SnapshotRecord> { record in
            record.accountIDRaw == raw
                && (record.freeQuotaUsedRatio != nil || record.dailySpendData != nil)
        }
        return try context.fetchCount(FetchDescriptor<SnapshotRecord>(predicate: rest)) > 0
    }

    /// 谁的读数在库里（盖过章的账号）。
    public static func accountIDs(in context: ModelContext) throws -> Set<AccountID> {
        var descriptor = FetchDescriptor<SnapshotRecord>()
        descriptor.propertiesToFetch = [\.accountIDRaw]
        return Set(
            try context.fetch(descriptor).compactMap { UUID(uuidString: $0.accountIDRaw).map(AccountID.init(rawValue:)) }
        )
    }

    private static func predicate(
        accountIDs: Set<AccountID>?,
        since: Date?
    ) -> Predicate<SnapshotRecord>? {
        let raws = accountIDs.map { Array($0.map(\.rawValue.uuidString)) }
        switch (raws, since) {
        case (nil, nil):
            return nil
        case (let raws?, nil):
            return #Predicate { raws.contains($0.accountIDRaw) }
        case (nil, let since?):
            return #Predicate { $0.fetchedAt >= since }
        case (let raws?, let since?):
            return #Predicate { raws.contains($0.accountIDRaw) && $0.fetchedAt >= since }
        }
    }
}
