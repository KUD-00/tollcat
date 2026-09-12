import Foundation
#if canImport(ServiceManagement)
import ServiceManagement
#endif

/// 开机自启动。系统是唯一的真相源，不落盘：用户随时可能在「系统设置 › 登录项」里改。
@MainActor
protocol LoginItemControlling: AnyObject {
    var isEnabled: Bool { get }
    /// 系统拦下了，要用户去登录项里放行。
    var requiresApproval: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

@MainActor
enum LoginItem {
    static func live() -> any LoginItemControlling {
        #if os(macOS)
        LiveLoginItem()
        #else
        InMemoryLoginItem()
        #endif
    }
}

/// 测试和非 Mac 平台用。非 Mac 上界面不展示这一行，行为等于永远关。
@MainActor
final class InMemoryLoginItem: LoginItemControlling {
    var isEnabled = false
    var requiresApproval = false
    var failsNextChange = false

    init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if failsNextChange {
            failsNextChange = false
            throw CocoaError(.featureUnsupported)
        }
        isEnabled = enabled
    }
}

#if os(macOS)
@MainActor
final class LiveLoginItem: LoginItemControlling {
    var isEnabled: Bool { SMAppService.mainApp.status == .enabled }
    var requiresApproval: Bool { SMAppService.mainApp.status == .requiresApproval }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
#endif
