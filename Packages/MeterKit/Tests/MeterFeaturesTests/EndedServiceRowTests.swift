import Foundation
import Testing
import MeterCore
@testable import MeterFeatures

/// 「历史服务」：不再花钱、但过去花过的那几家。
///
/// 它不是新存的一张表，是从「接入结束了没」和「订阅退了没」推出来的。
/// 推错的代价是真的：一家结束掉的服务如果还留在主列表里，用户会以为它还在扣钱；
/// 反过来如果它连历史那一节都进不去，那段账就等于被藏起来了。
struct EndedServiceRowTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))!
    }

    @Test("接入结束、订阅也退了：这一行标成历史服务，不摆金额")
    func endedProviderBecomesHistory() {
        let account = AccountID.fixture(1)
        let rows = ServiceRowBuilder.rows(
            memberships: [ProviderMembership(providerID: .openai, sortIndex: 0)],
            connections: [connection(account, providerID: .openai, archivedAt: date(2026, 6, 20))],
            latest: [:],
            monthToDate: nil,
            marks: [:],
            subscriptions: [
                subscription(name: "ChatGPT Team", providerID: .openai, endDate: date(2026, 6, 1)),
            ],
            now: now,
            calendar: calendar
        )
        #expect(rows.count == 1)
        #expect(rows[0].isEnded)
        // 不写 $0（看着像还在跑），也不写最后一次读数（那是过去的钱）。
        #expect(rows[0].value == "—")
        #expect(rows[0].subtitle?.contains(String(localized: L("已结束"))) == true)
    }

    @Test("还有一笔在付就不算历史服务")
    func liveSubscriptionKeepsProviderCurrent() {
        let account = AccountID.fixture(1)
        let rows = ServiceRowBuilder.rows(
            memberships: [ProviderMembership(providerID: .openai, sortIndex: 0)],
            connections: [connection(account, providerID: .openai, archivedAt: date(2026, 6, 20))],
            latest: [:],
            monthToDate: nil,
            marks: [:],
            subscriptions: [
                subscription(name: "ChatGPT Team", providerID: .openai, endDate: date(2026, 6, 1)),
                subscription(name: "ChatGPT Plus", providerID: .openai, endDate: nil),
            ],
            now: now,
            calendar: calendar
        )
        #expect(rows.count == 1)
        #expect(!rows[0].isEnded)
        // 副标题只写还在付的那一笔，退掉的不能继续挂在行上。
        #expect(rows[0].subtitle?.contains("Team") != true)
    }

    @Test("刚加进来还没配任何东西的一家不是历史服务，是空的一家")
    func brandNewProviderIsNotHistory() {
        let rows = ServiceRowBuilder.rows(
            memberships: [ProviderMembership(providerID: .openai, sortIndex: 0)],
            connections: [],
            latest: [:],
            monthToDate: nil,
            marks: [:],
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        #expect(rows.count == 1)
        #expect(!rows[0].isEnded)
    }

    @Test("历史服务不进主列表的分组，只进「历史服务」那一节")
    func endedRowsLeaveTheMainSections() {
        let ended = ServiceRowBuilder.rows(
            memberships: [ProviderMembership(providerID: .openai, sortIndex: 0)],
            connections: [],
            latest: [:],
            monthToDate: nil,
            marks: [:],
            subscriptions: [
                subscription(name: "ChatGPT Team", providerID: .openai, endDate: date(2026, 6, 1)),
            ],
            now: now,
            calendar: calendar
        )
        #expect(ended.count == 1)
        #expect(ended[0].isEnded)
        // `connectedRows` 是主列表的入口（`ServicesModel`），历史那几行必须被它排掉。
        #expect(ended.filter { $0.isConnected && !$0.isEnded }.isEmpty)
    }

    // MARK: - Helpers

    private func connection(
        _ accountID: AccountID,
        providerID: ProviderID,
        archivedAt: Date?
    ) -> ProviderConnectionState {
        ProviderConnectionState(
            accountID: accountID,
            providerID: providerID,
            isEnabled: true,
            archivedAt: archivedAt,
            sortIndex: 0,
            credentialReference: "credential.\(accountID.rawValue.uuidString)",
            includeInGlobalRefresh: true
        )
    }

    private func subscription(
        name: String,
        providerID: ProviderID,
        endDate: Date?
    ) -> MonthlySubscription {
        MonthlySubscription(
            name: name,
            amount: Money(usd: 20),
            period: .monthly,
            anchorDate: date(2026, 1, 1),
            endDate: endDate,
            providerID: providerID
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
}
