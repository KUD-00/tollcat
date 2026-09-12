import Foundation

/// 柱 / 折线的横轴粒度。日和月不能混用同一套刻度。
public enum ChartTimeUnit: Sendable, Equatable {
    case day
    case month
}
