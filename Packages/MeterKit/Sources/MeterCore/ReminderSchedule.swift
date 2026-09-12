import Foundation

/// 定时提醒的日历输入。没有金额，也没有阈值。
public struct ReminderSchedule: Equatable, Sendable, Codable {
    public var frequency: ReminderFrequency
    public var hour: Int
    public var minute: Int
    /// `Calendar` 的 weekday：1 是星期日。
    public var weekday: Int
    /// 1...31。超出当月天数时由 `MonthDay` 钳到月末。
    public var dayOfMonth: Int

    public init(
        frequency: ReminderFrequency = .weekly,
        hour: Int = 21,
        minute: Int = 0,
        weekday: Int = 2,
        dayOfMonth: Int = 1
    ) {
        self.frequency = frequency
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
        self.weekday = min(max(weekday, 1), 7)
        self.dayOfMonth = min(max(dayOfMonth, 1), 31)
    }

    public static let `default` = ReminderSchedule()
}
