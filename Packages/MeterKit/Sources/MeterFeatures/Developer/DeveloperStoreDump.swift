#if DEBUG
import Foundation
import MeterCore

@MainActor
enum DeveloperStoreDump {
    static func json(from dashboard: DashboardModel) -> String {
        let payload = Payload(
            snapshots: dashboard.debugAllReadings().map(SnapshotItem.init),
            subscriptions: dashboard.subscriptions.map(SubscriptionItem.init),
            connections: dashboard.connectionStates().map(ConnectionItem.init)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload),
              let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }

    private struct Payload: Encodable {
        var snapshots: [SnapshotItem]
        var subscriptions: [SubscriptionItem]
        var connections: [ConnectionItem]
    }

    private struct SnapshotItem: Encodable {
        var accountID: String?
        var providerID: String
        var kind: String
        var fetchedAt: Date
        var periodStart: Date
        var periodEnd: Date
        var currentSpendUSD: String?
        var balanceUSD: String?
        var committedMonthlyUSD: String?
        var chargeDayOfMonth: Int?
        var freeQuotaUsedRatio: Double?
        var dailyDayCount: Int?
        var dailyStart: Date?
        var dailyEnd: Date?

        init(_ snapshot: Snapshot) {
            // 账号才是主键：同一家两份账号的快照只写 providerID 会并成一堆。
            accountID = snapshot.accountID?.rawValue.uuidString
            providerID = snapshot.providerID.rawValue
            kind = snapshot.kind.rawValue
            fetchedAt = snapshot.fetchedAt
            periodStart = snapshot.periodStart
            periodEnd = snapshot.periodEnd
            currentSpendUSD = snapshot.currentSpendUSD.map(Self.decimal)
            balanceUSD = snapshot.balanceUSD.map(Self.decimal)
            committedMonthlyUSD = snapshot.committedMonthlyUSD.map(Self.decimal)
            chargeDayOfMonth = snapshot.chargeDayOfMonth
            freeQuotaUsedRatio = snapshot.freeQuotaUsedRatio
            if let daily = snapshot.dailyUSD, !daily.isEmpty {
                dailyDayCount = daily.count
                dailyStart = daily.keys.min()
                dailyEnd = daily.keys.max()
            }
        }

        private static func decimal(_ money: Money) -> String {
            NSDecimalNumber(decimal: money.usd).stringValue
        }
    }

    private struct SubscriptionItem: Encodable {
        var name: String
        var amountUSD: String
        var period: String
        var accountID: String?
        var providerID: String?

        init(_ subscription: MonthlySubscription) {
            name = subscription.name
            amountUSD = NSDecimalNumber(decimal: subscription.amount.usd).stringValue
            period = subscription.period.rawValue
            accountID = subscription.accountID?.rawValue.uuidString
            providerID = subscription.providerID?.rawValue
        }
    }

    private struct ConnectionItem: Encodable {
        var accountID: String
        var providerID: String
        var nickname: String?
        var isEnabled: Bool
        var credentialReference: String

        init(_ state: ProviderConnectionState) {
            accountID = state.accountID.rawValue.uuidString
            providerID = state.providerID.rawValue
            nickname = state.nickname
            isEnabled = state.isEnabled
            credentialReference = state.credentialReference
        }
    }
}
#endif
