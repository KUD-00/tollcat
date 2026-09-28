import Foundation
import WatchKit

/// 系统为了收数把手表 App 从后台叫醒时给的任务，收完才能结束。
/// WatchConnectivity 的回调在它自己的队列上，所以带一把锁。
final class PendingRefreshTasks: @unchecked Sendable {
    private let lock = NSLock()
    private var tasks: [WKWatchConnectivityRefreshBackgroundTask] = []

    func add(_ task: WKWatchConnectivityRefreshBackgroundTask) {
        lock.withLock { tasks.append(task) }
    }

    func completeAll() {
        let finished = lock.withLock {
            defer { tasks.removeAll() }
            return tasks
        }
        for task in finished {
            task.setTaskCompletedWithSnapshot(false)
        }
    }
}
