import Observation
import SwiftUI

/// 「检查更新…」的入口。
///
/// 更新器本体（Sparkle）只住在 Mac 壳里，不进 MeterKit：菜单和关于页只需要知道
/// 「现在能不能查、点了怎么办」两件事，不该认识它背后是谁。App Store 版和 iOS
/// 没有这个对象，入口就不出现，界面上不用再写一遍「这是直发版才有」的判断。
@MainActor
@Observable
public final class AppUpdateChecker {
    /// 正在下载或安装时为假，菜单项跟着灰掉。由壳按更新器的状态回填。
    public var canCheck: Bool

    private let check: @MainActor () -> Void

    public init(canCheck: Bool = true, check: @escaping @MainActor () -> Void) {
        self.canCheck = canCheck
        self.check = check
    }

    public func checkForUpdates() {
        check()
    }
}

extension EnvironmentValues {
    /// 只有 Mac 直发壳会挂。为空即「这个构建没有自动更新」。
    @Entry public var appUpdateChecker: AppUpdateChecker?
}
