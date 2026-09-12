import Foundation
import SwiftData
import Testing
import MeterCore
import MeterPersistence
import MeterProviders
@testable import MeterFeatures

@MainActor
struct UsageRefreshOnActivateTests {
    @Test("开关关上、没走完引导、正在刷、没有可刷的服务，都不刷")
    func policyRequiresEveryCondition() {
        #expect(
            UsageRefreshOnActivate.shouldRefresh(
                isEnabled: false,
                hasCompletedOnboarding: true,
                isAlreadyRefreshing: false,
                hasRefreshableProviders: true
            ) == false
        )
        #expect(
            UsageRefreshOnActivate.shouldRefresh(
                isEnabled: true,
                hasCompletedOnboarding: false,
                isAlreadyRefreshing: false,
                hasRefreshableProviders: true
            ) == false
        )
        #expect(
            UsageRefreshOnActivate.shouldRefresh(
                isEnabled: true,
                hasCompletedOnboarding: true,
                isAlreadyRefreshing: true,
                hasRefreshableProviders: true
            ) == false
        )
        #expect(
            UsageRefreshOnActivate.shouldRefresh(
                isEnabled: true,
                hasCompletedOnboarding: true,
                isAlreadyRefreshing: false,
                hasRefreshableProviders: false
            ) == false
        )
        #expect(
            UsageRefreshOnActivate.shouldRefresh(
                isEnabled: true,
                hasCompletedOnboarding: true,
                isAlreadyRefreshing: false,
                hasRefreshableProviders: true
            )
        )
    }

    @Test("开关关上时进入前台不刷")
    func disabledDoesNotRefresh() async {
        let model = DashboardModel.preview
        let token = model.refreshSuccessToken
        await model.refreshUsageIfNeededOnActivate()
        #expect(model.refreshSuccessToken == token)
    }

    @Test("开关打开且有可刷的服务时进入前台会刷")
    func enabledRefreshesConnectedProviders() async {
        let model = DashboardModel.preview
        model.setRefreshesUsageOnActivate(true)
        await model.refreshUsageIfNeededOnActivate()
        // Preview 的传输是空 stub，真适配器会失败；失败文案说明确实发出去了。
        #expect(model.refreshFailureCaption != nil)
    }

    @Test("没走完引导不刷")
    func skipsDuringOnboarding() async {
        let model = DashboardModel.preview
        model.setRefreshesUsageOnActivate(true)
        model.shell.replayOnboarding()
        let token = model.refreshSuccessToken
        await model.refreshUsageIfNeededOnActivate()
        #expect(model.refreshSuccessToken == token)
    }

    @Test("一家都没接时不刷")
    func skipsWhenNothingToRefresh() async {
        let model = DashboardModel.previewEmpty
        model.setRefreshesUsageOnActivate(true)
        let token = model.refreshSuccessToken
        await model.refreshUsageIfNeededOnActivate()
        #expect(model.refreshSuccessToken == token)
    }

    @Test("设置页开关会落到偏好里")
    func settingsTogglePersists() throws {
        let dashboard = DashboardModel.preview
        let settings = SettingsModel(
            dashboard: dashboard,
            persistenceStatus: .preview,
            reminderScheduler: InMemoryReminderScheduler()
        )
        #expect(settings.refreshesUsageOnActivate == false)
        settings.setRefreshesUsageOnActivate(true)
        #expect(settings.refreshesUsageOnActivate)
        #expect(dashboard.refreshesUsageOnActivate())
        let stored = try AppPreferencesRecord.load(from: ModelContext(dashboard.storeContainer))
        #expect(stored.refreshesUsageOnActivate)
    }
}

/// 亮屏自动刷新的保鲜期。**这一组是 SPEC 之外的一条用户可感承诺**：
/// 锁屏再解锁不是一轮全量取数。没有它的时候，连续亮屏三次 = 三轮请求，
/// 而每一条回来都让正在看的详情页整页重算。
@MainActor
struct AutoRefreshFreshnessTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func connection(
        _ n: UInt8,
        lastSuccessfulRefreshAt: Date?,
        providerID: ProviderID = .cloudflare
    ) -> ProviderConnectionState {
        ProviderConnectionState(
            accountID: .fixture(n),
            providerID: providerID,
            isEnabled: true,
            lastSuccessfulRefreshAt: lastSuccessfulRefreshAt,
            credentialReference: "ref-\(n)",
            includeInGlobalRefresh: true
        )
    }

    @Test("保鲜期内的家不再取数，过了的才取")
    func skipsFreshAccounts() {
        let fresh = connection(1, lastSuccessfulRefreshAt: now.addingTimeInterval(-60))
        let stale = connection(2, lastSuccessfulRefreshAt: now.addingTimeInterval(-3600))
        let targets = RefreshCoordinator.autoRefreshTargets(
            connections: [fresh, stale],
            now: now,
            freshness: UsageRefreshOnActivate.freshness
        )
        #expect(targets == [AccountID.fixture(2)])
    }

    @Test("从没成功过的家一律要刷：nil 不是「刚刷过」")
    func neverRefreshedAlwaysCounts() {
        let targets = RefreshCoordinator.autoRefreshTargets(
            connections: [connection(1, lastSuccessfulRefreshAt: nil)],
            now: now,
            freshness: UsageRefreshOnActivate.freshness
        )
        #expect(targets == [AccountID.fixture(1)])
    }

    @Test("按账号过滤，不是整批开关：只重试失败的那一家")
    func filtersPerAccountNotPerBatch() {
        let connections = (1...4).map { index -> ProviderConnectionState in
            // 3 号刚失败过（上次成功很久以前），其余三家一分钟前刚成功。
            let last = index == 3 ? now.addingTimeInterval(-86_400) : now.addingTimeInterval(-60)
            return connection(UInt8(index), lastSuccessfulRefreshAt: last)
        }
        let targets = RefreshCoordinator.autoRefreshTargets(
            connections: connections,
            now: now,
            freshness: UsageRefreshOnActivate.freshness
        )
        #expect(targets == [AccountID.fixture(3)])
    }

    @Test("盖在未来的章当成不新鲜，否则这家会被冻到那个时刻为止")
    func futureStampDoesNotFreezeRefresh() {
        let targets = RefreshCoordinator.autoRefreshTargets(
            connections: [connection(1, lastSuccessfulRefreshAt: now.addingTimeInterval(86_400))],
            now: now,
            freshness: UsageRefreshOnActivate.freshness
        )
        #expect(targets == [AccountID.fixture(1)])
    }

    @Test("保鲜期只管自动刷新：手动那条路仍然刷全部")
    func manualRefreshIgnoresFreshness() {
        let connections = (1...3).map {
            connection(UInt8($0), lastSuccessfulRefreshAt: now)
        }
        #expect(
            RefreshCoordinator.autoRefreshTargets(
                connections: connections,
                now: now,
                freshness: UsageRefreshOnActivate.freshness
            ).isEmpty
        )
        #expect(
            RefreshCoordinator.refreshTargets(
                connections: connections,
                includePaid: false
            ).count == 3
        )
    }

    @Test("按天限流的家，手动下拉也跳过间隔内已成功的")
    func dailyQuotaSkipsManualRefresh() {
        let quota = connection(
            1,
            lastSuccessfulRefreshAt: now.addingTimeInterval(-3_600),
            providerID: .neo4j
        )
        let regular = connection(
            2,
            lastSuccessfulRefreshAt: now.addingTimeInterval(-60),
            providerID: .cloudflare
        )
        let targets = RefreshCoordinator.refreshTargets(
            connections: [quota, regular],
            includePaid: false,
            now: now
        )
        #expect(targets == [AccountID.fixture(2)])
    }

    @Test("按天限流的家从没成功过，手动仍打")
    func dailyQuotaStillFetchesNeverSucceeded() {
        let targets = RefreshCoordinator.refreshTargets(
            connections: [
                connection(1, lastSuccessfulRefreshAt: nil, providerID: .neo4j),
            ],
            includePaid: false,
            now: now
        )
        #expect(targets == [AccountID.fixture(1)])
    }

    @Test("刷成功之后连着亮屏两次：一次取数都不再发生")
    func activatingRightAfterASuccessfulRefreshDoesNothing() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let counter = FetchCallCounter()
        let accountID = AccountID.fixture(for: .cloudflare)
        let snapshot = Snapshot(
            providerID: .cloudflare,
            accountID: accountID,
            kind: .usage,
            fetchedAt: now,
            periodStart: now.addingTimeInterval(-86_400 * 15),
            periodEnd: now.addingTimeInterval(86_400 * 15),
            currentSpendUSD: Money(usd: 12)
        )
        let dashboard = DashboardModel(
            providers: [.cloudflare: CountingProvider(snapshot: snapshot, counter: counter)],
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
            remoteIdentityFingerprint: "freshness-probe",
            fields: [CredentialField.apiKey.rawValue: "sk-test"],
            snapshots: [],
            mode: .create
        )
        dashboard.shell.completeOnboarding()
        dashboard.setRefreshesUsageOnActivate(true)

        await dashboard.refreshUsageIfNeededOnActivate()
        #expect(counter.count == 1)

        // 锁屏再解锁，再来一次。保鲜期内，一次请求都不该发出去。
        await dashboard.refreshUsageIfNeededOnActivate()
        await dashboard.refreshUsageIfNeededOnActivate()
        #expect(counter.count == 1)

        // 手动下拉不受保鲜期管：用户说「现在给我最新的」就是现在。
        await dashboard.refresh()
        #expect(counter.count == 2)
    }
}

private final class FetchCallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func bump() {
        lock.lock()
        value += 1
        lock.unlock()
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

private struct CountingProvider: BillingProvider {
    var snapshot: Snapshot
    var counter: FetchCallCounter

    func fetch(credential: Credential) async throws -> Snapshot {
        counter.bump()
        return snapshot
    }
}

/// 展示版本的分格。**这一组保护的是"别家刷回来时这一页不重算"**——
/// 它以前是一个全局的数，一跳就让每一屏的派生缓存全部作废，实测一次亮屏刷新
/// 让详情页重算 26 遍、占主线程 1620ms。
@MainActor
struct PresentationRevisionTests {
    @Test("刷新只动那一家那一格，别家的钥匙一个字不变")
    func readingOnlyBumpsItsOwnProvider() {
        var revision = PresentationRevision()
        let before = revision.scoped(to: .openai)
        revision.noteReading(for: .cloudflare)
        #expect(revision.scoped(to: .openai) == before)
        #expect(revision.scoped(to: .cloudflare) != before)
    }

    @Test("写库 / 换货币动的是 global，每一家的钥匙都跟着变")
    func globalChangeBumpsEveryScope() {
        var revision = PresentationRevision()
        let openai = revision.scoped(to: .openai)
        let cloudflare = revision.scoped(to: .cloudflare)
        revision.noteGlobalChange()
        #expect(revision.scoped(to: .openai) != openai)
        #expect(revision.scoped(to: .cloudflare) != cloudflare)
    }

    @Test("同一家连着刷两次，钥匙每次都变")
    func repeatedReadingsKeepBumping() {
        var revision = PresentationRevision()
        let first = revision.scoped(to: .openai)
        revision.noteReading(for: .openai)
        let second = revision.scoped(to: .openai)
        revision.noteReading(for: .openai)
        #expect(first != second)
        #expect(second != revision.scoped(to: .openai))
    }
}

/// 内存里那份原始读数。**追加只覆盖"多了一条"；改写和删除必须整份扔掉。**
@MainActor
struct ReadingCacheTests {
    private let accountID = AccountID.fixture(1)
    private let other = AccountID.fixture(2)

    private func snapshot(_ id: AccountID, at fetchedAt: Date, spend: Decimal) -> Snapshot {
        Snapshot(
            providerID: .cloudflare,
            accountID: id,
            kind: .usage,
            fetchedAt: fetchedAt,
            periodStart: fetchedAt.addingTimeInterval(-86_400),
            periodEnd: fetchedAt.addingTimeInterval(86_400),
            currentSpendUSD: Money(usd: spend)
        )
    }

    private var epoch: Date { Date(timeIntervalSince1970: 1_800_000_000) }

    @Test("头一次走 load，之后不再走")
    func loadsOnceThenServesFromMemory() {
        let cache = ReadingCache()
        var loads = 0
        let stored = [snapshot(accountID, at: epoch, spend: 1)]
        for _ in 0..<3 {
            _ = cache.readings(accountIDs: [accountID], since: epoch.addingTimeInterval(-86_400)) {
                loads += 1
                return stored
            }
        }
        #expect(loads == 1)
    }

    @Test("起点往前爬时手上那份是超集，筛一下就够，不重读")
    func laterSinceIsServedByFiltering() {
        let cache = ReadingCache()
        var loads = 0
        let old = snapshot(accountID, at: epoch, spend: 1)
        let recent = snapshot(accountID, at: epoch.addingTimeInterval(86_400), spend: 2)
        let load: () -> [Snapshot] = { loads += 1; return [old, recent] }

        _ = cache.readings(accountIDs: [accountID], since: epoch.addingTimeInterval(-1), load: load)
        let later = cache.readings(
            accountIDs: [accountID],
            since: epoch.addingTimeInterval(3_600),
            load: load
        )
        #expect(loads == 1)
        #expect(later.count == 1)
        #expect(later.first?.fetchedAt == recent.fetchedAt)
    }

    @Test("起点比手上那份更早就得重读：那份是子集，答不了")
    func earlierSinceReloads() {
        let cache = ReadingCache()
        var loads = 0
        let load: () -> [Snapshot] = { loads += 1; return [] }
        _ = cache.readings(accountIDs: [accountID], since: epoch, load: load)
        _ = cache.readings(accountIDs: [accountID], since: epoch.addingTimeInterval(-86_400), load: load)
        #expect(loads == 2)
    }

    @Test("落盘之后追加一条，不回库里重读")
    func appendAvoidsReload() {
        let cache = ReadingCache()
        var loads = 0
        let first = snapshot(accountID, at: epoch, spend: 1)
        _ = cache.readings(accountIDs: [accountID], since: epoch.addingTimeInterval(-86_400)) {
            loads += 1
            return [first]
        }
        let fresh = snapshot(accountID, at: epoch.addingTimeInterval(3_600), spend: 9)
        cache.append(fresh)
        let readings = cache.readings(accountIDs: [accountID], since: epoch.addingTimeInterval(-86_400)) {
            loads += 1
            return []
        }
        #expect(loads == 1)
        #expect(readings.count == 2)
        // 升序落定：最新那条在最后，「最近一条读数」两处指向同一个。
        #expect(readings.last?.currentSpendUSD == Money(usd: 9))
    }

    @Test("同一时刻的同一账号是替换，不叠第二条")
    func appendReplacesSameStamp() {
        let cache = ReadingCache()
        _ = cache.readings(accountIDs: [accountID], since: epoch.addingTimeInterval(-86_400)) {
            [self.snapshot(self.accountID, at: self.epoch, spend: 1)]
        }
        cache.append(snapshot(accountID, at: epoch, spend: 7))
        let readings = cache.readings(accountIDs: [accountID], since: epoch.addingTimeInterval(-86_400)) { [] }
        #expect(readings.count == 1)
        #expect(readings.first?.currentSpendUSD == Money(usd: 7))
    }

    @Test("追加只落到含这个账号的那几份上，别人的不动")
    func appendOnlyTouchesMatchingSets() {
        let cache = ReadingCache()
        let since = epoch.addingTimeInterval(-86_400)
        _ = cache.readings(accountIDs: [accountID], since: since) { [] }
        _ = cache.readings(accountIDs: [other], since: since) { [] }
        cache.append(snapshot(accountID, at: epoch, spend: 3))
        #expect(cache.readings(accountIDs: [accountID], since: since) { [] }.count == 1)
        #expect(cache.readings(accountIDs: [other], since: since) { [] }.isEmpty)
    }

    @Test("整份扔掉之后必须重读——改写和删除只能走这条路")
    func invalidateForcesReload() {
        let cache = ReadingCache()
        var loads = 0
        let load: () -> [Snapshot] = { loads += 1; return [] }
        _ = cache.readings(accountIDs: [accountID], since: epoch, load: load)
        cache.invalidate()
        _ = cache.readings(accountIDs: [accountID], since: epoch, load: load)
        #expect(loads == 2)
    }
}
