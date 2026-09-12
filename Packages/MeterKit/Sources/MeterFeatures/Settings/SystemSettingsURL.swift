import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// 打开系统设置里和通知有关的那一页。URL 常量本身还是系统 API 给的。
enum SystemSettingsURL {
    static var notifications: URL? {
        #if os(macOS)
        URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings")
        #else
        URL(string: UIApplication.openNotificationSettingsURLString)
        #endif
    }
}
