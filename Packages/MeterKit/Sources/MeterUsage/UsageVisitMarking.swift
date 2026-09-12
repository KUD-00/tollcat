import Foundation

/// 「这个 UTC 日算不算第一次打开」。成功发出去之后才落盘，失败下次还能再报。
public protocol UsageVisitMarking: Sendable {
    func shouldCountVisit(on day: String) -> Bool
    func markVisitSent(on day: String)
}

/// 记在标准 UserDefaults，不进 Keychain、不进 App Group。这不是凭据。
public struct UserDefaultsVisitMarker: UsageVisitMarking, @unchecked Sendable {
    public static let storageKey = "usageAnalytics.lastVisitDay"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func shouldCountVisit(on day: String) -> Bool {
        defaults.string(forKey: Self.storageKey) != day
    }

    public func markVisitSent(on day: String) {
        defaults.set(day, forKey: Self.storageKey)
    }
}

public enum UsageUTCDay: Sendable {
    public static func string(from date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            parts.year ?? 0,
            parts.month ?? 0,
            parts.day ?? 0
        )
    }
}
