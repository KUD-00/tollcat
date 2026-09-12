import Foundation

public final class InMemoryVisitMarker: UsageVisitMarking, @unchecked Sendable {
    private let lock = NSLock()
    private var lastDay: String?

    public init(lastDay: String? = nil) {
        self.lastDay = lastDay
    }

    public func shouldCountVisit(on day: String) -> Bool {
        lock.withLock { lastDay != day }
    }

    public func markVisitSent(on day: String) {
        lock.withLock { lastDay = day }
    }
}
