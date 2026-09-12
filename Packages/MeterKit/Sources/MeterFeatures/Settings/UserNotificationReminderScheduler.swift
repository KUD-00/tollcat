import Foundation
import UserNotifications
import MeterCore

/// 本地定时提醒的 UN 适配。
///
/// 边界（不可协商，SPEC 12.5）：
/// 1. 只用 `UNUserNotificationCenter` + `UNCalendarNotificationTrigger`。
///    不接 APNs、不加 push entitlement、不做后台取数。
/// 2. 不做任何基于金额的告警。那需要 App 不运行时知道当前金额，
///    也就需要后台取数（AWS 每次要钱）或服务器推送（项目变性质）。
/// 3. 通知内容里不出现金额、百分比、provider 名单。触发时 App 没运行，
///    能拿到的只有旧数字；显示过期金额正是规格在防的事。
///    文案只说「去看看」，可以带事实性补充（「上次刷新 3 天前」）。
struct UserNotificationReminderScheduler: ReminderScheduling {
    static let identifierPrefix = "meter.reminder."

    func authorizationStatus() async -> ReminderAuthorization {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .provisional, .ephemeral:
            return .denied
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    func pendingRequestCount() async -> Int {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.filter { $0.identifier.hasPrefix(Self.identifierPrefix) }.count
    }

    func replacePending(
        specs: [ReminderTriggerSpec],
        content: ReminderNotificationContent
    ) async throws {
        await cancelAll()
        let center = UNUserNotificationCenter.current()
        for (index, spec) in specs.enumerated() {
            let payload = UNMutableNotificationContent()
            payload.title = content.title
            payload.body = content.body
            payload.sound = .default
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: spec.dateComponents,
                repeats: spec.repeats
            )
            let request = UNNotificationRequest(
                identifier: "\(Self.identifierPrefix)\(index)",
                content: payload,
                trigger: trigger
            )
            try await center.add(request)
        }
    }

    func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
