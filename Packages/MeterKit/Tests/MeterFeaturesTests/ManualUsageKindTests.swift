import Foundation
import SwiftData
import Testing
import MeterCore
import MeterPersistence
import MeterProviders
@testable import MeterFeatures

/// 手填的 kind 只能是**装得下 `currentSpendUSD` 的那两种**。
///
/// 第二轮审视第 2 条：照目录原样落 `.subscription`（Notion / Figma / Slack / Linear）
/// 会写出一条永远不算数的快照——`hasBillableMetrics` 对 `.subscription` 只看
/// `committedMonthlyUSD`。保存成功、无报错、仪表显示 $0 并把这家标成「取数失败」。
/// 探针：`PROBE notion kind=subscription billable=false total=Optional(0) facts=["fetchFailed"]`。
@MainActor
struct ManualUsageKindTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func makeDashboard() throws -> DashboardModel {
        DashboardModel(
            providers: [:],
            container: try PersistenceContainer.makeContainer(inMemory: true),
            credentials: InMemoryCredentialStore(),
            clock: MeterClock(now: date(2026, 8, 17), calendar: calendar),
            httpClient: StubHTTPClient()
        )
    }

    /// 目录里各挑一家：按量、档位 + 超额、纯订阅、预充值。
    /// 四种 kind 手填 $30，四条都必须**算数**。
    @Test(
        "四种 kind 手填都算得进合计",
        arguments: [ProviderID.fly, .clerk, .notion, .openai]
    )
    func typedUsageCountsForEveryKind(providerID: ProviderID) async throws {
        let dashboard = try makeDashboard()
        try dashboard.addMembership(providerID)
        try dashboard.applyManualUsage(providerID: providerID, amount: Money(usd: 30), to: nil)
        // 折叠在后台排（`loadFromPersistence` 结尾那个 Task）。
        await dashboard.syncLedger()

        let state = try #require(dashboard.connectionStates().first { $0.providerID == providerID })
        let snapshot = try #require(
            dashboard.debugAllReadings().first { $0.accountID == state.accountID }
        )
        #expect(snapshot.hasBillableMetrics, "\(providerID.rawValue) 的手填快照不算数")
        #expect(dashboard.monthToDate?.totalUSD == Money(usd: 30), "\(providerID.rawValue)")
        let failed = dashboard.monthToDate?.facts.contains { $0.type == .fetchFailed } ?? false
        #expect(!failed, "\(providerID.rawValue) 被标成了取数失败")
    }

    @Test("目录 kind 装不下 currentSpendUSD 的一律降成 usage")
    func kindsThatCannotHoldCurrentSpendFallBackToUsage() {
        #expect(ProviderKind.usage.manualEntryKind == .usage)
        #expect(ProviderKind.planAndUsage.manualEntryKind == .planAndUsage)
        #expect(ProviderKind.subscription.manualEntryKind == .usage)
        #expect(ProviderKind.prepaid.manualEntryKind == .usage)
        #expect(ProviderKind.freeTier.manualEntryKind == .usage)
    }

    @Test("落下去的 kind 记在手填那张表上，不是每次读的时候现查目录")
    func kindIsStoredOnTheManualUsageRow() throws {
        let dashboard = try makeDashboard()
        try dashboard.addMembership(.notion)
        try dashboard.applyManualUsage(providerID: .notion, amount: Money(usd: 30), to: nil)

        let context = ModelContext(dashboard.storeContainer)
        let record = try #require(try ManualUsageStore.all(in: context).first)
        #expect(record.kind == .usage)
        #expect(record.kindRaw == ProviderKind.usage.rawValue)
    }

    @Test("导出再导入：两台设备算出的钱一样")
    func transferKeepsTheSameTotal() async throws {
        let source = try makeDashboard()
        try source.addMembership(.notion)
        try source.applyManualUsage(providerID: .notion, amount: Money(usd: 30), to: nil)
        try source.addMembership(.clerk)
        try source.applyManualUsage(providerID: .clerk, amount: Money(usd: 12), to: nil)
        await source.syncLedger()
        let before = try #require(source.monthToDate?.totalUSD)
        #expect(before == Money(usd: 42))

        let export = try DeviceTransfer.makeExport(
            container: source.storeContainer,
            credentials: InMemoryCredentialStore(),
            now: date(2026, 8, 17),
            calendar: calendar
        )
        let destinationContainer = try PersistenceContainer.makeContainer(inMemory: true)
        try DeviceTransfer.applyImport(
            fileBytes: export.fileBytes,
            code: export.code,
            container: destinationContainer,
            credentials: InMemoryCredentialStore(),
            now: date(2026, 8, 17),
            calendar: calendar
        )

        // 导入侧从**快照**重新折一遍：`.planAndUsage` 那家以前会被写死成 `.usage`，
        // 两台设备于是算出不同的钱。
        let context = ModelContext(destinationContainer)
        let imported = try SnapshotLog.snapshots(accountIDs: nil, calendar: calendar, in: context)
        #expect(imported.allSatisfy { $0.hasBillableMetrics })
        let total = MonthToDateCalculator.compute(
            snapshots: imported,
            subscriptions: [],
            now: date(2026, 8, 17),
            calendar: calendar
        )
        #expect(total.totalUSD == before)
    }
}
