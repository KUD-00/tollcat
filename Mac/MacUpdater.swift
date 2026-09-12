import Foundation
import MeterFeatures
#if canImport(Sparkle)
import Sparkle
#endif

/// Sparkle 只在这一个文件里出现。
///
/// 壳把它包成 `AppUpdateChecker` 交给菜单和关于页，MeterKit 不链 Sparkle、
/// 也不知道自己在直发版里。以后若出 Mac App Store 版，那个 target 不链这个包，
/// `canImport(Sparkle)` 为假，这里退成「没有更新器」，上层入口自动消失。
///
/// 更新清单 / 公钥 / 沙盒安装服务开关都在 `Mac/Supporting-Info.plist`
/// （`SUFeedURL` / `SUPublicEDKey` / `SUEnableInstallerLauncherService`），
/// 安装服务的 mach-lookup 例外在 `project.yml` 的 Mac entitlements 里。
@MainActor
final class MacUpdater {
    /// 为空即这个构建没有自动更新（没链 Sparkle，或验收模式关掉了联网）。
    let checker: AppUpdateChecker?

    #if canImport(Sparkle)
    private let controller: SPUStandardUpdaterController?
    private var canCheckObservation: NSKeyValueObservation?
    #endif

    /// 截图 / UI 验收用 `-stub-catalog` 关掉了所有联网，这里跟着不起更新器：
    /// 否则第二次启动 Sparkle 会弹「要不要自动检查」，把截图挡住。
    init(startsUpdater: Bool = !FeatureLaunchArguments.stubCatalog) {
        #if canImport(Sparkle)
        guard startsUpdater else {
            controller = nil
            checker = nil
            return
        }
        // 用户界面用 Sparkle 自带的标准弹窗（三语都在框架里），不自己画。
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        self.controller = controller
        let checker = AppUpdateChecker(canCheck: controller.updater.canCheckForUpdates) {
            controller.checkForUpdates(nil)
        }
        self.checker = checker
        // 下载 / 安装进行中 Sparkle 会把 canCheckForUpdates 拉低；菜单项跟着灰。
        canCheckObservation = controller.updater.observe(\.canCheckForUpdates, options: [.new]) { _, change in
            guard let value = change.newValue else { return }
            Task { @MainActor in checker.canCheck = value }
        }
        #else
        checker = nil
        #endif
    }
}
