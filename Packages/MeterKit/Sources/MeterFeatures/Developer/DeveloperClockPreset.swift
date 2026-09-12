#if DEBUG
import Foundation
import MeterCore

enum DeveloperClockPreset: String, CaseIterable, Identifiable, Sendable {
    case design
    case monthStart
    case monthEnd
    case feb29
    case newYear

    var id: String { rawValue }

    var title: String {
        switch self {
        case .design: String(localized: L("设计稿 8 月 16 日"))
        case .monthStart: String(localized: L("月初 1 号 00:00"))
        case .monthEnd: String(localized: L("月末最后一刻"))
        case .feb29: String(localized: L("2 月 29 日"))
        case .newYear: String(localized: L("跨年（1 月 1 日 00:00）"))
        }
    }

    func date(calendar: Calendar, now: Date) -> Date {
        switch self {
        case .design:
            return MeterClock.design.now
        case .monthStart:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        case .monthEnd:
            guard
                let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
                let next = calendar.date(byAdding: .month, value: 1, to: start),
                let last = calendar.date(byAdding: .second, value: -1, to: next)
            else { return now }
            return last
        case .feb29:
            let year = calendar.component(.year, from: now)
            for offset in 0..<8 {
                var components = DateComponents()
                components.year = year + offset
                components.month = 2
                components.day = 29
                components.hour = 12
                if let date = calendar.date(from: components),
                   calendar.range(of: .day, in: .month, for: date)?.count == 29 {
                    return date
                }
            }
            return calendar.date(from: DateComponents(year: 2028, month: 2, day: 29, hour: 12)) ?? now
        case .newYear:
            let year = calendar.component(.year, from: now)
            return calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1, hour: 0)) ?? now
        }
    }
}
#endif
