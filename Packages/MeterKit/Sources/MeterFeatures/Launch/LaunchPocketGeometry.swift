// GENERATED — scripts/render-app-icon.py（猫的几何来自 shared/cat.json）。改脚本再跑，不要手改。
import MeterDashboard

/// 启动画面里三枚服务圆牌在画面里的位置（1024 见方，画面贴底、和屏幕一样宽）。
/// 顺序就是叠放顺序。图层图片在 `LaunchPocket.xcassets`，同一次生成。
enum LaunchPocketGeometry {
    static let canvas: Double = 1024
    static let tokens: [LaunchPocketToken] = [
        LaunchPocketToken(kind: .database, x: 926.0, y: 475.8, radius: 75.9),
        LaunchPocketToken(kind: .cloud, x: 125.6, y: 531.0, radius: 115.0),
        LaunchPocketToken(kind: .ai, x: 893.8, y: 531.0, radius: 103.5),
    ]
}
