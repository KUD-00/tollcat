import Foundation

/// 「今天」变了就喊一声。
///
/// 这个 App 里几乎每个数字都挂在两个时间概念上：**今天**（同期比的是「上个月到
/// 今天为止」）和**本月**（月首按当前时区切）。两者都会在没有任何用户操作的情况下
/// 变掉——过了午夜，或者飞去另一个时区。
///
/// 少了这一声，长开不关的那两种壳（Mac 菜单栏、iPad 台前调度）会一直显示昨天的
/// 「今天」：数字看起来完全正常，只是那个百分比停在昨天，而没有任何一步会去碰它。
///
/// 只喊，不判断该重算什么——那是 `DashboardModel` 的事。
final class ClockChangeObserver {
    private let tokens: [any NSObjectProtocol]

    /// - Parameter onChange: 主线程回调。
    init(onChange: @escaping @Sendable @MainActor () -> Void) {
        let center = NotificationCenter.default
        tokens = [Notification.Name.NSCalendarDayChanged, .NSSystemTimeZoneDidChange]
            .map { name in
                center.addObserver(forName: name, object: nil, queue: .main) { _ in
                    MainActor.assumeIsolated { onChange() }
                }
            }
    }

    deinit {
        let center = NotificationCenter.default
        for token in tokens { center.removeObserver(token) }
    }
}
