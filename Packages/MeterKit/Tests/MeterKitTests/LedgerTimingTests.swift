import Foundation
import Testing
@testable import MeterCore

/// **折于 t1、读于 t2。**
///
/// 生产上账本行是某一刻折下来的，之后一直用到失效为止，而失效的粒度是「天」
/// （`LedgerFingerprint.day`）。`LedgerSelfCheck.run` 的老签名用同一个 `now` 折和读，
/// 于是这一整类漏它一条都抓不到——第二轮审视第 6 条就是这么漏掉的：
/// 同期窗口的终点精确到纳秒，早上 9 点折的那一行下午 6 点读出来是另一个数。
struct LedgerTimingTests {
    private let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()

    private func at(_ y: Int, _ m: Int, _ d: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d, hour: hour, minute: minute))!
    }

    /// 审视里那条探针：`PROBE ledgerCmp=Optional(0) recomputeCmp=Optional(20)`。
    private var prepaidLedger: [Snapshot] {
        func balance(_ at: Date, _ usd: Int) -> Snapshot {
            Snapshot(
                providerID: .openai,
                accountID: AccountID.fixture(1),
                kind: .prepaid,
                fetchedAt: at,
                periodStart: at,
                periodEnd: at,
                balanceUSD: Money(usd: usd)
            )
        }
        return [
            balance(at(2026, 7, 1, 0, 0), 100),
            balance(at(2026, 7, 16, 15, 7), 80),
            balance(at(2026, 8, 1, 0, 0), 70),
        ]
    }

    @Test("同一天里折和读：上午 9 点折的账本，下午 6 点读出来的同期和重算相同")
    func sameDayFoldAndReadAgree() {
        let issues = LedgerSelfCheck.run(
            snapshots: prepaidLedger,
            subscriptions: [],
            foldNow: at(2026, 8, 16, 9),
            readNow: at(2026, 8, 16, 18),
            calendar: utc
        )
        // 修前：账本 0 / 重算 20。
        #expect(issues.isEmpty, "\(issues.map(\.description).joined(separator: " | "))")
    }

    @Test("同一天里任取两个时刻折和读，都对得上")
    func anyTwoMomentsInTheSameDayAgree() {
        for foldHour in [0, 9, 13, 23] {
            for readHour in [0, 9, 13, 23] {
                let issues = LedgerSelfCheck.run(
                    snapshots: prepaidLedger,
                    subscriptions: [],
                    foldNow: at(2026, 8, 16, foldHour),
                    readNow: at(2026, 8, 16, readHour),
                    calendar: utc
                )
                #expect(issues.isEmpty, "折 \(foldHour) 点 / 读 \(readHour) 点: \(issues)")
            }
        }
    }

    @Test("跨时区：同一批读数换本日历，折和读都用新日历时仍然对得上")
    func timeZoneChangeStillAgreesWhenBothSidesMove() {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        let issues = LedgerSelfCheck.run(
            snapshots: prepaidLedger,
            subscriptions: [],
            foldNow: at(2026, 8, 16, 9),
            readNow: at(2026, 8, 16, 18),
            calendar: newYork
        )
        #expect(issues.isEmpty, "\(issues.map(\.description).joined(separator: " | "))")
    }

    @Test("按量那条路同样：日表在，同一天里折和读的同期一致")
    func dailyUsageAgreesWithinTheDay() {
        var daily: [Date: Money] = [:]
        for day in 1...31 {
            daily[utc.startOfDay(for: at(2026, 7, day))] = Money(usd: 1)
        }
        for day in 1...16 {
            daily[utc.startOfDay(for: at(2026, 8, day))] = Money(usd: 2)
        }
        let snapshot = Snapshot(
            providerID: .cloudflare,
            accountID: AccountID.fixture(2),
            kind: .usage,
            fetchedAt: at(2026, 8, 16, 9),
            periodStart: at(2026, 7, 1),
            periodEnd: at(2026, 8, 31),
            currentSpendUSD: Money(usd: 63),
            dailyUSD: daily
        )
        let issues = LedgerSelfCheck.run(
            snapshots: [snapshot],
            subscriptions: [],
            foldNow: at(2026, 8, 16, 9),
            readNow: at(2026, 8, 16, 18),
            calendar: utc
        )
        #expect(issues.isEmpty, "\(issues.map(\.description).joined(separator: " | "))")
    }
}
