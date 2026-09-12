import Foundation
import MeterDesign

public struct TrendModuleContent: Equatable, Sendable {
    public var points: [PlotPoint]
    public var xStart: Date
    public var xEnd: Date
    public var highlight: Date
    public var spokenLabel: String
    /// 不含本月的近几个月月均，宽壳卡上的大数字。只有本月一根柱时没有。
    public var averageText: String? = nil

    public init(
        points: [PlotPoint],
        xStart: Date,
        xEnd: Date,
        highlight: Date,
        spokenLabel: String,
        averageText: String? = nil
    ) {
        self.points = points
        self.xStart = xStart
        self.xEnd = xEnd
        self.highlight = highlight
        self.spokenLabel = spokenLabel
        self.averageText = averageText
    }
}
