import CoreGraphics

/// 一只仪表猫相对构成卡的落点。坐标是舞台左上角为原点，猫视图的左上角。
struct DashboardCatPlacement: Equatable, Sendable {
    var x: CGFloat
    var y: CGFloat
    var rotationDegrees: Double
    var isFlipped: Bool
}
