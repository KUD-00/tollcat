import Foundation
import SwiftData
import MeterCore

/// Snapshot 只有这一条写入路径。刷新和首次接入回填都走这里，种子不许另开一条。
///
/// `calendar` 是**落盘日历**：日表的键存的是日历上的那一天，不是时刻（见 `DayKey`），
/// 所以把 `Date` 翻成年月日要知道用哪本日历——和读它的那本一致，读出来就是同一天。
public enum SnapshotWriter: Sendable {
    /// save 失败原样抛出。折成 false 会让「没写进去」混进「没什么可写」，
    /// 刷新被记成成功、重启后又吐回旧数字。
    @discardableResult
    public static func persist(
        _ snapshot: Snapshot,
        into container: ModelContainer,
        calendar: Calendar
    ) throws -> Bool {
        try persist(contentsOf: [snapshot], into: container, calendar: calendar)
    }

    /// 刷新路径用：`context.save()` 在主线程上按家逐条做，够把好几帧吞掉。
    @discardableResult
    public static func persistOffMain(
        _ snapshot: Snapshot,
        into container: ModelContainer,
        calendar: Calendar
    ) async throws -> Bool {
        try await Task.detached(priority: .userInitiated) {
            try persist(snapshot, into: container, calendar: calendar)
        }.value
    }

    @discardableResult
    public static func persist(
        contentsOf snapshots: [Snapshot],
        into container: ModelContainer,
        calendar: Calendar
    ) throws -> Bool {
        let context = ModelContext(container)
        var wrote = false
        for snapshot in snapshots {
            if try apply(snapshot, to: context, calendar: calendar) {
                wrote = true
            }
        }
        try context.save()
        return wrote
    }

    /// `accountID == nil` 拒绝写入。DEBUG 下立刻炸，免得漏盖章悄悄丢掉读数。
    ///
    /// 编码失败（日表 / 钱包 / 明细）和回写「上次成功刷新」失败都**原样抛**：
    /// 前者会落一条少了三段的读数，后者会让那家的时间停在上一次——两件事在
    /// 界面上都完全正常，只是数字不对。
    @discardableResult
    public static func apply(_ snapshot: Snapshot, to context: ModelContext, calendar: Calendar) throws -> Bool {
        guard snapshot.accountID != nil else {
            #if DEBUG
            preconditionFailure("unstamped Snapshot")
            #else
            return false
            #endif
        }
        context.insert(try SnapshotRecord(domain: snapshot, calendar: calendar))
        guard snapshot.hasBillableMetrics, let accountID = snapshot.accountID else { return true }
        let target = accountID.rawValue.uuidString
        var descriptor = FetchDescriptor<ProviderConfigRecord>(
            predicate: #Predicate { $0.accountIDRaw == target }
        )
        descriptor.fetchLimit = 1
        if let record = try context.fetch(descriptor).first {
            record.lastSuccessfulRefreshAt = snapshot.fetchedAt
        }
        return true
    }
}
