import Foundation

/// 图表只吃日期和金额，不认 Snapshot。
public struct PlotPoint: Identifiable, Sendable, Equatable, Hashable {
    public var date: Date
    public var amount: Double

    public var id: Date { date }

    public init(date: Date, amount: Double) {
        self.date = date
        self.amount = amount
    }
}
