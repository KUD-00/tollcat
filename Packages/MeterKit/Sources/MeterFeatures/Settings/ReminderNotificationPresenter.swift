import Foundation
import UserNotifications

/// 前台也出横幅。delegate 是弱引用，由 `RootView` 留住这份实例。
///
/// 系统在通知回调里不保证主线程；回调只读一次闭包再 hop 到主线程，
/// 不要在 `MainActor.run` 里抓 `self`。
final class ReminderNotificationPresenter: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    /// 点通知进来：落到设置，提醒那一组就在第一屏。
    var onOpenSettings: (@Sendable @MainActor () -> Void)?

    func install() {
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        guard notification.request.identifier.hasPrefix(UserNotificationReminderScheduler.identifierPrefix) else {
            return []
        }
        return [.banner, .sound, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.notification.request.identifier.hasPrefix(
            UserNotificationReminderScheduler.identifierPrefix
        ) else { return }
        let open = onOpenSettings
        await open?()
    }
}
