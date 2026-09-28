import Foundation
import Testing
import MeterCore
import MeterInbox
import MeterPersistence
@testable import MeterFeatures

/// 全局锁和单账号锁必须互斥，且谁拿的锁谁放。
/// 以前两种锁各看各的判据：回填占着 A 时全局照样开跑，同一家两条请求在飞、两条快照落盘；
/// 全局收尾的 `subtract` 还会把单账号那条刚插进去的 id 一起删掉。
@MainActor
struct RefreshCoordinatorLockTests {
    private let render = InboxLaneHarness.target(.render, key: "key_render")
    private let expo = InboxLaneHarness.target(.expo, key: "key_expo")

    private func makeCoordinator() -> RefreshCoordinator {
        RefreshCoordinator(
            inboxClient: InboxClient(transport: InboxLaneHarness.transport(readings: [
                ("render", "key_render", "5.00"),
            ])),
            credentials: InboxLaneHarness.storeWithMailbox()
        )
    }

    @Test("账号被回填占着时，涉及它的全局刷新和同账号刷新都算忙，且不释放别人的锁")
    func accountLockBlocksGlobalAndAccount() async {
        let coordinator = makeCoordinator()
        let render = render
        var globalResult: RefreshCoordinator.RunResult?
        var accountResult: RefreshCoordinator.RunResult?
        var nestedBackfill: Bool?
        var stillHeld = false

        let ran = await coordinator.withAccountLock(render.accountID) {
            globalResult = await coordinator.run(
                jobs: [],
                inboxTargets: [render],
                lock: .global,
                calendar: InboxLaneHarness.calendar
            ) { _ in }
            accountResult = await coordinator.run(
                jobs: [],
                inboxTargets: [render],
                lock: .account(render.accountID),
                calendar: InboxLaneHarness.calendar
            ) { _ in }
            nestedBackfill = await coordinator.withAccountLock(render.accountID) { true }
            // 被拒的那几次不能把回填拿着的锁顺手放掉。
            stillHeld = coordinator.refreshingAccountIDs.contains(render.accountID)
            #expect(!coordinator.isRefreshing)
            return true
        }

        #expect(ran == true)
        #expect(isBusy(globalResult))
        #expect(isBusy(accountResult))
        #expect(nestedBackfill == nil)
        #expect(stillHeld)
        #expect(coordinator.refreshingAccountIDs.isEmpty)
    }

    @Test("全局刷新进行中，回填和任何单账号刷新都算忙；全局收尾后锁全部放开")
    func globalLockBlocksAccountLanes() async {
        let coordinator = makeCoordinator()
        let render = render
        let expo = expo
        var backfillDuringGlobal: Bool?
        var accountDuringGlobal: RefreshCoordinator.RunResult?
        var otherAccountDuringGlobal: RefreshCoordinator.RunResult?

        let result = await coordinator.run(
            jobs: [],
            inboxTargets: [render],
            lock: .global,
            calendar: InboxLaneHarness.calendar
        ) { _ in
            backfillDuringGlobal = await coordinator.withAccountLock(render.accountID) { true }
            accountDuringGlobal = await coordinator.run(
                jobs: [],
                inboxTargets: [render],
                lock: .account(render.accountID),
                calendar: InboxLaneHarness.calendar
            ) { _ in }
            // 不在这批里的账号也要等：全局在跑时不另开一条泳道。
            otherAccountDuringGlobal = await coordinator.run(
                jobs: [],
                inboxTargets: [expo],
                lock: .account(expo.accountID),
                calendar: InboxLaneHarness.calendar
            ) { _ in }
            #expect(coordinator.refreshingAccountIDs == [render.accountID])
        }

        #expect(isRan(result))
        #expect(backfillDuringGlobal == nil)
        #expect(isBusy(accountDuringGlobal))
        #expect(isBusy(otherAccountDuringGlobal))
        #expect(!coordinator.isRefreshing)
        #expect(coordinator.refreshingAccountIDs.isEmpty)

        let afterwards = await coordinator.withAccountLock(render.accountID) { true }
        #expect(afterwards == true)
    }

    @Test("不相干的账号锁互不影响，各放各的")
    func disjointAccountLocksCoexist() async {
        let coordinator = makeCoordinator()
        let render = render
        let expo = expo
        var innerRan: Bool?
        var afterInner: Set<AccountID> = []

        _ = await coordinator.withAccountLock(render.accountID) {
            innerRan = await coordinator.withAccountLock(expo.accountID) { true }
            afterInner = coordinator.refreshingAccountIDs
            return true
        }

        #expect(innerRan == true)
        #expect(afterInner == [render.accountID])
        #expect(coordinator.refreshingAccountIDs.isEmpty)
    }

    private func isBusy(_ result: RefreshCoordinator.RunResult?) -> Bool {
        if case .lockBusy? = result { return true }
        return false
    }

    private func isRan(_ result: RefreshCoordinator.RunResult?) -> Bool {
        if case .ran? = result { return true }
        return false
    }
}
