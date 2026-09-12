#if DEBUG
import Foundation
import Observation
import MeterCore

/// 开发工具的会话状态。只活在进程里，退出 App 就丢。
@MainActor
@Observable
final class DeveloperSession {
    static let shared = DeveloperSession()

    var clockOverride: Date?

    private init() {}

    func apply(now: Date, to dashboard: DashboardModel) {
        clockOverride = now
        dashboard.setClock(Self.clock(now: now, calendar: dashboard.clock.calendar))
    }

    func apply(_ preset: DeveloperClockPreset, to dashboard: DashboardModel) {
        apply(now: preset.date(calendar: dashboard.clock.calendar, now: dashboard.clock.now), to: dashboard)
    }

    func clearClock(on dashboard: DashboardModel) {
        clockOverride = nil
        dashboard.setClock(.live)
    }

    func resetForTests() {
        clockOverride = nil
    }

    private static func clock(now: Date, calendar: Calendar) -> MeterClock {
        var next = calendar
        next.locale = .current
        return MeterClock(now: now, calendar: next)
    }
}
#endif
