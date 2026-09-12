import Foundation
import Testing
import MeterCore
import MeterProviders
@testable import MeterFeatures

struct InboxServiceRowTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))! }

    private func row(
        usesInbox: Bool,
        lastSuccess: Date?,
        snapshots: [Snapshot] = []
    ) -> ServiceRowItem? {
        ServiceRowBuilder.rows(
            memberships: [ProviderMembership(providerID: .render, sortIndex: 0)],
            connections: [
                ProviderConnectionState(
                    accountID: AccountID.fixture(for: .render),
                    providerID: .render,
                    isEnabled: true,
                    sortIndex: 0,
                    lastSuccessfulRefreshAt: lastSuccess,
                    credentialReference: "render-ref",
                    includeInGlobalRefresh: true,
                    usesInbox: usesInbox
                ),
            ],
            // 行首金额现在收「每账号此刻的状态」，不是快照日志。
            // 测试仍从快照出发，先归约一遍——那条归约规则也一并被覆盖。
            latest: AccountLatest.reduceAll(snapshots: snapshots, calendar: calendar),
            monthToDate: nil,
            marks: [:],
            subscriptions: [],
            now: now,
            calendar: calendar
        ).first { $0.id == .render }
    }

    @Test("刚接入还没收到投递：说「等待第一次投递」，不是「暂无读数」")
    func freshInboxConnectionSaysWaiting() throws {
        let item = try #require(row(usesInbox: true, lastSuccess: nil))
        #expect(item.isConnected)
        #expect(item.value == "—")
        #expect(item.subtitle == String(localized: L("等待第一次投递")))
        #expect(item.spokenValue == String(localized: L("等待第一次投递")))
    }

    @Test("非信箱的家没数时不说「等待投递」——那是接失败")
    func regularProviderKeepsOldWording() throws {
        let item = try #require(row(usesInbox: false, lastSuccess: nil))
        #expect(item.subtitle != String(localized: L("等待第一次投递")))
        #expect(item.spokenValue != String(localized: L("等待第一次投递")))
    }

    @Test("投递过一次之后就走正常文案，不再停在等待态")
    func afterFirstDeliveryFallsBackToNormalCopy() throws {
        let reported = calendar.date(from: DateComponents(year: 2026, month: 8, day: 16))!
        let snapshot = Snapshot(
            providerID: .render,
            accountID: AccountID.fixture(for: .render),
            kind: .planAndUsage,
            source: .inbox,
            fetchedAt: reported,
            periodStart: calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!,
            periodEnd: calendar.date(from: DateComponents(year: 2026, month: 8, day: 31))!,
            currentSpendUSD: Money(usd: Decimal(string: "12.34")!)
        )
        let item = try #require(
            row(usesInbox: true, lastSuccess: reported, snapshots: [snapshot])
        )
        #expect(item.subtitle != String(localized: L("等待第一次投递")))
        #expect(item.value == Money(usd: Decimal(string: "12.34")!).formatted())
    }

    @Test("手填的行说「你填入的」，不是等待投递")
    func typedUsageSaysEntered() throws {
        let entered = calendar.date(from: DateComponents(year: 2026, month: 8, day: 16))!
        let snapshot = Snapshot(
            providerID: .fly,
            accountID: AccountID.fixture(for: .fly),
            kind: .usage,
            source: .manual,
            fetchedAt: entered,
            periodStart: calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!,
            periodEnd: calendar.date(from: DateComponents(year: 2026, month: 8, day: 31))!,
            currentSpendUSD: Money(roundedUSD: 21.4)
        )
        let item = ServiceRowBuilder.rows(
            memberships: [ProviderMembership(providerID: .fly, sortIndex: 0)],
            connections: [
                ProviderConnectionState(
                    accountID: AccountID.fixture(for: .fly),
                    providerID: .fly,
                    isEnabled: true,
                    sortIndex: 0,
                    lastSuccessfulRefreshAt: entered,
                    credentialReference: "fly-ref",
                    includeInGlobalRefresh: false,
                    usesInbox: false
                ),
            ],
            latest: AccountLatest.reduceAll(snapshots: [snapshot], calendar: calendar),
            monthToDate: nil,
            marks: [:],
            subscriptions: [],
            now: now,
            calendar: calendar
        ).first { $0.id == .fly }
        let row = try #require(item)
        #expect(row.subtitle == String(localized: L("你填入的")))
        #expect(row.value == Money(roundedUSD: 21.4).formatted())
    }
}

struct PrepaidServiceRowTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))! }

    @Test("预充值行首是本月消耗，钱包剩额只在副标题")
    func prepaidRowShowsSpendNotBalance() throws {
        let start = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 8, day: 31))!
        let snapshot = Snapshot(
            providerID: .openrouter,
            accountID: AccountID.fixture(for: .openrouter),
            kind: .prepaid,
            fetchedAt: now,
            periodStart: start,
            periodEnd: end,
            balanceUSD: Money(roundedUSD: 74.75)
        )
        let month = MonthToDateCalculator.compute(
            snapshots: [snapshot],
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        let item = try #require(
            prepaidRow(snapshots: [snapshot], monthToDate: month)
        )
        let balance = Money(roundedUSD: 74.75)
        #expect(item.value == Money.zero.formatted())
        #expect(item.value != balance.formatted())
        #expect(
            item.subtitle == String(localized: L("余额 \(MoneyPresentation.usd.string(from: balance, original: nil))"))
        )
    }

    @Test("有月初余额时，行首是月初减现在，不是现在还剩多少")
    func prepaidRowShowsMonthConsumptionWhenHistoryExists() throws {
        let monthStart = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 8, day: 31))!
        let opening = Snapshot(
            providerID: .openrouter,
            accountID: AccountID.fixture(for: .openrouter),
            kind: .prepaid,
            fetchedAt: monthStart,
            periodStart: monthStart,
            periodEnd: end,
            balanceUSD: Money(usd: 100)
        )
        let current = Snapshot(
            providerID: .openrouter,
            accountID: AccountID.fixture(for: .openrouter),
            kind: .prepaid,
            fetchedAt: now,
            periodStart: monthStart,
            periodEnd: end,
            balanceUSD: Money(roundedUSD: 74.75)
        )
        let month = MonthToDateCalculator.compute(
            snapshots: [opening, current],
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        let item = try #require(
            prepaidRow(snapshots: [opening, current], monthToDate: month)
        )
        let spent = Money(usd: Decimal(string: "25.25")!)
        let balance = Money(roundedUSD: 74.75)
        #expect(item.value == spent.formatted())
        #expect(item.value != balance.formatted())
        #expect(
            item.subtitle == String(localized: L("余额 \(MoneyPresentation.usd.string(from: balance, original: nil))"))
        )
    }

    private func prepaidRow(
        snapshots: [Snapshot],
        monthToDate: MonthToDate?
    ) -> ServiceRowItem? {
        ServiceRowBuilder.rows(
            memberships: [ProviderMembership(providerID: .openrouter, sortIndex: 0)],
            connections: [
                ProviderConnectionState(
                    accountID: AccountID.fixture(for: .openrouter),
                    providerID: .openrouter,
                    isEnabled: true,
                    sortIndex: 0,
                    lastSuccessfulRefreshAt: now,
                    credentialReference: "or-ref",
                    includeInGlobalRefresh: true,
                    usesInbox: false
                ),
            ],
            latest: AccountLatest.reduceAll(snapshots: snapshots, calendar: calendar),
            monthToDate: monthToDate,
            marks: [AccountID.fixture(for: .openrouter): .current],
            subscriptions: [],
            now: now,
            calendar: calendar
        ).first { $0.id == .openrouter }
    }
}
