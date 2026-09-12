import Foundation

/// 详情页历史读数的范围。粒度跟着范围走：7 / 30 天按天，12 个月按月。
public enum ProviderHistoryRange: String, CaseIterable, Sendable, Codable, Equatable, Identifiable {
    case days7
    case days30
    case months12

    public var id: String { rawValue }

    public static let `default`: ProviderHistoryRange = .days30
}
