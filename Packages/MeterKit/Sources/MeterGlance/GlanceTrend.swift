import Foundation

/// 本月累计走势。**只表示方向，不标数**：值已经归一到 0...1。
public struct GlanceTrend: Codable, Equatable, Sendable {
    /// 1 号到今天，每天一个累计值。最后一个点就是大数字那个位置。
    public var cumulative: [Double]
    /// 按当前速度推到月底的位置。外推不成立时为 nil，走势线后面就不画虚线。
    public var projectedEnd: Double?
    /// 这个月有几天。横轴按整月排，月中那条线只走到一半。
    public var dayCount: Int

    public init(cumulative: [Double], projectedEnd: Double?, dayCount: Int) {
        self.cumulative = cumulative
        self.projectedEnd = projectedEnd
        self.dayCount = dayCount
    }
}
