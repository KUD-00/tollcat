import Foundation

/// 测试用。记下收到的 payload，可以指定抛错。
public final class StubUsageSubmitter: UsageSubmitting, @unchecked Sendable {
    private let lock = NSLock()
    private var _received: [UsageAnalyticsPayload] = []
    private var _shouldFail = false

    public init() {}

    public var received: [UsageAnalyticsPayload] {
        lock.withLock { _received }
    }

    public func setShouldFail(_ value: Bool) {
        lock.withLock { _shouldFail = value }
    }

    public func submit(_ payload: UsageAnalyticsPayload) async throws {
        let fail = lock.withLock { () -> Bool in
            if _shouldFail { return true }
            _received.append(payload)
            return false
        }
        if fail { throw UsageSubmitError.transport }
    }
}

public enum UsageSubmitError: Error, Sendable {
    case transport
}
