import SwiftUI

private struct CompositionRevealEpochKey: EnvironmentKey {
    static let defaultValue = 0
}

extension EnvironmentValues {
    /// 加一，圆环从空再转一次。Tab 切回来、开场滑回第一页时用。刷新不要加。
    public var compositionRevealEpoch: Int {
        get { self[CompositionRevealEpochKey.self] }
        set { self[CompositionRevealEpochKey.self] = newValue }
    }
}
