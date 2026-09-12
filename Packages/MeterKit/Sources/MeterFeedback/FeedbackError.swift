import Foundation

public enum FeedbackError: Error, Hashable, Sendable {
    case emptyMessage
    case invalidResponse
    case rateLimited
    case httpStatus(Int)
    case transport

    /// 限流不是错，是「你刚才提过了」。界面上要说人话，不能报 429。
    public var isRateLimited: Bool {
        self == .rateLimited
    }
}
