import Foundation

/// 「预计月底」的外推。**只有这一处实现。**
///
/// 从量按「本月至今 ÷ 已过天数 × 当月天数」推到月底；订阅不进来——它按扣款日
/// 全额计入，没有可推的东西（SPEC 第 12.5 节）。
///
/// 收在这里是因为现在有两条路要用它：直接扫快照的 `MonthToDateCalculator`，
/// 和读物化账本的 `LedgerProjection`。两处各写一遍的话，同一个月会因为"从哪条路
/// 读的"而给出两个不同的月底预计——那种不一致没人会想到去查。
public enum MonthProjection {
    /// 已过天数。1 号 00:00 记 0，避免除以零。
    public static func elapsedDays(now: Date, calendar: Calendar) -> Int {
        let day = calendar.component(.day, from: now)
        if day == 1, calendar.startOfDay(for: now) == now {
            return 0
        }
        return day
    }

    /// 把从量外推到月底。
    ///
    /// 回看已经结束的月份时，`now` 是那个月的最后一瞬，于是已过天数 = 当月天数、
    /// 系数为 1，结果自然等于总数——月份结束了，没有可推的东西。这条性质是
    /// `DashboardFilter.anchor` 特意做出来的，别在调用方再加 if。
    public static func extrapolate(_ variableTotal: Money, now: Date, calendar: Calendar) -> Money {
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 0
        let elapsed = elapsedDays(now: now, calendar: calendar)
        guard elapsed > 0, daysInMonth > 0 else { return .zero }
        return variableTotal * Decimal(daysInMonth) / Decimal(elapsed)
    }
}
