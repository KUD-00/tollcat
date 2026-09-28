import SwiftUI

/// 本月累计走势：实线到今天，虚线按当前速度推到月底。不标数。
struct GlanceSparkline: View {
    let trend: GlanceTrend
    var lineWidth: CGFloat = 2

    var body: some View {
        Canvas { context, size in
            let points = self.points(in: size)
            guard let last = points.last, points.count > 1 else { return }
            var solid = Path()
            solid.addLines(points)
            context.stroke(
                solid,
                with: .foreground,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )
            if let end = projectedPoint(in: size) {
                var dashed = Path()
                dashed.move(to: last)
                dashed.addLine(to: end)
                context.stroke(
                    dashed,
                    with: .foreground,
                    style: StrokeStyle(lineWidth: lineWidth * 0.75, lineCap: .round, dash: [1, lineWidth * 2])
                )
            }
            let dot = lineWidth * 1.6
            context.fill(
                Path(ellipseIn: CGRect(x: last.x - dot, y: last.y - dot, width: dot * 2, height: dot * 2)),
                with: .foreground
            )
        }
        .accessibilityHidden(true)
    }

    private func x(_ index: Int, width: CGFloat) -> CGFloat {
        let span = CGFloat(max(trend.dayCount - 1, 1))
        return inset + CGFloat(index) / span * (width - inset * 2)
    }

    private func y(_ value: Double, height: CGFloat) -> CGFloat {
        let clamped = min(max(value, 0), 1)
        return height - inset - CGFloat(clamped) * (height - inset * 2)
    }

    private var inset: CGFloat { lineWidth * 1.6 }

    private func points(in size: CGSize) -> [CGPoint] {
        trend.cumulative.enumerated().map { index, value in
            CGPoint(x: x(index, width: size.width), y: y(value, height: size.height))
        }
    }

    private func projectedPoint(in size: CGSize) -> CGPoint? {
        guard let end = trend.projectedEnd, trend.cumulative.count < trend.dayCount else { return nil }
        return CGPoint(x: x(trend.dayCount - 1, width: size.width), y: y(end, height: size.height))
    }
}
