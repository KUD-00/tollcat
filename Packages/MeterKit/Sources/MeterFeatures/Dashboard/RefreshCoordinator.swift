import Foundation
import Observation
import MeterCore
import MeterInbox
import MeterPersistence
import MeterProviders

/// 刷新编排：全局 / 单账号两把锁 + 并发拉账单 + 信箱泳道的先后次序。
/// 结果逐条回给 `consume`——快照怎么落、标记怎么打、token 怎么涨，
/// 是 `DashboardModel` 的事，这里只保证「同一把锁不重入、泳道跑完才算完」。
@MainActor
@Observable
final class RefreshCoordinator {
    enum Lock {
        case global
        case account(AccountID)
    }

    enum RunResult {
        /// 这把锁正被占用，什么都没做。
        case lockBusy
        /// 锁拿到了，但没有任何可刷新的目标。
        case nothingToRefresh
        case ran
    }

    private(set) var isRefreshing = false
    /// 付费账号刷新、以及 `refresh(accountID:)` 的那一行。
    private(set) var refreshingAccountIDs: Set<AccountID> = []

    private let inboxClient: InboxClient
    private let credentials: any CredentialStore

    init(inboxClient: InboxClient, credentials: any CredentialStore) {
        self.inboxClient = inboxClient
        self.credentials = credentials
    }

    /// 拿着某个账号的锁跑一段**不是刷新**的取数（现在只有历史回填）。
    ///
    /// 回 `nil` 表示锁被占着，一步都没做。
    ///
    /// 回填以前完全绕开这里：用户在详情页点「拉取更多历史」的同时下拉刷新，
    /// 同一个账号会有两条几乎同时的请求各自落一条快照，而那一行连转圈都没有——
    /// 界面上看不出正在发生两件事。锁是这一层的全部职责，绕开它就等于没有锁。
    ///
    /// 不并进 `run`：回填的失败语义和刷新不同（不标 stale、不改横幅、不算 tally），
    /// 硬塞进同一条管线只会让那条管线多两个分支。共用的是**锁**，不是流程。
    func withAccountLock<T>(_ id: AccountID, _ body: () async -> T) async -> T? {
        guard !refreshingAccountIDs.contains(id) else { return nil }
        refreshingAccountIDs.insert(id)
        defer { refreshingAccountIDs.remove(id) }
        return await body()
    }

    func run(
        jobs: [BillingRefreshJob],
        inboxTargets: [InboxRefreshTarget],
        lock: Lock,
        calendar: Calendar,
        consume: @MainActor (BillingRefreshOutcome) async -> Void
    ) async -> RunResult {
        let involved = Set(jobs.map(\.id) + inboxTargets.map(\.accountID))
        switch lock {
        case .global:
            guard !isRefreshing else { return .lockBusy }
            isRefreshing = true
            refreshingAccountIDs.formUnion(involved)
        case .account(let id):
            guard !refreshingAccountIDs.contains(id) else { return .lockBusy }
            refreshingAccountIDs.insert(id)
        }
        defer {
            switch lock {
            case .global:
                isRefreshing = false
                refreshingAccountIDs.subtract(involved)
            case .account(let id):
                refreshingAccountIDs.remove(id)
            }
        }

        guard !jobs.isEmpty || !inboxTargets.isEmpty else {
            return .nothingToRefresh
        }

        await withTaskGroup(of: BillingRefreshOutcome.self) { group in
            for job in jobs {
                group.addTask {
                    await BillingRefresh.fetchOne(job)
                }
            }

            for await outcome in group {
                await consume(outcome)
            }
        }

        for outcome in await InboxRefreshLane.run(
            targets: inboxTargets,
            client: inboxClient,
            credentials: credentials,
            calendar: calendar
        ) {
            await consume(outcome)
        }
        return .ran
    }

    /// 全局刷新收谁：`costsMoneyToRefresh` 的家默认不进，除非用户显式勾了。
    ///
    /// `now` 有值时，还要过 `RefreshCadence`：对方按天限流的家，间隔内已成功的不打。
    /// 接入测试和历史回填不走这里。
    static func refreshTargets(
        connections: [ProviderConnectionState],
        includePaid: Bool,
        now: Date? = nil
    ) -> [AccountID] {
        connections.compactMap { state in
            guard state.isLive else { return nil }
            guard let descriptor = ProviderCatalog.descriptor(id: state.providerID) else { return nil }
            if descriptor.costsMoneyToRefresh {
                if !(includePaid || state.includeInGlobalRefresh) { return nil }
            }
            if let now, !RefreshCadence.shouldFetch(
                lastSuccessfulRefreshAt: state.lastSuccessfulRefreshAt,
                now: now,
                minimumInterval: descriptor.minimumRefreshInterval
            ) {
                return nil
            }
            return state.accountID
        }
    }

    /// 自动刷新（亮屏）收谁：在 `refreshTargets` 的基础上，把还在保鲜期里的家去掉。
    ///
    /// **按账号过滤，不是按整批开关。** 11 家一分钟前刚成功、1 家失败了，下次亮屏
    /// 只重试失败的那一家；整批的「距上次自动刷新够久了吗」做不到这件事，它要么
    /// 把 11 家白刷一遍，要么把失败的那家一起压住。
    ///
    /// 判据是 `lastSuccessfulRefreshAt`——刷新落盘时已经在盖章（见
    /// `DashboardModel.refreshDidPersist`），不需要为这件事新记一份状态。
    /// **从没成功过的家一律要刷**：nil 不是「刚刷过」。
    ///
    /// 保鲜期是全局默认和这家 `minimumRefreshInterval` 里更严的那个。
    static func autoRefreshTargets(
        connections: [ProviderConnectionState],
        includePaid: Bool = false,
        now: Date,
        freshness: TimeInterval
    ) -> [AccountID] {
        let eligible = Set(refreshTargets(connections: connections, includePaid: includePaid))
        return connections.compactMap { state in
            guard eligible.contains(state.accountID) else { return nil }
            guard let descriptor = ProviderCatalog.descriptor(id: state.providerID) else {
                return state.accountID
            }
            let interval = RefreshCadence.autoInterval(
                minimumRefreshInterval: descriptor.minimumRefreshInterval,
                defaultFreshness: freshness
            )
            return RefreshCadence.shouldFetch(
                lastSuccessfulRefreshAt: state.lastSuccessfulRefreshAt,
                now: now,
                minimumInterval: interval
            ) ? state.accountID : nil
        }
    }

    static func inboxTargets(
        connections: [ProviderConnectionState],
        ids: [AccountID]
    ) -> [InboxRefreshTarget] {
        let wanted = Set(ids)
        return connections.compactMap { state in
            guard state.isLive, state.usesInbox, wanted.contains(state.accountID) else {
                return nil
            }
            return InboxRefreshTarget(
                accountID: state.accountID,
                providerID: state.providerID,
                ingestKeyID: state.inboxIngestKeyID
            )
        }
    }
}
