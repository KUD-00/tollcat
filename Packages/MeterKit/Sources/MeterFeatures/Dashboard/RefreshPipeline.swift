import Foundation
import Observation
import SwiftData
import MeterCore
import MeterInbox
import MeterModules
import MeterPersistence
import MeterProviders

/// 刷新管线在做完一件事之后要宿主（`DashboardModel`）配合的几步。
///
/// 管线自己管「取数 → 落盘 → 打标记 → 记账（成功几家、横幅说什么）」；
/// 账本增量、给 connections 盖章、展示重算这些是宿主的状态，管线只喊一声。
@MainActor
protocol RefreshPipelineHost: AnyObject {
    var refreshCalendar: Calendar { get }
    /// 一条读数**已经落盘**。宿主在这里做账本增量、给这家的 connection 盖上次成功时间。
    func refreshDidPersist(_ snapshot: Snapshot, for id: AccountID) async
    /// 这家的新鲜度标记刚被改过（成功 / 陈旧 / 失败都算）。宿主据此推进展示版本。
    func refreshDidMark(_ id: AccountID)
    /// 这家有没有过**读到数**的读数。失败时决定标「陈旧」还是「失败」。
    func refreshHasBillableReading(_ id: AccountID) -> Bool
    /// 这家有没有过任何读数。
    func refreshHasAnyReading(_ id: AccountID) -> Bool
    /// 刷新开始：节流从这一刻算，头一条结果也让进场动画先画完。
    func refreshWillStart()
    func refreshRebuildThrottled() async
    func refreshFlushPendingRebuild() async
    func refreshRebuildNow()
}

/// 刷新管线：一批账号进来，取数、落盘、打标记、算成败，逐条喊宿主重算。
///
/// 从 `DashboardModel` 里拆出来的一块。拆的理由是它的状态是**自己一组**：
/// 每家的新鲜度标记、全局失败的横幅、成功计数、开发页那行摘要——只有刷新这条路
/// 会写它们，别的写库路径一个都不碰。留在模型里，它们就和版式、猫、账本混在
/// 同一个 1400 行的类里，改刷新逻辑要在整个模型里找。
///
/// 依赖只到取数（providers / credentials / container）和 `RefreshCoordinator` 的两把锁。
/// 宿主通过 `RefreshPipelineHost` 接回调，没有反向引用模型。
@MainActor
@Observable
final class RefreshPipeline {
    /// 每家读数的新鲜度。`loadFromPersistence` 之后一律先当「新鲜」，刷新路径上再改。
    private(set) var providerMarks: [AccountID: ProviderDataMark] = [:]
    /// 全局刷新全部失败时的行内说明。有旧数据就留着，不弹 alert。
    private(set) var refreshFailureCaption: String?
    /// 每次至少一家成功就加一。服务页据此知道该重读。
    private(set) var refreshSuccessToken = 0
    #if DEBUG
    /// 开发页「刷新日志」顶上那一行。不进正式包。
    private(set) var lastRefreshSummary = ""
    #endif

    var isRefreshing: Bool { coordinator.isRefreshing }
    /// 付费账号刷新、以及 `refresh(accountID:)` 的那一行。
    var refreshingAccountIDs: Set<AccountID> { coordinator.refreshingAccountIDs }

    private let coordinator: RefreshCoordinator
    private let container: ModelContainer
    private let credentials: any CredentialStore
    private let providers: [ProviderID: any BillingProvider]
    private weak var host: (any RefreshPipelineHost)?

    init(
        container: ModelContainer,
        credentials: any CredentialStore,
        providers: [ProviderID: any BillingProvider],
        inboxClient: InboxClient
    ) {
        self.container = container
        self.credentials = credentials
        self.providers = providers
        self.coordinator = RefreshCoordinator(inboxClient: inboxClient, credentials: credentials)
    }

    /// 宿主持有管线，所以宿主在自己初始化完之后再接上来。
    func attach(host: any RefreshPipelineHost) {
        self.host = host
    }

    // MARK: - 标记

    /// 有读数的账号一律先当「新鲜」：失败的标记只在刷新路径上打。
    func resetMarks(currentAccounts: some Sequence<AccountID>) {
        providerMarks = Dictionary(
            uniqueKeysWithValues: currentAccounts.map { ($0, ProviderDataMark.current) }
        )
    }

    /// 预览 / 截图用：把一家标成刷新失败的样子。
    func markStale(_ id: AccountID) {
        applyFailure(id: id)
    }

    func clearFailureCaption() {
        refreshFailureCaption = nil
    }

    // MARK: - 刷新

    private final class Tally {
        var successCount = 0
        var persistedCount = 0
        var sawFailure = false
    }

    func run(
        ids: [AccountID],
        lock: RefreshCoordinator.Lock,
        connections: [ProviderConnectionState]
    ) async {
        guard let host else { return }
        // 锁在 coordinator 里，这里先探一眼只是为了保持「重入时什么都不说」的老行为。
        switch lock {
        case .global:
            guard !coordinator.isRefreshing else { return }
        case .account(let id):
            guard !coordinator.refreshingAccountIDs.contains(id) else { return }
        }

        let jobs = await BillingRefreshJobs.makeOffMain(
            ids: ids,
            container: container,
            credentials: credentials,
            providers: providers
        )
        let inboxTargets = RefreshCoordinator.inboxTargets(connections: connections, ids: ids)
        guard !jobs.isEmpty || !inboxTargets.isEmpty else {
            #if DEBUG
            lastRefreshSummary = String(localized: L("没有可刷新的接入"))
            TollCatLog.event("refresh", "refresh skipped, nothing refreshable")
            #endif
            return
        }

        #if DEBUG
        let started = ContinuousClock.now
        let names = (
            jobs.map { "\($0.providerID.rawValue):\($0.id.rawValue.uuidString)" }
                + inboxTargets.map { "\($0.providerID.rawValue):\($0.accountID.rawValue.uuidString)" }
        ).joined(separator: ",")
        TollCatLog.event("refresh", "refresh start \(names)")
        #endif

        let tally = Tally()
        // 头一条结果也让节流卡一下：冷启动 / 回到前台时自动刷新和进场动画同时开始，
        // 立刻重算会把刚画到一半的圆环打断。
        host.refreshWillStart()
        let result = await coordinator.run(
            jobs: jobs,
            inboxTargets: inboxTargets,
            lock: lock,
            calendar: host.refreshCalendar
        ) { [weak self] outcome in
            guard let self, let host = self.host else { return }
            switch outcome {
            case .success(let id, let snapshot):
                // 落盘失败不算成功：数字没写进去，横幅不能说刷新成了。
                if await self.applySuccess(id: id, snapshot: snapshot) {
                    tally.persistedCount += 1
                    tally.successCount += 1
                } else {
                    tally.sawFailure = true
                }
            case .failure(let id):
                tally.sawFailure = true
                self.applyFailure(id: id)
            case .skipped:
                break
            }
            await host.refreshRebuildThrottled()
        }
        await host.refreshFlushPendingRebuild()
        guard case .ran = result else { return }

        if tally.successCount > 0 {
            refreshSuccessToken += 1
            refreshFailureCaption = nil
        } else if tally.sawFailure {
            refreshFailureCaption = String(localized: L("刷新失败，仍显示上次的数字"))
        }
        #if DEBUG
        let total = jobs.count + inboxTargets.count
        let elapsedMs = Int((ContinuousClock.now - started) / .milliseconds(1))
        lastRefreshSummary = String(localized: L("\(tally.successCount) 成功 · \(total) 家 · \(elapsedMs)ms"))
        TollCatLog.event(
            "refresh",
            "refresh done ok=\(tally.successCount) persist=\(tally.persistedCount) \(elapsedMs)ms"
        )
        #endif
        if tally.persistedCount > 0 {
            WidgetTimelineReloader.reloadAfterStoreWrite()
        }
    }

    /// 接入之后、详情页「拉取更多历史」：拉这家能给的最长窗口，写成一条 Snapshot。
    /// 失败不改已有读数，也不把行标成 stale。
    ///
    /// **走和刷新同一把账号锁**（`withAccountLock`）。它以前完全绕开锁：
    /// 用户点「拉取更多历史」的同时下拉刷新，同一个账号两条请求各落一条快照，
    /// 而那一行连转圈都没有——界面上看不出正在发生两件事。锁被占着就什么都不做，
    /// 和 `refresh(accountID:)` 重入时的行为一致。
    func backfill(accountID: AccountID, connections: [ProviderConnectionState]) async -> Bool {
        await coordinator.withAccountLock(accountID) {
            await runBackfill(accountID: accountID, connections: connections)
        } ?? false
    }

    private func runBackfill(accountID: AccountID, connections: [ProviderConnectionState]) async -> Bool {
        guard let host, let state = connections.first(where: { $0.accountID == accountID }) else {
            return false
        }
        guard let months = ProviderCatalog.descriptor(id: state.providerID)?.historyLookbackMonths, months > 0 else {
            return false
        }
        let jobs = await BillingRefreshJobs.makeOffMain(
            ids: [accountID],
            container: container,
            credentials: credentials,
            providers: providers
        )
        guard let job = jobs.first else { return false }
        do {
            var snapshot = try await job.provider.fetch(
                credential: job.credential,
                horizon: .availableHistory
            )
            snapshot.accountID = accountID
            let wrote = await applySuccess(id: accountID, snapshot: snapshot)
            host.refreshRebuildNow()
            if wrote {
                WidgetTimelineReloader.reloadAfterStoreWrite()
            }
            #if DEBUG
            TollCatLog.event(
                "refresh",
                "history backfill ok \(state.providerID.rawValue) \(accountID.rawValue.uuidString) days=\(snapshot.dailyUSD?.count ?? 0)"
            )
            #endif
            return snapshot.hasBillableMetrics
        } catch {
            #if DEBUG
            TollCatLog.event(
                "refresh",
                "history backfill fail \(state.providerID.rawValue) \(accountID.rawValue.uuidString) \(String(describing: error))"
            )
            #endif
            return false
        }
    }

    @discardableResult
    private func applySuccess(id: AccountID, snapshot: Snapshot) async -> Bool {
        guard let host else { return false }
        var stamped = snapshot
        stamped.accountID = id
        // 先落盘再改内存：save 失败时界面不能先说成功，重启后又吐回旧数字。
        let persisted: Bool
        do {
            persisted = try await SnapshotWriter.persistOffMain(
                stamped,
                into: container,
                calendar: host.refreshCalendar
            )
        } catch {
            applyFailure(id: id)
            return false
        }
        await host.refreshDidPersist(stamped, for: id)
        if stamped.hasBillableMetrics {
            providerMarks[id] = .current
        } else if host.refreshHasBillableReading(id) {
            providerMarks[id] = .stale
        } else {
            providerMarks[id] = .failed
        }
        host.refreshDidMark(id)
        return persisted
    }

    private func applyFailure(id: AccountID) {
        // 这家曾经读到过数，这次是陈旧，不是从没成功。
        if host?.refreshHasAnyReading(id) == true {
            providerMarks[id] = .stale
        } else {
            providerMarks[id] = .failed
        }
        // 标记变了就得推进版本，否则详情页的行缓存继续命中，那一页永远不亮「陈旧」。
        host?.refreshDidMark(id)
    }
}
