// GENERATED — scripts/render-app-icon.py（猫的几何来自 shared/cat.json）。改脚本再跑，不要手改。
import CoreGraphics
import MeterDashboard

/// 启动画面的几何（1024 见方的画面空间）。启动画面的方框：居中，边长 = min(屏宽, 屏高) × 0.5，最大 280，再往上提屏高的 0.04。故事板、两端覆盖层都按这条摆。
/// `LaunchScreen.storyboard` 是手写的，约束要和这里的三个数一致。
/// 圆牌顺序就是叠放顺序。图层图片在 `LaunchPocket.xcassets`，同一次生成。
enum LaunchPocketGeometry {
    static let canvas: Double = 1024
    static let artFraction: CGFloat = 0.5
    static let maxArt: CGFloat = 280
    static let lift: CGFloat = 0.04
    static let tokens: [LaunchPocketToken] = [
        LaunchPocketToken(kind: .database, x: 910.27, y: 326.77, radius: 83.09),
        LaunchPocketToken(kind: .cloud, x: 150.29, y: 388.81, radius: 126.29),
        LaunchPocketToken(kind: .ai, x: 885.89, y: 388.81, radius: 114.11),
    ]
}
