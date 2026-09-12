import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

/// 账本落盘那几组测试共用的种子。
///
/// 两个套件（`MonthlyLedgerStoreTests` 和 `LedgerCodecTests`）问的是两件事——
/// 「读写这张表的行为对不对」和「一行过一遍编解码还是不是原来那一行」——
/// 但要的种子是同一份。各抄一份的话，改了一处忘了另一处，两组测试会开始
/// 描述两个不同的库，而它们本该守着同一个不变量。
@MainActor
enum LedgerFixture {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()
    static var now: Date { calendar.date(from: DateComponents(year: 2026, month: 8, day: 17, hour: 12))! }

    static func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    static var snapshots: [Snapshot] {
        var daily: [Date: Money] = [:]
        for (m, count) in [(6, 30), (7, 31), (8, 17)] {
            for d in 1...count {
                daily[calendar.startOfDay(for: day(2026, m, d))] = Money(usd: Decimal(d) / 10)
            }
        }
        return [
            Snapshot(
                providerID: .aws, accountID: AccountID.fixture(1), kind: .usage,
                fetchedAt: now,
                periodStart: day(2026, 6, 1), periodEnd: day(2026, 8, 31),
                currentSpendUSD: Money(usd: 90), dailyUSD: daily
            ),
            Snapshot(
                providerID: .github, accountID: AccountID.fixture(2), kind: .subscription,
                fetchedAt: now,
                periodStart: day(2026, 8, 1), periodEnd: day(2026, 8, 31),
                committedMonthlyUSD: Money(usd: 21), chargeDayOfMonth: 4
            ),
        ]
    }

    static var subscriptions: [MonthlySubscription] {
        [
            MonthlySubscription(
                name: "seat", amount: Money(usd: 12), period: .monthly,
                anchorDate: day(2026, 3, 8),
                accountID: AccountID.fixture(3), providerID: .openai
            )
        ]
    }

    /// 账本的输入现在从库里来：先把读数写进库，再按 `Scope` 折。
    static func store(_ snapshots: [Snapshot], into context: ModelContext, calendar: Calendar? = nil) throws {
        for snapshot in snapshots {
            _ = try SnapshotWriter.apply(snapshot, to: context, calendar: calendar ?? self.calendar)
        }
        try context.save()
    }

    static func scope(
        accountIDs: Set<AccountID>? = nil,
        ended: [AccountID: Date] = [:],
        now: Date? = nil,
        calendar: Calendar? = nil
    ) -> MonthlyLedgerStore.Scope {
        MonthlyLedgerStore.Scope(
            accountIDs: accountIDs,
            endedAccounts: ended,
            now: now ?? self.now,
            calendar: calendar ?? self.calendar
        )
    }
}
