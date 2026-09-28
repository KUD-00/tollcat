import WatchKit

/// 手表 App 的生命周期只用来做两件事：尽早接上 WatchConnectivity，
/// 以及在系统为了收数把我们从后台叫醒时，收完再让系统走。
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        WatchGlanceReceiver.shared.activate()
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let connectivity = task as? WKWatchConnectivityRefreshBackgroundTask {
                WatchGlanceReceiver.shared.activate()
                WatchGlanceReceiver.shared.holdUntilDelivered(connectivity)
            } else {
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
