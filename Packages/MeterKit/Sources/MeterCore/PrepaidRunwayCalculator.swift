import Foundation

/// 近 7 日平均日消耗，以及按当前余额还能撑多少天。
///
/// 至少要有一条「7 天前或更早」的余额快照，才谈得上近 7 日均速。
/// 没有、或者这段时间余额没降（充值 / 没用），返回空，UI 整块不显示。
public enum PrepaidRunwayCalculator {
    public static func compute(
        snapshots: [Snapshot],
        now: Date,
        calendar: Calendar
    ) -> [PrepaidRunway] {
        let (groups, _) = SnapshotGrouping.byAccount(
            snapshots.filter { $0.kind == .prepaid && $0.balanceUSD != nil }
        )
        return groups.compactMap { group in
            runway(
                accountID: group.id,
                providerID: group.providerID,
                snapshots: group.ordered,
                now: now,
                calendar: calendar
            )
        }
    }

    /// 读物化账本那条路。**余额那条曲线在账本里已经是每天一格**，
    /// 于是"7 天前那次的余额"是查表，不是把该账号全部快照再扫一遍。
    ///
    /// 判据和上面那条一字不差：要有一条「7 天前或更早」的观测、这段时间余额真的降过、
    /// 间隔至少 7 天。少一条都算不出诚实的均速。
    public static func compute(
        latest: [AccountLatest],
        rollups: [MonthlyRollup],
        now: Date,
        calendar: Calendar
    ) -> [PrepaidRunway] {
        var balancesByAccount: [AccountID: [Date: Money]] = [:]
        for rollup in rollups where !rollup.dailyBalanceUSD.isEmpty {
            balancesByAccount[rollup.accountID, default: [:]]
                .merge(rollup.dailyBalanceUSD) { _, new in new }
        }
        guard
            let windowStart = calendar.date(
                byAdding: .day,
                value: -7,
                to: calendar.startOfDay(for: now)
            )
        else {
            return []
        }
        let today = calendar.startOfDay(for: now)

        return latest.compactMap { account -> PrepaidRunway? in
            guard
                let balance = account.balanceUSD,
                balance > .zero,
                let byDay = balancesByAccount[account.accountID],
                let baselineDay = byDay.keys.filter({ $0 <= windowStart }).max(),
                let startBalance = byDay[baselineDay]
            else {
                return nil
            }
            let consumed = startBalance - balance
            guard consumed > .zero else { return nil }
            let elapsed = calendar.dateComponents([.day], from: baselineDay, to: today).day ?? 0
            guard elapsed >= 7 else { return nil }
            let daily = consumed / Decimal(elapsed)
            guard daily > .zero else { return nil }
            let remaining = NSDecimalNumber(decimal: balance.usd / daily.usd).doubleValue
            let daysRemaining = Int(remaining.rounded())
            guard daysRemaining >= 0 else { return nil }
            return PrepaidRunway(
                accountID: account.accountID,
                providerID: account.providerID,
                balanceUSD: balance,
                averageDailyUSD: daily.roundedToCents(),
                daysRemaining: daysRemaining
            )
        }
    }

    private static func runway(
        accountID: AccountID,
        providerID: ProviderID,
        snapshots: [Snapshot],
        now: Date,
        calendar: Calendar
    ) -> PrepaidRunway? {
        guard
            let current = snapshots.last,
            let balance = current.balanceUSD,
            balance > .zero
        else {
            return nil
        }

        guard
            let windowStart = calendar.date(
                byAdding: .day,
                value: -7,
                to: calendar.startOfDay(for: now)
            )
        else {
            return nil
        }

        // 取「7 天前或更早」里最近的一条，才是近 7 日而不是接入以来的均速。
        guard
            let baseline = snapshots.last(where: { calendar.startOfDay(for: $0.fetchedAt) <= windowStart }),
            let startBalance = baseline.balanceUSD
        else {
            return nil
        }

        let consumed = startBalance - balance
        guard consumed > .zero else { return nil }

        let elapsed = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: baseline.fetchedAt),
            to: calendar.startOfDay(for: now)
        ).day ?? 0
        guard elapsed >= 7 else { return nil }

        let daily = consumed / Decimal(elapsed)
        guard daily > .zero else { return nil }

        let remaining = NSDecimalNumber(decimal: balance.usd / daily.usd).doubleValue
        let daysRemaining = Int(remaining.rounded())
        guard daysRemaining >= 0 else { return nil }

        return PrepaidRunway(
            accountID: accountID,
            providerID: providerID,
            balanceUSD: balance,
            averageDailyUSD: daily.roundedToCents(),
            daysRemaining: daysRemaining
        )
    }
}
