import Foundation
import SwiftData
import Testing
import MeterCore
import MeterPersistence
@testable import MeterFeatures

/// `DashboardStore` 的读**一律 throws，不在这一层吞**。
///
/// 第二轮审视第 11 条：文件头刚写完这句话，同一文件 20 行后就是
/// `try? record.toDomain(calendar:)`——一条 `periodRaw` 不认识的订阅从合计里
/// 悄悄消失，界面上没有那一行，而且完全正常。
@MainActor
struct DashboardStoreReadFailureTests {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()

    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 8, day: 17, hour: 12))! }

    private func makeStore() throws -> (DashboardStore, ModelContainer) {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        return (DashboardStore(container: container, credentials: InMemoryCredentialStore()), container)
    }

    private func seedGoodAndBadSubscription(into container: ModelContainer) throws {
        let context = ModelContext(container)
        context.insert(
            SubscriptionRecord(
                domain: MonthlySubscription(
                    name: "好的",
                    amount: Money(usd: 10),
                    period: .monthly,
                    anchorDate: calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!
                ),
                calendar: calendar
            )
        )
        let broken = SubscriptionRecord(
            domain: MonthlySubscription(
                name: "坏的",
                amount: Money(usd: 20),
                period: .monthly,
                anchorDate: calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!
            ),
            calendar: calendar
        )
        // 加这一档周期之前写下的行、或者半截写坏的行。
        broken.periodRaw = "每两周"
        context.insert(broken)
        try context.save()
    }

    @Test("一条 periodRaw 不合法的订阅让 fetchSubscriptions 抛错，而不是少一行")
    func brokenSubscriptionThrowsInsteadOfVanishing() throws {
        let (store, container) = try makeStore()
        try seedGoodAndBadSubscription(into: container)
        #expect(throws: (any Error).self) {
            _ = try store.fetchSubscriptions(calendar: self.calendar)
        }
    }

    @Test("列表那条路同样：坏行抛错，不是安静地少一行")
    func brokenSubscriptionThrowsFromTheListPathToo() throws {
        let (store, container) = try makeStore()
        try seedGoodAndBadSubscription(into: container)
        #expect(throws: (any Error).self) {
            _ = try store.subscriptionItems(now: self.now, calendar: self.calendar)
        }
    }

    @Test("好行照读：上面两条不是被别的东西挡住的")
    func healthyRowsStillRead() throws {
        let (store, container) = try makeStore()
        let context = ModelContext(container)
        context.insert(
            SubscriptionRecord(
                domain: MonthlySubscription(
                    name: "好的",
                    amount: Money(usd: 10),
                    period: .monthly,
                    anchorDate: calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!
                ),
                calendar: calendar
            )
        )
        try context.save()
        #expect(try store.fetchSubscriptions(calendar: calendar).count == 1)
    }

    @Test("写失败会亮「有一项没能保存」，不是安静地弹回旧值")
    func writeFailuresAreReported() {
        let status = PersistenceStatus(storage: .disk, containsDemoData: false)
        #expect(status.notices.isEmpty)
        status.didFailToWrite = true
        #expect(status.notices.map(\.id) == ["write-failed"])
        // 和读失败分开：一个是「你看到的是旧的」，一个是「你以为改了其实没改」。
        status.didFailToRead = true
        #expect(status.notices.map(\.id) == ["read-failed", "write-failed"])
    }
}
