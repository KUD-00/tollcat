import Foundation

/// 连续几个整月的钱（从量与合计都算）。缺的月份仍占位，金额为 0——
/// 展示层决定画不画柱，这里不把 0 删掉，否则「哪几个月」会跟着数据跳。
public enum MonthSpendHistoryCalculator {
    public static let defaultMonthCount = 6

    public static func compute(
        snapshots: [Snapshot],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        filter: DashboardFilter = .unfiltered,
        monthCount: Int = defaultMonthCount,
        endedAccounts: [AccountID: Date] = [:]
    ) -> [MonthSpendPoint] {
        // 取景框选了多月区间时，柱子至少要盖住整个区间——不然图上看到的
        // 那几根加起来，和顶上那个合计对不上号。
        let window = filter.window(now: now, calendar: calendar)
        let count = max(monthCount, window.monthCount)
        let newest = window.newestBack
        let oldest = min(newest + count - 1, DashboardFilter.maxMonthsBack)

        var points: [MonthSpendPoint] = []
        var back = oldest
        while back >= newest {
            let monthFilter = DashboardFilter(
                monthsBack: back,
                includesSubscriptions: filter.includesSubscriptions,
                excludedAccounts: filter.excludedAccounts
            )
            let result = MonthToDateCalculator.compute(
                snapshots: snapshots,
                subscriptions: subscriptions,
                now: now,
                calendar: calendar,
                filter: monthFilter,
                endedAccounts: endedAccounts
            )
            let asOf = monthFilter.anchor(now: now, calendar: calendar)
            let monthStart = calendar.date(
                from: calendar.dateComponents([.year, .month], from: asOf)
            ) ?? asOf
            points.append(
                MonthSpendPoint(
                    monthStart: monthStart,
                    variableUSD: result.variableUSD,
                    totalUSD: result.totalUSD
                )
            )
            if back == 0 { break }
            back -= 1
        }
        return points
    }
}
