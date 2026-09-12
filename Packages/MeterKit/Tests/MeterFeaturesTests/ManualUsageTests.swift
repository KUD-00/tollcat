import Foundation
import SwiftData
import Testing
import MeterCore
import MeterPersistence
import MeterProviders
@testable import MeterFeatures

@MainActor
struct ManualUsageTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("手填会建用量身份并写入本月快照")
    func typingCreatesIdentityAndSnapshot() async throws {
        let dashboard = try makeDashboard()
        try dashboard.addMembership(.fly)
        try dashboard.applyManualUsage(providerID: .fly, amount: Money(roundedUSD: 12.34), to: nil)
        await dashboard.syncLedger()

        let state = try #require(dashboard.connectionStates().first { $0.providerID == .fly })
        #expect(!state.usesInbox)
        #expect(state.includeInGlobalRefresh == false)
        let snapshot = try #require(dashboard.debugAllReadings().first { $0.accountID == state.accountID })
        #expect(snapshot.source == .manual)
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 12.34))
        #expect(dashboard.monthToDate?.totalUSD == Money(roundedUSD: 12.34))
    }

    @Test("同月再填仍是同一份用量，快照追加，合计取最新")
    func typingAgainAppendsSnapshotAndUsesLatest() async throws {
        let dashboard = try makeDashboard()
        try dashboard.addMembership(.fly)
        try dashboard.applyManualUsage(providerID: .fly, amount: Money(usd: 10), to: nil)
        await dashboard.syncLedger()
        let id = try #require(dashboard.connectionStates().first?.accountID)
        dashboard.setClock(MeterClock(now: date(2026, 8, 20), calendar: calendar))
        try dashboard.applyManualUsage(providerID: .fly, amount: Money(usd: 22), to: id)
        await dashboard.syncLedger()
        #expect(dashboard.connectionStates().count == 1)
        let typed = dashboard.debugAllReadings().filter { $0.accountID == id && $0.source == .manual }
        #expect(typed.count == 2)
        #expect(Set(typed.compactMap(\.currentSpendUSD)) == [Money(usd: 10), Money(usd: 22)])
        #expect(dashboard.monthToDate?.totalUSD == Money(usd: 22))
    }

    @Test("补填上月进 12 个月图，不算进本月合计")
    func backfillLastMonthShowsOnYearChartNotCurrentTotal() async throws {
        let dashboard = try makeDashboard()
        try dashboard.addMembership(.fly)
        try dashboard.applyManualUsage(
            providerID: .fly,
            amount: Money(usd: 40),
            to: nil,
            period: date(2026, 7, 1)
        )
        await dashboard.syncLedger()

        #expect(dashboard.monthToDate?.totalUSD == .zero)
        let id = try #require(dashboard.connectionStates().first?.accountID)
        let chart = ProviderHistoryChartBuilder.make(
            kind: .usage,
            readings: dashboard.readings(for: [id], since: date(2025, 8, 1)),
            range: .months12,
            now: date(2026, 8, 17),
            calendar: calendar
        )
        guard case .spend(let points, _, _, .month, _) = chart else {
            Issue.record("expected monthly spend chart")
            return
        }
        let july = points.first {
            calendar.isDate($0.date, equalTo: date(2026, 7, 1), toGranularity: .month)
        }
        #expect(july?.amount == 40)
        let august = points.first {
            calendar.isDate($0.date, equalTo: date(2026, 8, 1), toGranularity: .month)
        }
        #expect(august == nil)
    }

    @Test("两个月各留一条，本月合计取本月")
    func twoMonthsKeepSeparateTotals() async throws {
        let dashboard = try makeDashboard()
        try dashboard.addMembership(.fly)
        try dashboard.applyManualUsage(
            providerID: .fly,
            amount: Money(usd: 40),
            to: nil,
            period: date(2026, 7, 1)
        )
        await dashboard.syncLedger()
        let id = try #require(dashboard.connectionStates().first?.accountID)
        try dashboard.applyManualUsage(
            providerID: .fly,
            amount: Money(usd: 22),
            to: id,
            period: date(2026, 8, 1)
        )
        await dashboard.syncLedger()
        #expect(dashboard.monthToDate?.totalUSD == Money(usd: 22))
        let typed = dashboard.debugAllReadings().filter { $0.accountID == id && $0.source == .manual }
        let months = Set(typed.map { calendar.component(.month, from: $0.periodStart) })
        #expect(months == [7, 8])
    }

    @Test("脚本接到已有手填身份上，不是第二份账号")
    func attachInboxKeepsAccount() throws {
        let dashboard = try makeDashboard()
        try dashboard.addMembership(.fly)
        try dashboard.applyManualUsage(providerID: .fly, amount: Money(usd: 8), to: nil)
        let id = try #require(dashboard.connectionStates().first?.accountID)
        try dashboard.attachInbox(accountID: id, ingestKeyID: "key_fly")
        #expect(dashboard.connectionStates().count == 1)
        let state = try #require(dashboard.connectionStates().first)
        #expect(state.accountID == id)
        #expect(state.usesInbox)
        #expect(state.inboxIngestKeyID == "key_fly")
        #expect(state.includeInGlobalRefresh)
    }

    @Test("空态主操作对信箱那几家是填数")
    func inboxProvidersOfferTypedEntry() {
        let model = ProviderDetailModel(providerID: .fly, dashboard: .preview)
        #expect(model.supportsTypedUsage)
        #expect(model.showsTypedUsageEntry)
        #expect(!model.showsRefresh)
        let cloudflare = ProviderDetailModel(providerID: .cloudflare, dashboard: .preview)
        #expect(!cloudflare.supportsTypedUsage)
    }

    @Test("Cursor 没有账单接口：手填超额，不连钥匙，也不开信箱")
    func cursorIsSubscriptionWithTypedOverage() {
        let model = ProviderDetailModel(providerID: .cursor, dashboard: .preview)
        #expect(model.kind == .subscription)
        #expect(model.supportsTypedUsage)
        #expect(!model.supportsInboxIngest)
        #expect(!model.supportsUsageSetup)
        #expect(!model.showsRefresh)
        #expect(!model.showsRotateCredentials)
        #expect(!model.showsCredentialManagement)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func makeDashboard() throws -> DashboardModel {
        let now = date(2026, 8, 17)
        return DashboardModel(
            providers: [:],
            container: try PersistenceContainer.makeContainer(inMemory: true),
            credentials: InMemoryCredentialStore(),
            clock: MeterClock(now: now, calendar: calendar),
            httpClient: StubHTTPClient()
        )
    }
}
