import Foundation
import MeterCore

enum ReminderSettingsCopy {
    static var sectionHeader: String { String(localized: L("提醒")) }
    static var toggleTitle: String { String(localized: L("提醒")) }
    static var frequencyLabel: String { String(localized: L("频率")) }
    static var timeLabel: String { String(localized: L("时刻")) }
    static var weekdayLabel: String { String(localized: L("星期")) }
    static var dayOfMonthLabel: String { String(localized: L("每月几号")) }
    static var toggleNote: LocalizedStringResource {
        L("让猫猫到点提醒你回来刷新")
    }
    static var deniedExplanation: String { String(localized: L("通知权限被关掉了，提醒不会响。")) }
    static var openSettings: String { String(localized: L("去系统设置开启")) }

    static func frequencyTitle(_ frequency: ReminderFrequency) -> String {
        switch frequency {
        case .daily: String(localized: L("每天"))
        case .weekly: String(localized: L("每周"))
        case .biweekly: String(localized: L("每两周"))
        case .monthly: String(localized: L("每月"))
        }
    }

    static func weekdayTitle(_ weekday: Int, calendar: Calendar = .current) -> String {
        let symbols = calendar.standaloneWeekdaySymbols
        let index = weekday - 1
        guard symbols.indices.contains(index) else {
            return String(localized: L("星期")) + " \(weekday)"
        }
        return symbols[index]
    }

    static func dayOfMonthTitle(_ day: Int) -> String {
        String(localized: L("\(day) 日"))
    }

    static func weekdays(firstWeekday: Int) -> [Int] {
        (0..<7).map { ((firstWeekday - 1 + $0) % 7) + 1 }
    }
}
