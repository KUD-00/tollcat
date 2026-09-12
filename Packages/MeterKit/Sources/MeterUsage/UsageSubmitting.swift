import Foundation

/// 匿名计数的唯一出口。界面不认这个协议，只认 `UsageAnalyticsRecording`。
public protocol UsageSubmitting: Sendable {
    func submit(_ payload: UsageAnalyticsPayload) async throws
}
