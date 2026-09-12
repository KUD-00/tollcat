import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

/// 账本行和快照行**过一遍编解码之后还是不是原来那一行**，以及指纹。
///
/// 和 `MonthlyLedgerStoreTests` 分开：那一组问的是读写口的行为（折、重折、失效判据），
/// 这一组问的是「落盘这一步有没有把东西弄丢」——日表的精度、日期键跟哪本日历走、
/// 旧格式还读不读得出来、从库里算的指纹和从内存里算的是不是同一个。
///
/// 种子在 `LedgerFixture`，两组共用一份。
@MainActor
struct LedgerCodecTests {
    private var calendar: Calendar { LedgerFixture.calendar }
    private var now: Date { LedgerFixture.now }
    private var snapshots: [Snapshot] { LedgerFixture.snapshots }
    private var subscriptions: [MonthlySubscription] { LedgerFixture.subscriptions }

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date { LedgerFixture.day(y, m, d) }

    private func store(_ snapshots: [Snapshot], into context: ModelContext, calendar: Calendar? = nil) throws {
        try LedgerFixture.store(snapshots, into: context, calendar: calendar)
    }

    private func scope(
        accountIDs: Set<AccountID>? = nil,
        ended: [AccountID: Date] = [:],
        now: Date? = nil,
        calendar: Calendar? = nil
    ) -> MonthlyLedgerStore.Scope {
        LedgerFixture.scope(accountIDs: accountIDs, ended: ended, now: now, calendar: calendar)
    }

    @Test("日粒度过一遍编解码不掉精度——账本里那张表是「上月同期」的唯一来源")
    func dailyMapSurvivesTheRoundTrip() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        try MonthlyLedgerStore.rebuildAll(scope(), in: context)
        let folded = LedgerSelfCheck.foldAll(snapshots: snapshots, now: now, calendar: calendar)
        let stored = try MonthlyLedgerStore.all(calendar: calendar, in: context)
        for row in folded where !row.dailyUSD.isEmpty {
            let match = stored.first { $0.key == row.key }
            #expect(match?.dailyUSD == row.dailyUSD, "\(row.monthStart) 的日表变了")
        }
    }

    @Test("日表的键是日历上的那一天：东京写、纽约读，同一个厂商日不会变成两天")
    func dailyKeysFollowTheReadingCalendar() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        let id = AccountID.fixture(1)
        let tokyoDay = tokyo.date(from: DateComponents(year: 2026, month: 8, day: 15))!
        let newYorkDay = newYork.date(from: DateComponents(year: 2026, month: 8, day: 15))!
        func reading(fetchedAt: Date, day: Date) -> Snapshot {
            Snapshot(
                providerID: .cloudflare, accountID: id, kind: .usage, fetchedAt: fetchedAt,
                periodStart: day, periodEnd: day, currentSpendUSD: Money(usd: 10),
                dailyUSD: [day: Money(usd: 10)]
            )
        }
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        // 在东京刷的那条按东京日历落盘，飞到纽约再刷一条按纽约落盘。
        try store([reading(fetchedAt: tokyoDay.addingTimeInterval(3600 * 20), day: tokyoDay)], into: context, calendar: tokyo)
        try store([reading(fetchedAt: newYorkDay.addingTimeInterval(3600 * 30), day: newYorkDay)], into: context, calendar: newYork)

        let readBack = try SnapshotLog.snapshots(accountIDs: [id], calendar: newYork, in: context)
        let merged = SnapshotDailyMap.merged(from: readBack, calendar: newYork)
        // 两条说的都是「8 月 15 日」，纽约日历下就是同一个键，后取覆盖先取——不是两天 $20。
        #expect(merged.count == 1)
        #expect(merged[newYorkDay] == Money(usd: 10))
    }

    @Test("旧格式（时间戳）的日表仍然读得出来")
    func legacyDailyEntriesStillDecode() throws {
        let day = calendar.startOfDay(for: day(2026, 8, 15))
        // 加 `DayKey` 之前落盘的形状：`day` 是 timeIntervalSinceReferenceDate。
        let json = #"[{"day":\#(day.timeIntervalSinceReferenceDate),"usd":"11.05"}]"#
        let decoded = try DailySpendCodec.decode(Data(json.utf8), calendar: calendar)
        #expect(decoded == [day: Money(usd: Decimal(string: "11.05")!)])
    }

    @Test("指纹不看拿到读数的顺序，但看有哪些")
    func fingerprintIgnoresOrderNotContent() {
        let forward = LedgerFingerprint.make(
            snapshots: snapshots, endedAccounts: [:], now: now, calendar: calendar
        )
        let backward = LedgerFingerprint.make(
            snapshots: snapshots.reversed(), endedAccounts: [:], now: now, calendar: calendar
        )
        // 顺序是取数顺序，不是内容。同一批读数换个顺序不该让整份账本重折一遍。
        #expect(forward == backward)

        var newer = snapshots[0]
        newer.fetchedAt = calendar.date(byAdding: .day, value: -3, to: now)!
        #expect(
            LedgerFingerprint.make(
                snapshots: snapshots + [newer], endedAccounts: [:], now: now, calendar: calendar
            ) != forward
        )
        #expect(
            LedgerFingerprint.make(
                snapshots: Array(snapshots.dropFirst()),
                endedAccounts: [:],
                now: now,
                calendar: calendar
            ) != forward
        )
    }

    @Test("库里算的指纹和内存里算的是同一个——戳和比不会各说各话")
    func fingerprintFromStoreMatchesFingerprintFromMemory() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try store(snapshots, into: context)
        let fromStore = LedgerFingerprint.make(
            entries: try SnapshotLog.fingerprintEntries(accountIDs: nil, calendar: calendar, in: context),
            endedAccounts: [:], now: now, calendar: calendar
        )
        let fromMemory = LedgerFingerprint.make(
            snapshots: snapshots, endedAccounts: [:], now: now, calendar: calendar
        )
        #expect(fromStore == fromMemory)
    }

}
