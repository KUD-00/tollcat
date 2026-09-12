import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

/// 记录层的日表按日历分量落盘，读写都要一本日历。测试统一用 UTC 公历。
///
/// 账期端点同样只存分量（`periodStartDay` / `periodEndDay`），所以这些往返用例里
/// 的 `periodEnd` 写的是**那一天的零点**，不是 23:59:59——后者读回来会被归一到
/// 同一天的零点（含当天，折算一律走 `periodExclusiveEnd`）。归一本身在
/// `SnapshotPeriodDayTests` 里单独有一条。
private let recordCalendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(secondsFromGMT: 0)!
    return c
}()

@MainActor
struct SnapshotRecordTests {
    @Test("来源跟着快照落库，投递来的数不会在重启后变成 API 取的")
    func snapshotRoundTripsSource() throws {
        let snapshot = Snapshot(
            providerID: .render,
            accountID: AccountID.fixture(for: .render),
            kind: .planAndUsage,
            source: .inbox,
            fetchedAt: Date(timeIntervalSince1970: 1_787_000_000),
            periodStart: Date(timeIntervalSince1970: 1_785_542_400),
            periodEnd: Date(timeIntervalSince1970: 1_788_134_400),
            currentSpendUSD: Money(usd: Decimal(string: "12.34")!)
        )

        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        context.insert(try SnapshotRecord(domain: snapshot, calendar: recordCalendar))
        try context.save()

        let stored = try context.fetch(FetchDescriptor<SnapshotRecord>())
        #expect(stored[0].sourceRaw == SnapshotSource.inbox.rawValue)
        #expect(try stored[0].toDomain(calendar: recordCalendar) == snapshot)
    }

    @Test("明细往返保留原价、用量和归属，Decimal 不退化成 Double")
    func snapshotRoundTripsSpendLines() throws {
        let snapshot = Snapshot(
            providerID: .github,
            accountID: AccountID.fixture(for: .github),
            kind: .planAndUsage,
            fetchedAt: Date(timeIntervalSince1970: 1_787_000_000),
            periodStart: Date(timeIntervalSince1970: 1_785_542_400),
            periodEnd: Date(timeIntervalSince1970: 1_788_134_400),
            currentSpendUSD: .zero,
            lines: [
                SpendLine(
                    category: "actions",
                    label: "Actions Linux",
                    scope: "RelayOS",
                    amountUSD: .zero,
                    listUSD: Money(usd: Decimal(string: "10.002")!),
                    quantity: Decimal(string: "1667")!,
                    unit: "Minutes"
                ),
                SpendLine(
                    category: "actions",
                    label: "Actions storage",
                    amountUSD: Money(usd: Decimal(string: "0.0025")!),
                    quantity: Decimal(string: "0.46822993099999999")!,
                    unit: "GigabyteHours",
                    allowanceNote: "First 375 vCPU-minutes included"
                ),
            ]
        )

        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        context.insert(try SnapshotRecord(domain: snapshot, calendar: recordCalendar))
        try context.save()

        let stored = try context.fetch(FetchDescriptor<SnapshotRecord>())
        #expect(try stored[0].toDomain(calendar: recordCalendar) == snapshot)
        #expect(try stored[0].toDomain(calendar: recordCalendar).lines?.first?.discountUSD == Money(usd: Decimal(string: "10.002")!))
        // 额度说明也要活着穿过落库：漏一个字段界面上就是"那句话不见了"。
        #expect(
            try stored[0].toDomain(calendar: recordCalendar).lines?.last?.allowanceNote == "First 375 vCPU-minutes included"
        )
    }

    @Test("没有明细的快照那一列留空，不写成空数组")
    func snapshotWithoutLinesStoresNil() throws {
        let snapshot = Snapshot(
            providerID: .cloudflare,
            accountID: AccountID.fixture(for: .cloudflare),
            kind: .usage,
            fetchedAt: Date(timeIntervalSince1970: 1_787_000_000),
            periodStart: Date(timeIntervalSince1970: 1_785_542_400),
            periodEnd: Date(timeIntervalSince1970: 1_788_134_400),
            currentSpendUSD: Money(usd: 1)
        )
        let record = try SnapshotRecord(domain: snapshot, calendar: recordCalendar)
        #expect(record.spendLinesData == nil)
        #expect(try record.toDomain(calendar: recordCalendar).lines == nil)
    }

    @Test("Snapshot 往返保留 kind 和 Decimal 金额，不退化成 Double")
    func snapshotRoundTripsKindAndDecimalMoney() throws {
        let fetchedAt = Date(timeIntervalSince1970: 1_787_000_000)
        // 日桶的键是日历上的那一天（落盘存分量，读回来是那天零点），夹具也按零点给。
        let day1 = recordCalendar.startOfDay(for: Date(timeIntervalSince1970: 1_786_300_800))
        let day2 = recordCalendar.startOfDay(for: Date(timeIntervalSince1970: 1_786_387_200))
        var daily: [Date: Money] = [:]
        daily[day1] = Money(usd: Decimal(string: "11.05")!)
        daily[day2] = Money(usd: Decimal(string: "0.40")!)

        let snapshot = Snapshot(
            providerID: .cloudflare,
            accountID: AccountID.fixture(for: .cloudflare),
            kind: .usage,
            fetchedAt: fetchedAt,
            periodStart: Date(timeIntervalSince1970: 1_785_542_400),
            periodEnd: Date(timeIntervalSince1970: 1_788_134_400),
            currentSpendUSD: Money(usd: Decimal(string: "11.05")!),
            dailyUSD: daily
        )

        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        context.insert(try SnapshotRecord(domain: snapshot, calendar: recordCalendar))
        try context.save()

        let stored = try context.fetch(FetchDescriptor<SnapshotRecord>())
        #expect(stored.count == 1)
        #expect(stored[0].currentSpendUSD == Decimal(string: "11.05"))
        #expect(stored[0].kindRaw == ProviderKind.usage.rawValue)

        let restored = try stored[0].toDomain(calendar: recordCalendar)
        #expect(restored == snapshot)
        #expect(restored.currentSpendUSD?.usd == Decimal(string: "11.05"))
        #expect(restored.dailyUSD?[day1]?.usd == Decimal(string: "11.05"))
    }

    @Test("多币种钱包往返保留原币和汇率，合计仍是 balanceUSD")
    func snapshotRoundTripsWallets() throws {
        let wallets = [
            ConvertedAmount(
                currency: "CNY",
                amount: Decimal(string: "14.17")!,
                usdPerUnit: Decimal(string: "0.1404")!,
                usd: Decimal(string: "1.99")!
            ),
            ConvertedAmount(
                currency: "USD",
                amount: 0,
                usdPerUnit: 1,
                usd: 0
            ),
        ]
        let snapshot = Snapshot(
            providerID: .deepseek,
            accountID: AccountID.fixture(for: .deepseek),
            kind: .prepaid,
            fetchedAt: Date(timeIntervalSince1970: 1_787_000_000),
            periodStart: Date(timeIntervalSince1970: 1_785_542_400),
            periodEnd: Date(timeIntervalSince1970: 1_788_134_400),
            balanceUSD: Money(usd: Decimal(string: "1.99")!),
            converted: wallets[0],
            wallets: wallets
        )

        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        context.insert(try SnapshotRecord(domain: snapshot, calendar: recordCalendar))
        try context.save()

        let restored = try context.fetch(FetchDescriptor<SnapshotRecord>())[0].toDomain(calendar: recordCalendar)
        #expect(restored == snapshot)
        #expect(restored.wallets?.count == 2)
        #expect(restored.wallets?[0].amount == Decimal(string: "14.17"))
        #expect(restored.isCurrencyConverted)
    }
}
