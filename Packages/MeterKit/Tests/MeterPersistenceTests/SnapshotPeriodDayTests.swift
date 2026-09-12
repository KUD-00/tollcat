import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

/// 账期端点**只存日历分量**（`periodStartDay` / `periodEndDay`）。
///
/// 第二轮审视第 1 条：存瞬间的话，东京写下的「8 月 1 日 00:00」在纽约日历上是
/// 7 月 31 日 11:00，那条快照于是被判成「和七月有重叠」，整笔钱摊进七月。
/// 折算那一半在 `MeterKitTests/PeriodEndpointTimeZoneTests.swift`。
@MainActor
struct SnapshotPeriodDayTests {
    private let tokyo: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return c
    }()
    private let newYork: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return c
    }()

    @Test("东京写、纽约读：账期起点是纽约日历八月一号的零点")
    func periodStartFollowsTheReadingCalendar() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let snapshot = Snapshot(
            providerID: .aiven,
            accountID: AccountID.fixture(1),
            kind: .usage,
            fetchedAt: tokyo.date(from: DateComponents(year: 2026, month: 8, day: 17, hour: 12))!,
            periodStart: tokyo.date(from: DateComponents(year: 2026, month: 8, day: 1))!,
            periodEnd: tokyo.date(from: DateComponents(year: 2026, month: 8, day: 31))!,
            currentSpendUSD: Money(usd: 100)
        )
        context.insert(try SnapshotRecord(domain: snapshot, calendar: tokyo))
        try context.save()

        let stored = try context.fetch(FetchDescriptor<SnapshotRecord>())[0]
        #expect(stored.periodStartDay == "2026-08-01")
        #expect(stored.periodEndDay == "2026-08-31")

        let readInNewYork = try stored.toDomain(calendar: newYork)
        let augustInNewYork = newYork.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        #expect(readInNewYork.periodStart == augustInNewYork)
        #expect(newYork.component(.month, from: readInNewYork.periodStart) == 8)
        // 存瞬间的话这里会是 7 月——那正是整笔钱漂进上个月的入口。
        #expect(newYork.component(.month, from: snapshot.periodStart) == 7)
    }

    @Test("账期终点归一到那一天的零点：23:59:59 和当天零点存出来一样")
    func periodEndNormalisesToTheStartOfThatDay() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let lastSecond = tokyo.date(
            from: DateComponents(year: 2026, month: 8, day: 31, hour: 23, minute: 59, second: 59)
        )!
        let snapshot = Snapshot(
            providerID: .aiven,
            accountID: AccountID.fixture(1),
            kind: .usage,
            fetchedAt: lastSecond,
            periodStart: tokyo.date(from: DateComponents(year: 2026, month: 8, day: 1))!,
            periodEnd: lastSecond,
            currentSpendUSD: Money(usd: 100)
        )
        context.insert(try SnapshotRecord(domain: snapshot, calendar: tokyo))
        try context.save()
        let restored = try context.fetch(FetchDescriptor<SnapshotRecord>())[0].toDomain(calendar: tokyo)
        // 含当天：折算一律走 `periodExclusiveEnd`（当天零点 + 1 天），
        // 所以 23:59:59 这一节精度没人用得上。
        #expect(restored.periodEnd == tokyo.startOfDay(for: lastSecond))
        // `fetchedAt` 是**真正的瞬间**，一秒都不许动。
        #expect(restored.fetchedAt == lastSecond)
    }

    @Test("旧行（两列空串）回落到旧的瞬间列，读出来和从前一样")
    func legacyRowsFallBackToTheStoredInstant() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let start = tokyo.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let end = tokyo.date(from: DateComponents(year: 2026, month: 8, day: 31))!
        let record = try SnapshotRecord(
            domain: Snapshot(
                providerID: .aiven,
                accountID: AccountID.fixture(1),
                kind: .usage,
                fetchedAt: start,
                periodStart: start,
                periodEnd: end,
                currentSpendUSD: Money(usd: 100)
            ),
            calendar: tokyo
        )
        // 把这一行退回加分量列之前的形状。
        record.periodStartDay = ""
        record.periodEndDay = ""
        context.insert(record)
        try context.save()

        let restored = try context.fetch(FetchDescriptor<SnapshotRecord>())[0].toDomain(calendar: tokyo)
        #expect(restored.periodStart == start)
        #expect(restored.periodEnd == end)
    }

    @Test("结束时间也存分量：东京 8 月 31 日 23:30 结束，纽约读出来还是八月")
    func archivedDayFollowsTheReadingCalendar() throws {
        let endedAt = tokyo.date(
            from: DateComponents(year: 2026, month: 8, day: 31, hour: 23, minute: 30)
        )!
        let record = ProviderConfigRecord(
            accountID: AccountID.fixture(1),
            providerID: .aiven,
            isEnabled: true,
            archived: ArchivedStamp(at: endedAt, calendar: tokyo),
            sortIndex: 0,
            credentialReference: "credential.test"
        )
        #expect(record.archivedDay == "2026-08-31")

        let state = try #require(record.connectionState(calendar: newYork))
        let archived = try #require(state.archivedAt)
        #expect(newYork.component(.month, from: archived) == 8)
        #expect(newYork.component(.day, from: archived) == 31)
        // 存瞬间的话这里会是纽约的 8 月 31 日 10:30——同一天，但是碰上月末
        // 23:30 + 更东的时区就会整月挪位；分量没有这个问题。
        #expect(newYork.component(.month, from: endedAt) == 8)
    }

    @Test("旧接入行（没有分量列）回落到 archivedAt")
    func legacyArchivedRowsFallBack() throws {
        let endedAt = tokyo.date(from: DateComponents(year: 2026, month: 8, day: 31, hour: 12))!
        let record = ProviderConfigRecord(
            accountID: AccountID.fixture(1),
            providerID: .aiven,
            isEnabled: true,
            archived: ArchivedStamp(at: endedAt, calendar: tokyo),
            sortIndex: 0,
            credentialReference: "credential.test"
        )
        record.archivedDay = nil
        #expect(record.archivedDate(in: newYork) == endedAt)
    }
}
