import MeterDashboard

/// 启动画面里的一枚服务圆牌：位置在 1024 见方的画面空间里。
struct LaunchPocketToken: Identifiable, Sendable {
    let kind: LaunchTokenKind
    let x: Double
    let y: Double
    let radius: Double

    var id: LaunchTokenKind { kind }
}
