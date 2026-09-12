import Foundation
import MeterModules

/// `tollcat://settings/…`：从通知、别的页面跳进设置某一项。
///
/// scheme 和仪表深链共用，host 分开。认不出来的路径只打开设置列表。
enum SettingsDeepLink {
    static let host = "settings"

    static func matches(_ url: URL) -> Bool {
        url.scheme == DashboardDeepLink.scheme && url.host() == host
    }

    static func navigation(from url: URL) -> SettingsNavigation? {
        guard matches(url) else { return nil }
        return SettingsNavigation(path: url.pathComponents.first { $0 != "/" })
    }

    static var settingsURL: URL {
        URL(string: "\(DashboardDeepLink.scheme)://\(host)")!
    }

    static func url(path: String? = nil) -> URL {
        guard let path, !path.isEmpty else { return settingsURL }
        return URL(string: "\(DashboardDeepLink.scheme)://\(host)/\(path)")!
    }
}
