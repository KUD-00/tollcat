import Foundation

/// 通知文案。
///
/// 边界（不可协商，SPEC 12.5）：
/// 1. 只用本地通知，不接 APNs、不做后台取数。
/// 2. 不做任何基于金额的告警。
/// 3. 通知内容里不出现金额、百分比、provider 名单。
///    触发时 App 没运行，能拿到的只有旧数字；文案只说「去看看」，
///    可以带事实性补充（「上次刷新 3 天前」）。
enum ReminderNotificationCopy {
    static var title: String { String(localized: L("该看一眼了")) }
    static var lookBody: String { String(localized: L("打开 App，看看这个月花了多少。")) }

    static func content(
        lastRefreshAt: Date?,
        now: Date,
        calendar: Calendar
    ) -> ReminderNotificationContent {
        ReminderNotificationContent(
            title: title,
            body: body(lastRefreshAt: lastRefreshAt, now: now, calendar: calendar)
        )
    }

    static func body(
        lastRefreshAt: Date?,
        now: Date,
        calendar: Calendar
    ) -> String {
        guard let lastRefreshAt else { return lookBody }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastRefreshAt),
            to: calendar.startOfDay(for: now)
        ).day ?? 0
        if days <= 0 {
            return lookBody + String(localized: L("上次刷新就在今天。"))
        }
        if days == 1 {
            return lookBody + String(localized: L("上次刷新 1 天前。"))
        }
        return lookBody + String(localized: L("上次刷新 \(days) 天前。"))
    }
}
