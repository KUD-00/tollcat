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
        LaunchPocketToken(kind: .database, x: 901.21, y: 368.26, radius: 58.17),
        LaunchPocketToken(kind: .cloud, x: 192.43, y: 158.32, radius: 93.41),
        LaunchPocketToken(kind: .ai, x: 820.32, y: 148.69, radius: 86.67),
    ]
}
