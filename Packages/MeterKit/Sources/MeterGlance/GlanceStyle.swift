import SwiftUI

/// 手表上的颜色。手表壳链不了 MeterDesign（它的动态色走 UIKit 的 trait，
/// watchOS 没有），所以用到的那几种系统色在这里另列一份——
/// `GlanceStyleTests` 逐个核对它们和 `MeterColor` 是同一种颜色。
public enum GlanceStyle {
    /// App 壳的强调色（`TollCatApp` 上的 `.tint(.indigo)`）。
    public static let accent = Color.indigo

    static let good = Color.green
    static let warn = Color.orange
    static let crit = Color.red

    /// 和 App 构成图同一套：前 5 名各一色，「其他」是灰。
    static let rankColors: [Color] = [.indigo, .teal, .orange, .pink, .purple]
    static let remainderColor = Color.gray

    public static func color(for level: GlanceBudgetLevel) -> Color {
        switch level {
        case .normal: good
        case .close: warn
        case .over: crit
        }
    }

    public static func color(for service: GlanceService) -> Color {
        guard !service.isRemainder, rankColors.indices.contains(service.rank) else {
            return remainderColor
        }
        return rankColors[service.rank]
    }
}
