import Foundation

/// 上月同期：上个月 1 号到「和本月已过天数相同的那一天」**整天结束**。
///
/// 上月天数不够时钳到上月最后一天（3 月 31 日 → 2 月 28/29 日）。
/// 用「本月 1 号减一个月」再钳日，不依赖 `now - 1 month` 对 31 号的溢出行为。
///
/// ## 为什么上月侧截到日，本月侧却是「到此刻」
///
/// 这个不对称是**有意的**，不是漏了。
///
/// 账本行折下来之后会一直用到下一次失效，而失效的粒度是「天」
/// （`LedgerFingerprint.day`）。窗口终点若精确到时分秒，早上 9 点折的那一行
/// 记的是「上月 1 日到 16 日 09:00」，下午 6 点读它时指纹说还作数——同一天里
/// 账本和直接重算于是给出两个不同的同期，而屏幕上看不出来。
///
/// 上月那一侧本来也没有「几点」可言：SPEC 的口径就是按日截断。本月这一侧
/// 才是真的「到此刻」——它是正在走的这个月，日粒度的钱还在往上加。
/// 于是终点取**同日的下一天零点**：同一天的观测和日桶全部算进来，
/// 而且一整天里这个值不变。
public struct ComparisonWindow: Hashable, Sendable {
    public var start: Date
    /// **不含**。上月同日的下一天零点——同一天整天都在窗口里。
    public var end: Date
    public var dayOfMonth: Int

    public init(start: Date, end: Date, dayOfMonth: Int) {
        self.start = start
        self.end = end
        self.dayOfMonth = dayOfMonth
    }

    public func month(calendar: Calendar) -> Int {
        calendar.component(.month, from: start)
    }

    public static func samePeriodLastMonth(now: Date, calendar: Calendar) -> ComparisonWindow? {
        guard
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
            let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart),
            let daysInLast = calendar.range(of: .day, in: .month, for: lastMonthStart)?.count,
            daysInLast > 0
        else {
            return nil
        }

        let day = min(calendar.component(.day, from: now), daysInLast)
        var endParts = calendar.dateComponents([.year, .month], from: lastMonthStart)
        endParts.day = day
        // 不再拷 `now` 的时分秒纳秒：见上面那段为什么按日截断。
        guard
            let sameDay = calendar.date(from: endParts),
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: sameDay))
        else {
            return nil
        }

        return ComparisonWindow(start: lastMonthStart, end: end, dayOfMonth: day)
    }
}
