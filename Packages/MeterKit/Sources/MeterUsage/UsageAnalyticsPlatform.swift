import Foundation

/// 匿名页面计数的平台字段。和 `shared/api-contract.json` 的 `usage.platforms` 对齐。
public enum UsageAnalyticsPlatform: Sendable {
    public static var current: String {
        #if os(macOS)
        "macos"
        #else
        "ios"
        #endif
    }
}
