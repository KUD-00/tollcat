import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

/// 折一次账本要多久。**不是断言性能，是把数字量出来写进文档。**
///
/// 第二轮审视第 3 条：读侧和刷新次数脱钩了，写侧没有。每次刷新走
/// `rebuild(accountID:)`，它以前取该账号**全部**历史；每天第一次打开走整份重折。
/// 一个 10 家、每天刷 3 次的用户，一年后是 ~11k 行。
///
/// 这里种 5000 条读数，量三条路各要多久，结果打进日志（`docs/LEDGER.md` 那张表就是
/// 从这里抄的）。只在 DEBUG 下跑，而且**不设阈值**——机器快慢差几倍，
/// 一个会随机变红的性能断言比没有更糟。
@MainActor
struct LedgerFoldCostTests {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()

    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 8, day: 17, hour: 12))! }

    #if DEBUG
    @Test("5000 条读数下三条写路各要多久（只记录，不设阈值）")
    func foldCostAtFiveThousandReadings() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let accounts = (1...10).map { AccountID.fixture($0) }
        // 10 家 × 500 条 = 5000：每天 3 次刷了半年多。
        for (index, account) in accounts.enumerated() {
            for tick in 0..<500 {
                let when = calendar.date(byAdding: .hour, value: -tick * 8, to: now)!
                _ = try SnapshotWriter.apply(
                    Snapshot(
                        providerID: .aws,
                        accountID: account,
                        kind: .usage,
                        fetchedAt: when,
                        periodStart: calendar.date(from: calendar.dateComponents([.year, .month], from: when))!,
                        periodEnd: when,
                        currentSpendUSD: Money(usd: Decimal(index * 100 + tick)),
                        dailyUSD: [calendar.startOfDay(for: when): Money(usd: 1)]
                    ),
                    to: context,
                    calendar: calendar
                )
            }
        }
        try context.save()
        #expect(try SnapshotLog.count(in: context) == 5000)

        let scope = MonthlyLedgerStore.Scope(accountIDs: Set(accounts), now: now, calendar: calendar)

        let rebuildAll = elapsed { try? MonthlyLedgerStore.rebuildAll(scope, in: context) }
        let single = elapsed {
            try? MonthlyLedgerStore.rebuild(accountID: accounts[0], scope: scope, in: context)
        }
        let today = calendar.date(byAdding: .day, value: 1, to: now)!
        let refoldToday = elapsed {
            try? MonthlyLedgerStore.refoldCurrentMonth(
                MonthlyLedgerStore.Scope(accountIDs: Set(accounts), now: today, calendar: calendar),
                in: context
            )
        }

        TollCatLedgerCost.log(
            "5000 条 / 10 家：rebuildAll \(rebuildAll)ms，rebuild(一家) \(single)ms，跨天重折当月 \(refoldToday)ms"
        )

        // **这里没有计时断言。** 上面那行注释说了「一个会随机变红的性能断言比没有更糟」，
        // 而 382 对 508 只有 25% 余量——CI 机器一忙就是红的，红了还什么都说明不了。
        // 数字只打进日志，人去看（`docs/LEDGER.md` 那张表就是从这里抄的）。
        //
        // 换成一条**确定性**的、而且只有在这个规模上才有意义的断言：跨天只重折当月
        // 之后，账本必须和「先清空再重铺」逐行相同。这条要是破了，省下来的时间就是
        // 用错数字换的——那才是这个测试该拦的事。
        let viaRefold = try MonthlyLedgerStore.all(calendar: calendar, in: context)
        try MonthlyLedgerStore.rebuildAll(
            MonthlyLedgerStore.Scope(accountIDs: Set(accounts), now: today, calendar: calendar),
            in: context
        )
        let viaRebuildAll = try MonthlyLedgerStore.all(calendar: calendar, in: context)
        #expect(Set(viaRefold) == Set(viaRebuildAll))
    }

    private func elapsed(_ body: () -> Void) -> Int {
        let started = ContinuousClock.now
        body()
        return Int((ContinuousClock.now - started) / .milliseconds(1))
    }
    #endif
}

#if DEBUG
enum TollCatLedgerCost {
    static func log(_ message: String) {
        print("[ledger-cost] \(message)")
    }
}
#endif
