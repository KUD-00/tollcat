import Foundation

/// 设置里的外观三档。跟随系统时展示层传 `nil`，不要写成固定的 light/dark。
public enum AppearancePreference: String, CaseIterable, Sendable, Codable, Equatable {
    case system
    case light
    case dark

    /// 新装默认暗色，不是跟随系统。
    public static let `default` = AppearancePreference.dark
}
