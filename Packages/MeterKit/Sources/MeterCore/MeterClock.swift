import Foundation

/// 折算和时间相关展示都走注入的时钟，别处不散落 `Date()`。
///
/// ## 为什么它在 MeterCore
///
/// 它以前住在 `MeterFeatures`，理由是「MeterCore 一处 `Date()` 都不许有」。
/// 那守住了字面上的禁令，代价是 **Modules / Persistence / Widget 拿不到时钟**——
/// 于是它们各自去捡 `Calendar.current` 和 `Date.formatted(.dateTime…)`，
/// 而那两样用的是系统时区，不是注入的这本日历。真正的漏在那儿，不在这儿。
///
/// 现在规矩说清楚：**墙钟进入这一层只有这一个入口**，有名字、有注入口、
/// 有 `design` 那份钉死的实现；别的文件照旧一处 `Date()` / `Calendar.current`
/// 都不许有。闸和 `ArchitectureGuardrailTests` 都按这一条扫。
public struct MeterClock: Sendable, Equatable {
    public var calendar: Calendar
    /// `nil` 表示每次读墙钟。钉死 `now` 会让刚刷新显示成「N 小时后」：
    /// 快照盖的是 `Date()`，对比的却是启动那一刻。
    private let frozenNow: Date?

    public var now: Date {
        frozenNow ?? Date()
    }

    public init(now: Date, calendar: Calendar) {
        self.frozenNow = now
        self.calendar = calendar
    }

    /// 设计稿固定时钟。合计、构成比例都按这一刻的 fixture 对账。
    public static var design: MeterClock {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 16
        components.hour = 12
        let now = calendar.date(from: components) ?? Date.distantPast
        return MeterClock(now: now, calendar: calendar)
    }

    /// 真机 / 模拟器入口用。每次读墙钟；折算仍从 `now` 参数走，不在 Core 里 `Date()`。
    ///
    /// 时区和 locale 取 **autoupdating** 那一份，不是 `.current`。`.current` 是取值
    /// 那一刻的快照，而这个时钟在 `DashboardModel` 里只取一次：Mac 菜单栏那份能连着
    /// 开几个星期，飞一趟之后「今天」「本月」还按出发地算，直到重启才回正。
    /// autoupdating 的那一份自己跟着系统走；界面什么时候重算由
    /// `ClockChangeObserver` 负责喊。
    public static var live: MeterClock {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        calendar.locale = .autoupdatingCurrent
        return MeterClock(frozenNow: nil, calendar: calendar)
    }

    private init(frozenNow: Date?, calendar: Calendar) {
        self.frozenNow = frozenNow
        self.calendar = calendar
    }

    /// 逐项比，不用 `Calendar` 自己的 `==`：它还会比 `firstWeekday`、`minimumDaysInFirstWeek`
    /// 这些这个 App 一处都没用到的东西。
    ///
    /// **locale 要比**：它决定月份名、相对时间怎么写，格式化缓存的钥匙里也有它。
    /// 漏掉它，系统语言切了之后两个时钟仍然相等，界面于是不会重画。
    public static func == (lhs: MeterClock, rhs: MeterClock) -> Bool {
        lhs.frozenNow == rhs.frozenNow
            && lhs.calendar.identifier == rhs.calendar.identifier
            && lhs.calendar.timeZone == rhs.calendar.timeZone
            && lhs.calendar.locale == rhs.calendar.locale
    }
}
