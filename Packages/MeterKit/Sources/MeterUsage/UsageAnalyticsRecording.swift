import Foundation

/// 界面只认这个协议。Preview 和测试用空实现，不必碰网络。
public protocol UsageAnalyticsRecording: Sendable {
    func record(_ screen: UsageAnalyticsScreen)
    func flush()
}

public struct NoOpUsageAnalytics: UsageAnalyticsRecording {
    public init() {}

    public func record(_ screen: UsageAnalyticsScreen) {}

    public func flush() {}
}
