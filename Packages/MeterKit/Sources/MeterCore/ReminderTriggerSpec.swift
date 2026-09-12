import Foundation

/// 下一次（或若干次）应触发的日期分量。Features 再拿去建本地日历 trigger。
public struct ReminderTriggerSpec: Equatable, Sendable {
    public var dateComponents: DateComponents
    public var repeats: Bool

    public init(dateComponents: DateComponents, repeats: Bool) {
        self.dateComponents = dateComponents
        self.repeats = repeats
    }
}
