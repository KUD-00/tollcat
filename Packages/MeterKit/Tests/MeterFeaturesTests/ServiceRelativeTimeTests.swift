import Foundation
import Testing
import MeterCore
import MeterPersistence
import MeterProviders
@testable import MeterFeatures

struct ServiceRelativeTimeTests {
    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("刚刷新过的时刻写成刚刚，不要一小时后")
    func justRefreshedIsJustNow() {
        let now = Date(timeIntervalSince1970: 1_776_614_400)
        #expect(
            ServiceRelativeTime.caption(from: now, now: now, calendar: utc)
                == String(localized: L("刚刚"))
        )
    }

    @Test("刷新时刻比 now 新时也是刚刚，不要写成将来")
    func futureRefreshIsJustNow() {
        let now = Date(timeIntervalSince1970: 1_776_614_400)
        let later = now.addingTimeInterval(3600)
        #expect(
            ServiceRelativeTime.caption(from: later, now: now, calendar: utc)
                == String(localized: L("刚刚"))
        )
    }

    /// `MeterDateFormat` 的 formatter 按（模板 · locale · 历法 · 时区）缓存。
    /// 缓存的新风险是键冲突：先用 UTC 格式化，再用东京时区格式化同一瞬间，
    /// 混用同一个实例就会重演「七月印成八月」那个坑。
    @Test("formatter 缓存按时区分键：月末边界值在两个时区各印各的月份")
    func formatterCacheKeysByTimeZone() {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        // UTC 的 7 月 31 日深夜，东京已经是 8 月 1 日。
        let edge = utc.date(from: DateComponents(year: 2026, month: 7, day: 31, hour: 23, minute: 30))!
        let en = Locale(identifier: "en_US")

        let july = MeterDateFormat.monthAndDay(edge, calendar: utc, locale: en)
        let august = MeterDateFormat.monthAndDay(edge, calendar: tokyo, locale: en)
        #expect(july.contains("Jul"))
        #expect(august.contains("Aug"))

        // 反过来再各读一遍：命中缓存后结果必须原样。
        #expect(MeterDateFormat.monthAndDay(edge, calendar: tokyo, locale: en) == august)
        #expect(MeterDateFormat.monthAndDay(edge, calendar: utc, locale: en) == july)

        let julyYearMonth = MeterDateFormat.yearMonth(edge, calendar: utc, locale: en)
        let augustYearMonth = MeterDateFormat.yearMonth(edge, calendar: tokyo, locale: en)
        #expect(julyYearMonth.contains("July"))
        #expect(augustYearMonth.contains("August"))
        #expect(MeterDateFormat.yearMonth(edge, calendar: tokyo, locale: en) == augustYearMonth)
        #expect(MeterDateFormat.yearMonth(edge, calendar: utc, locale: en) == julyYearMonth)
    }

    @Test("live 时钟读墙钟，不是启动那一刻")
    func liveClockReadsWallTime() {
        let clock = MeterClock.live
        #expect(abs(clock.now.timeIntervalSinceNow) < 1)
    }
}

@MainActor
struct RefreshTimestampTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 16, hour: 12))!
    }

    @Test("刷新成功后，内存里的上次成功时间跟着新快照走，详情页写成刚刚")
    func refreshUpdatesInMemoryStampAndCaption() async throws {
        let old = now.addingTimeInterval(-8 * 60)
        let accountID = AccountID.fixture(for: .cloudflare)
        let dashboard = DashboardModel(
            providers: [
                .cloudflare: FixedSnapshotProvider(
                    snapshot: usageSnapshot(accountID: accountID, fetchedAt: now, spend: 11.05)
                ),
            ],
            container: try PersistenceContainer.makeContainer(inMemory: true),
            credentials: InMemoryCredentialStore(),
            clock: MeterClock(now: now, calendar: calendar),
            httpClient: StubHTTPClient()
        )
        try dashboard.applyConnection(
            accountID: accountID,
            providerID: .cloudflare,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: "test-cf-refresh-stamp",
            fields: [
                CredentialField.apiToken.rawValue: "tok",
                CredentialField.accountID.rawValue: "acc",
            ],
            snapshots: [usageSnapshot(accountID: accountID, fetchedAt: old, spend: 10)],
            mode: .create
        )
        #expect(dashboard.connectionStates().first?.lastSuccessfulRefreshAt == old)

        await dashboard.refresh()

        #expect(dashboard.connectionStates().first?.lastSuccessfulRefreshAt == now)
        let detail = ProviderDetailModel(providerID: .cloudflare, dashboard: dashboard)
        #expect(detail.lastRefreshCaption == String(localized: L("刚刚")))
        // 服务卡不写刷新时刻：读数是新的，「刚刚」只是噪声。这句留在详情页。
        let services = ServicesModel(dashboard: dashboard)
        #expect(services.rows.first { $0.id == .cloudflare }?.subtitle == nil)
    }

    private func usageSnapshot(accountID: AccountID, fetchedAt: Date, spend: Decimal) -> Snapshot {
        Snapshot(
            providerID: .cloudflare,
            accountID: accountID,
            kind: .usage,
            fetchedAt: fetchedAt,
            periodStart: calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!,
            periodEnd: calendar.date(
                from: DateComponents(year: 2026, month: 8, day: 31, hour: 23, minute: 59, second: 59)
            )!,
            currentSpendUSD: Money(usd: spend)
        )
    }
}

private struct FixedSnapshotProvider: BillingProvider {
    var snapshot: Snapshot

    func fetch(credential: Credential) async throws -> Snapshot {
        snapshot
    }
}

/// 刷新管线本身：成功 / 失败 / 半数失败 / 从没成功过 / 读到一条没金额的。
/// 这是 SPEC 第 10 节「单家失败不影响其他家，失败的行显示上次成功的数据，不显示 0」
/// 的直接保护——以前这条承诺一条测试都没有。
@MainActor
struct RefreshPipelineTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 16, hour: 12))!
    }

    private func snapshot(_ providerID: ProviderID, accountID: AccountID, spend: Decimal?, fetchedAt: Date? = nil) -> Snapshot {
        Snapshot(
            providerID: providerID,
            accountID: accountID,
            kind: .usage,
            fetchedAt: fetchedAt ?? now,
            periodStart: calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!,
            periodEnd: calendar.date(from: DateComponents(year: 2026, month: 8, day: 31, hour: 23, minute: 59, second: 59))!,
            currentSpendUSD: spend.map { Money(usd: $0) }
        )
    }

    private func makeDashboard(providers: [ProviderID: any BillingProvider]) throws -> DashboardModel {
        DashboardModel(
            providers: providers,
            container: try PersistenceContainer.makeContainer(inMemory: true),
            credentials: InMemoryCredentialStore(),
            clock: MeterClock(now: now, calendar: calendar),
            httpClient: StubHTTPClient()
        )
    }

    private func connect(
        _ dashboard: DashboardModel,
        _ providerID: ProviderID,
        accountID: AccountID,
        initialSpend: Decimal?
    ) async throws {
        try dashboard.applyConnection(
            accountID: accountID,
            providerID: providerID,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: "test-\(providerID.rawValue)-\(accountID.rawValue.uuidString)",
            fields: [
                CredentialField.apiToken.rawValue: "tok",
                CredentialField.accountID.rawValue: "acc",
            ],
            snapshots: initialSpend.map { [snapshot(providerID, accountID: accountID, spend: $0, fetchedAt: now.addingTimeInterval(-3600))] } ?? [],
            mode: .create
        )
        // 折叠在后台排（`loadFromPersistence` 结尾那个 Task）。同步调用链一返回
        // 它还没跑——测试里显式等一趟。
        await dashboard.syncLedger()
    }

    @Test("成功：新读数落库、进账本、合计跟着变，行标成新鲜")
    func successPersistsAndRecomputes() async throws {
        let id = AccountID.fixture(for: .cloudflare)
        let dashboard = try makeDashboard(providers: [
            .cloudflare: ScriptedProvider(.success(snapshot(.cloudflare, accountID: id, spend: 20))),
        ])
        try await connect(dashboard, .cloudflare, accountID: id, initialSpend: 10)
        #expect(dashboard.monthToDate?.totalUSD == Money(usd: 10))
        let before = dashboard.debugReadingCount

        await dashboard.refresh()

        #expect(dashboard.debugReadingCount == before + 1)
        #expect(dashboard.monthToDate?.totalUSD == Money(usd: 20))
        #expect(dashboard.providerMarks[id] == .current)
        #expect(dashboard.refreshSuccessToken == 1)
        #expect(dashboard.refreshFailureCaption == nil)
    }

    @Test("全部失败：仍显示上次的数字，不是 0；行标陈旧，横幅说明")
    func failureKeepsLastNumbers() async throws {
        let id = AccountID.fixture(for: .cloudflare)
        let dashboard = try makeDashboard(providers: [
            .cloudflare: ScriptedProvider(.failure),
        ])
        try await connect(dashboard, .cloudflare, accountID: id, initialSpend: 10)
        let before = dashboard.debugReadingCount

        await dashboard.refresh()

        #expect(dashboard.debugReadingCount == before, "失败不写快照")
        #expect(dashboard.monthToDate?.totalUSD == Money(usd: 10))
        #expect(dashboard.providerMarks[id] == .stale)
        #expect(dashboard.refreshSuccessToken == 0)
        #expect(dashboard.refreshFailureCaption != nil)
    }

    @Test("半数失败：成的那家更新，败的那家留旧数，不弹全局失败")
    func partialFailureIsPerAccount() async throws {
        let cf = AccountID.fixture(for: .cloudflare)
        let neon = AccountID.fixture(for: .neon)
        let dashboard = try makeDashboard(providers: [
            .cloudflare: ScriptedProvider(.success(snapshot(.cloudflare, accountID: cf, spend: 20))),
            .neon: ScriptedProvider(.failure),
        ])
        try await connect(dashboard, .cloudflare, accountID: cf, initialSpend: 10)
        try await connect(dashboard, .neon, accountID: neon, initialSpend: 5)
        #expect(dashboard.monthToDate?.totalUSD == Money(usd: 15))

        await dashboard.refresh()

        #expect(dashboard.monthToDate?.totalUSD == Money(usd: 25))
        #expect(dashboard.providerMarks[cf] == .current)
        #expect(dashboard.providerMarks[neon] == .stale)
        #expect(dashboard.refreshSuccessToken == 1)
        #expect(dashboard.refreshFailureCaption == nil)
    }

    @Test("从没成功过的家失败：标「失败」不是「陈旧」")
    func neverSucceededIsFailedNotStale() async throws {
        let id = AccountID.fixture(for: .cloudflare)
        let dashboard = try makeDashboard(providers: [
            .cloudflare: ScriptedProvider(.failure),
        ])
        try await connect(dashboard, .cloudflare, accountID: id, initialSpend: nil)

        await dashboard.refresh()

        #expect(dashboard.providerMarks[id] == .failed)
    }

    @Test("读到一条没金额的快照：落库但不算成功，合计不变、行标陈旧")
    func unbillableSnapshotIsStale() async throws {
        let id = AccountID.fixture(for: .cloudflare)
        let dashboard = try makeDashboard(providers: [
            .cloudflare: ScriptedProvider(.success(snapshot(.cloudflare, accountID: id, spend: nil))),
        ])
        try await connect(dashboard, .cloudflare, accountID: id, initialSpend: 10)

        await dashboard.refresh()

        // 一条「接了但没读到数」的快照不能被当成 $0 计入总数。
        #expect(dashboard.monthToDate?.totalUSD == Money(usd: 10))
        #expect(dashboard.providerMarks[id] == .stale)
    }
}

private struct ScriptedProvider: BillingProvider {
    enum Script: Sendable {
        case success(Snapshot)
        case failure
    }

    struct Failed: Error {}

    var script: Script

    init(_ script: Script) {
        self.script = script
    }

    func fetch(credential: Credential) async throws -> Snapshot {
        switch script {
        case .success(let snapshot): return snapshot
        case .failure: throw Failed()
        }
    }
}
