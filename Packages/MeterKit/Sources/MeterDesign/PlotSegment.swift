import Foundation

/// 折线上相邻两个已知点之间的一段。`isInferred` 为真时用虚线。
public struct PlotSegment: Identifiable, Sendable, Equatable {
    public var start: PlotPoint
    public var end: PlotPoint
    public var isInferred: Bool

    public var id: Date { start.date }

    public init(start: PlotPoint, end: PlotPoint, isInferred: Bool) {
        self.start = start
        self.end = end
        self.isInferred = isInferred
    }
}
