import Foundation
import MeterCore
import MeterProviders

/// 开发工具「种子演示数据」：和 iOS `DashboardFixtureSeeder` 同一组设计稿快照。
package enum ProductSeed {
    package static func json(nowMillis: Int64) -> String {
        let calendar = ProductClock.calendar()
        let now = ProductClock.date(millis: nowMillis)
        do {
            var accounts: [ProviderID: UUID] = [:]
            var connections: [[String: Any]] = []
            for descriptor in ProviderCatalog.offered {
                // 没有演示 fixture 的家跳过，和 designSnapshots / iOS DashboardFixtureSeeder 同一条策略：
                // offered 远多于有设计稿的家，这里一抛整份种子就是空的，而调用方拿到的只是 ok=false。
                guard (try? FixtureLoader.isConnected(descriptor.id)) ?? false else { continue }
                let accountID = UUID()
                accounts[descriptor.id] = accountID
                connections.append([
                    "providerID": descriptor.id.rawValue,
                    "accountID": accountID.uuidString,
                    "kind": descriptor.kind.rawValue,
                ])
            }
            let snapshots = try FixtureLoader.designSnapshots(now: now, calendar: calendar).compactMap { snapshot -> [String: Any]? in
                guard let uuid = accounts[snapshot.providerID] else { return nil }
                var copy = snapshot
                copy.accountID = AccountID(rawValue: uuid)
                return ProductSnapshotCodec.json(from: copy)
            }
            let subscriptions = (try? FixtureLoader.designSubscriptions(now: now, calendar: calendar)) ?? []
            let subscriptionJSON = subscriptions.map { ProductSnapshotCodec.json(from: $0, calendar: calendar) }
            return JNIJSON.stringify([
                "ok": true,
                "connections": connections,
                "snapshots": snapshots,
                "subscriptions": subscriptionJSON,
            ])
        } catch {
            return JNIJSON.stringify([
                "ok": false,
                "error": String(describing: error),
            ])
        }
    }
}
