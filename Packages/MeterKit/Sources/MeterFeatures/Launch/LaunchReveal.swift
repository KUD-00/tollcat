#if os(iOS)
import Foundation
import MeterCore
import MeterDashboard
import MeterDesign
import Observation
import SwiftUI
import UIKit

/// 冷启动过渡的状态：落点和仪表盘在不在台前。`RootView` 随数据更新它，
/// 覆盖层的动画任务每一步都读它——任务起跑时数据往往还没到。
@MainActor
@Observable
final class LaunchReveal {
    let registry = LaunchSwatchRegistry()
    /// 每枚圆牌落到图例哪一段。
    private(set) var targets: [LaunchTokenKind: String] = [:]
    /// 仪表盘在台前而且有数。不是（开场引导、别的 tab、还没接服务）就只淡出。
    private(set) var showsDashboard = false

    /// 系统的深浅色。故事板跟系统走，App 里「外观」可能强制成另一种；覆盖层第一帧要和故事板一样，
    /// 所以按系统画，演完淡掉后才轮到 App 自己的外观。
    let systemColorScheme: ColorScheme

    init(systemColorScheme: ColorScheme = LaunchReveal.currentSystemColorScheme()) {
        self.systemColorScheme = systemColorScheme
    }

    static func currentSystemColorScheme() -> ColorScheme {
        let screen = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen }
            .first
        let style = screen?.traitCollection.userInterfaceStyle ?? UITraitCollection.current.userInterfaceStyle
        return style == .dark ? .dark : .light
    }

    /// 一个进程只演一次：iPad 再开一个窗口没有系统启动画面垫着，不该冒出这层。
    private static var hasPlayed = false

    static func makeForFirstScene() -> LaunchReveal? {
        guard !hasPlayed else { return nil }
        hasPlayed = true
        if FeatureLaunchArguments.skipLaunchReveal {
            return nil
        }
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return nil
        }
        return LaunchReveal()
    }

    func update(showsDashboard: Bool, segments: [CompositionSegment], presentation: MoneyPresentation) {
        self.showsDashboard = showsDashboard
        let slices = CompositionSliceBuilder.make(from: segments, presentation: presentation)
        let next = LaunchTokenTargets.make(from: slices)
        if next != targets {
            targets = next
        }
    }
}
#endif
