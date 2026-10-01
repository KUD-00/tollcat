import SwiftUI

/// 圆环进场的遮罩：从 12 点顺时针扫出 `progress` 那么大的扇形，1 就是整个方框。
struct DonutRevealSweep: Shape {
    var progress: Double

    func path(in rect: CGRect) -> Path {
        guard progress < 1 else { return Path(rect) }
        guard progress > 0 else { return Path() }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        // 半径取到方框对角：外沿放大的选中段和抗锯齿边都在遮罩里。
        let radius = hypot(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * progress),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
