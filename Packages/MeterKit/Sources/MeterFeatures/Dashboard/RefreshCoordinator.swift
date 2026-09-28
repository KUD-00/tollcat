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
    ///
    /// 由 `accountLockOwners` 推出来，不单独存：以前是一个裸 `Set`，全局那条的
    /// `subtract(involved)` 会把后来单账号那条刚插进去的 id 一起删掉，锁提前松开。
    var refreshingAccountIDs: Set<AccountID> { Set(accountLockOwners.keys) }

    /// 每个被锁住的账号归哪一次加锁。释放时只删令牌对得上的——
    /// 谁拿的锁谁放，别人的收尾碰不到它。
    private var accountLockOwners: [AccountID: UUID] = [:]

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
    ///
    /// 全局刷新进行中也算占用：全局那条正在拉这家（付费的家用户勾了进全局时尤其），
    /// 这时再开一条回填，就是同一家两条请求在飞、两条快照落盘。
    func withAccountLock<T>(_ id: AccountID, _ body: () async -> T) async -> T? {
        guard let token = acquireAccountLock(id) else { return nil }
        defer { releaseAccountLocks([id], token: token) }
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
        // 两种锁必须互斥，判据也必须是同一个：以前全局只看 `isRefreshing`、
        // 单账号只看集合，回填 / 单行刷新占着 A 时全局照样开跑，同一家两条在飞。
        // 整批被拒而不是跳过被占的那家：跳过会让横幅按「少刷了几家」去报成功。
        let heldIDs: Set<AccountID>
        let token: UUID
        switch lock {
        case .global:
            guard !isRefreshing, involved.isDisjoint(with: accountLockOwners.keys) else {
                return .lockBusy
            }
            isRefreshing = true
            token = claimAccountLocks(involved)
            heldIDs = involved
        case .account(let id):
            guard let claimed = acquireAccountLock(id) else { return .lockBusy }
            token = claimed
            heldIDs = [id]
        }
        defer {
            if case .global = lock {
                isRefreshing = false
            }
            releaseAccountLocks(heldIDs, token: token)
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

    // MARK: - 账号锁

    /// 单账号加锁：全局在跑或这家已被占，一律算忙。
    private func acquireAccountLock(_ id: AccountID) -> UUID? {
        guard !isRefreshing, accountLockOwners[id] == nil else { return nil }
        return claimAccountLocks([id])
    }

    /// 调用方已确认这些 id 都空着；这里只负责盖同一个令牌。
    private func claimAccountLocks(_ ids: Set<AccountID>) -> UUID {
        let token = UUID()
        for id in ids {
            accountLockOwners[id] = token
        }
        return token
    }

    private func releaseAccountLocks(_ ids: Set<AccountID>, token: UUID) {
        for id in ids where accountLockOwners[id] == token {
            accountLockOwners[id] = nil
        }
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
