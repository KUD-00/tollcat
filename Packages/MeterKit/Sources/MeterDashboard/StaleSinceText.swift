import Foundation
import MeterFormat

/// 「之最」里「最久没刷新」那一格的时间。
///
/// Apple 平台跟着系统语言、没有桥钉语言时，交给 `RelativeDateTimeFormatter`
/// （能说到「2 小时前」）。Android 的 Foundation 没有它，桥又钉了语言，
/// 就退到按天说——「最久没刷新」本来也是按天才有意义的事。
enum StaleSinceText {
    static func make(since: Date, now: Date) -> String {
        #if canImport(Darwin)
        if PortableLocale.languageTag == nil {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return formatter.localizedString(for: since, relativeTo: now)
        }
        #endif
        let days = max(0, Int(now.timeIntervalSince(since) / 86_400))
        switch days {
        case 0: return L("今天")
        case 1: return L("1 天前")
        default: return L("\(days) 天前")
        }
    }
}
