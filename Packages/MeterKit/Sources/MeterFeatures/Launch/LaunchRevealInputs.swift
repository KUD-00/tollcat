#if os(iOS)
import MeterDashboard

/// `RootView` 喂给冷启动过渡的那几样，变了才更新。
struct LaunchRevealInputs: Equatable {
    var showsDashboard: Bool
    var segments: [CompositionSegment]
}
#endif
