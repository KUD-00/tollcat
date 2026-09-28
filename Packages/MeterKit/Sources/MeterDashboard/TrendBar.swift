import Foundation

/// 近几个月里的一根柱。
///
/// 带着已经格式化好的 `amountText`：Android / Windows 画柱时要在旁边写数，
/// 而货币怎么写只该有一处（`MoneyPresentation`）。图表那边要的 `PlotPoint`
/// 在 MeterModules 里从这里换出来——MeterDesign 带 SwiftUI，这一层不能链它。
public struct TrendBar: Identifiable, Equatable, Sendable {
    public var date: Date
    public var amount: Double
    public var amountText: String

    public var id: Date { date }

    public init(date: Date, amount: Double, amountText: String) {
        self.date = date
        self.amount = amount
        self.amountText = amountText
    }
}
