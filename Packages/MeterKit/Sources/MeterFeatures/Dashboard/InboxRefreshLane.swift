import Foundation
import MeterCore
import MeterInbox
import MeterPersistence
import MeterProviders

/// 刷新的第二条泳道：读数信箱。
///
/// **一次请求喂所有信箱账号。** 它不能做成 `BillingProvider`——
/// `MeterProviders` 不许 import `MeterInbox`（隔离测试拦着），而且多家信箱
/// 各建一个 job 就是对同一个 `/v1/readings` 打三次一模一样的请求。
///
/// 产出仍然是 `BillingRefreshOutcome`，所以落库还是走 `applySuccess` 那一条路，
/// `SnapshotWriter` 那扇唯一的门不动。
enum InboxRefreshLane: Sendable {
    /// 一次取回，按 ingest key 分发到账号。
    ///
    /// - 没有信箱、或者这批没有信箱账号 → 一个请求都不发
    /// - 整体失败 → 每个账号各记一次 failure
    /// - 某账号没有投递记录 → 跳过，不写 $0，也不把手填标成失败
    /// - 未映射的 reading **丢弃**
    static func run(
        targets: [InboxRefreshTarget],
        client: InboxClient,
        credentials: any CredentialStore,
        calendar: Calendar
    ) async -> [BillingRefreshOutcome] {
        guard !targets.isEmpty else { return [] }
        guard let stored = InboxMailboxStore.load(from: credentials) else {
            #if DEBUG
            TollCatLog.event("inbox", "inbox refresh missing mailbox")
            #endif
            return targets.map { .failure(id: $0.accountID) }
        }

        let readings: [InboxReading]
        do {
            readings = try await client.fetchReadings(
                readKey: stored.readKey,
                calendar: calendar
            )
        } catch {
            #if DEBUG
            TollCatLog.event("inbox", "inbox fetch fail \(String(describing: error))")
            #endif
            return targets.map { .failure(id: $0.accountID) }
        }

        return distribute(targets: targets, readings: readings, calendar: calendar)
    }

    static func distribute(
        targets: [InboxRefreshTarget],
        readings: [InboxReading],
        calendar: Calendar
    ) -> [BillingRefreshOutcome] {
        let keyedReadings = Dictionary(
            readings.map { ($0.ingestKeyID, $0) },
            uniquingKeysWith: { _, latest in latest }
        )

        return targets.map { target in
            guard let ingestKeyID = target.ingestKeyID, !ingestKeyID.isEmpty else {
                return .failure(id: target.accountID)
            }
            guard let reading = keyedReadings[ingestKeyID] else {
                return .skipped(id: target.accountID)
            }
            return mapped(target: target, reading: reading, calendar: calendar)
        }
    }

    private static func mapped(
        target: InboxRefreshTarget,
        reading: InboxReading,
        calendar: Calendar
    ) -> BillingRefreshOutcome {
        guard let kind = ProviderCatalog.descriptor(id: target.providerID)?.kind,
              InboxSnapshotMapper.canRepresent(kind) else {
            return .failure(id: target.accountID)
        }
        var snapshot = InboxSnapshotMapper.snapshot(from: reading, kind: kind, calendar: calendar)
        // key 的归属是唯一事实源。投递 body 里的 provider 写错了也不许污染这个账号的历史。
        snapshot.providerID = target.providerID
        snapshot.accountID = target.accountID
        return .success(id: target.accountID, snapshot: snapshot)
    }
}
