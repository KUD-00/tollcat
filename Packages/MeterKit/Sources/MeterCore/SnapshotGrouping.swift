import Foundation

/// 按账号收齐的历史快照。同厂商不同账号绝不相交。
/// `ordered` 保证非空且按 fetchedAt 升序——空组根本建不出来。
struct AccountSnapshots {
    var id: AccountID
    var providerID: ProviderID
    var ordered: [Snapshot]
}

/// 三个计算器共用的分组入口，别再各写各的。
enum SnapshotGrouping {
    /// 按账号保序分组。没盖章（`accountID == nil`）的快照被跳过并如实报告，
    /// 要不要把这当成事故由调用方决定。
    static func byAccount(_ snapshots: [Snapshot]) -> (groups: [AccountSnapshots], skippedUnstamped: Bool) {
        var order: [AccountID] = []
        var buckets: [AccountID: [Snapshot]] = [:]
        var skippedUnstamped = false
        for snapshot in snapshots {
            guard let accountID = snapshot.accountID else {
                skippedUnstamped = true
                continue
            }
            if buckets[accountID] == nil {
                order.append(accountID)
            }
            buckets[accountID, default: []].append(snapshot)
        }
        let groups = order.compactMap { id -> AccountSnapshots? in
            guard let bucket = buckets[id], let first = bucket.first else { return nil }
            return AccountSnapshots(
                id: id,
                providerID: first.providerID,
                ordered: bucket.sorted { $0.fetchedAt < $1.fetchedAt }
            )
        }
        return (groups, skippedUnstamped)
    }
}
