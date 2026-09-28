import MeterDashboard
import MeterDesign

public extension TrendModuleContent {
    /// 图表要的点。`TrendBar` 住在不带 SwiftUI 的 MeterDashboard，换形状在这一层。
    var points: [PlotPoint] {
        bars.map { PlotPoint(date: $0.date, amount: $0.amount) }
    }
}
