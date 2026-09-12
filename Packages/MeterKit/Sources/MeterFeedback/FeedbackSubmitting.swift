import Foundation

/// 反馈的唯一出口。界面只认这个协议，所以测试里不必碰网络。
public protocol FeedbackSubmitting: Sendable {
    func submit(_ payload: FeedbackPayload) async throws
}
