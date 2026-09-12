import Foundation

/// 测试和 Preview 用。记下收到的 payload，可以指定抛什么。
public final class StubFeedbackSubmitter: FeedbackSubmitting, @unchecked Sendable {
    private let lock = NSLock()
    private var _received: [FeedbackPayload] = []
    private var _error: FeedbackError?

    public init(error: FeedbackError? = nil) {
        self._error = error
    }

    public var received: [FeedbackPayload] {
        lock.withLock { _received }
    }

    public func setError(_ error: FeedbackError?) {
        lock.withLock { _error = error }
    }

    public func submit(_ payload: FeedbackPayload) async throws {
        let error = lock.withLock { () -> FeedbackError? in
            _received.append(payload)
            return _error
        }
        if let error { throw error }
    }
}
