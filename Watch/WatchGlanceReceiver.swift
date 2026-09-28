import Foundation
import WatchConnectivity
import WatchKit
import WidgetKit
import MeterGlance

/// 手表这头的 WatchConnectivity：收 iPhone 推来的 `Glance`，落盘给表盘读，再换掉屏幕上那份。
///
/// 三条通道收到的是同一种东西（`GlanceCodec` 那一份），谁先到谁后到都一样处理：
/// 比手上旧的丢掉（`GlanceStore.saveIfNewer`）。
final class WatchGlanceReceiver: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = WatchGlanceReceiver()

    private let store = GlanceStore.live()
    /// 收完才能结束的后台任务。不结束的话，表盘刷新会被算作「App 在后台赖着不走」。
    private let pendingTasks = PendingRefreshTasks()
    private let lock = NSLock()
    private var isActivated = false

    override private init() {
        super.init()
    }

    /// 启动时和被后台叫醒时都会来，只激活一次。
    func activate() {
        guard WCSession.isSupported() else { return }
        let first = lock.withLock {
            defer { isActivated = true }
            return !isActivated
        }
        guard first else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func requestLatest() {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return }
        session.sendMessage([GlanceCodec.requestKey: true]) { [weak self] reply in
            if let glance = GlanceCodec.glance(in: reply) {
                self?.accept(glance)
            }
        } errorHandler: { _ in
            // iPhone 不在身边、或者 App 被杀了：屏幕上那份照旧，等下一次推送。
        }
    }

    func holdUntilDelivered(_ task: WKWatchConnectivityRefreshBackgroundTask) {
        pendingTasks.add(task)
        finishTasksIfIdle()
    }

    private func accept(_ glance: Glance) {
        guard store.saveIfNewer(glance) else { return }
        WidgetCenter.shared.reloadAllTimelines()
        Task { @MainActor in
            WatchGlanceModel.shared.glance = glance
        }
    }

    private func finishTasksIfIdle() {
        let session = WCSession.default
        guard session.activationState == .activated, !session.hasContentPending else { return }
        pendingTasks.completeAll()
    }

    // MARK: WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // 手表 App 没开着的时候推来的那份，激活后在这里。
        if let glance = GlanceCodec.glance(in: session.receivedApplicationContext) {
            accept(glance)
        }
        finishTasksIfIdle()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let glance = GlanceCodec.glance(in: applicationContext) {
            accept(glance)
        }
        finishTasksIfIdle()
    }

    /// 复杂功能那条通道：iPhone 用它把后台的我们叫醒去刷表盘。
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        if let glance = GlanceCodec.glance(in: userInfo) {
            accept(glance)
        }
        finishTasksIfIdle()
    }
}
