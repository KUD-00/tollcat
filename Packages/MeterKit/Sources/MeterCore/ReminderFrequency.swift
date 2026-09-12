import Foundation

/// 用户自己打开的定时提醒频率。就这四档，不做自定义天数。
public enum ReminderFrequency: String, CaseIterable, Sendable, Codable, Equatable {
    case daily
    case weekly
    case biweekly
    case monthly
}
