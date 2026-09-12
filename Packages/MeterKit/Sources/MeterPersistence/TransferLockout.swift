import Foundation

/// 只挡这台设备上的乱试。挡不住已经拿到文件的人离线穷举。
public struct TransferLockout: Equatable, Sendable {
    public static let freeAttemptLimit = 5

    public private(set) var failureCount: Int
    public private(set) var lockedUntil: Date?

    public init(failureCount: Int = 0, lockedUntil: Date? = nil) {
        self.failureCount = failureCount
        self.lockedUntil = lockedUntil
    }

    public var remainingFreeAttempts: Int {
        max(0, Self.freeAttemptLimit - failureCount)
    }

    public mutating func registerFailure(now: Date) {
        failureCount += 1
        let delay = Self.delay(afterFailureCount: failureCount)
        if delay > 0 {
            lockedUntil = now.addingTimeInterval(delay)
        }
    }

    public mutating func registerSuccess() {
        failureCount = 0
        lockedUntil = nil
    }

    public func isLocked(now: Date) -> Bool {
        guard let lockedUntil else { return false }
        return now < lockedUntil
    }

    public func remainingSeconds(now: Date) -> Int {
        guard let lockedUntil else { return 0 }
        return max(0, Int(ceil(lockedUntil.timeIntervalSince(now))))
    }

    /// 第 5 次起才锁，之后时间递增。这不是密码学保护。
    public static func delay(afterFailureCount count: Int) -> TimeInterval {
        switch count {
        case ...4:
            return 0
        case 5:
            return 15
        case 6:
            return 30
        case 7:
            return 60
        case 8:
            return 120
        case 9:
            return 300
        default:
            return 900
        }
    }
}
