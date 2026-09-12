import Foundation

/// 未来 N 天内要扣的订阅。
///
/// 手动月付不记扣款日，不算即将。年付看首次扣款日。
/// snapshot 没带扣款日的也不算——不知道哪天扣就无法判断「即将」。
public enum UpcomingChargeCalculator {
    public static func charges(
        snapshots: [Snapshot],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        withinDays: Int = 7
    ) -> [UpcomingCharge] {
        // 退掉的手动订阅不再压住 API 报回来的月费——那家可能还在跑。
        let manualOwners = subscriptions.accountsSupersedingAPISubscriptions(
            on: now,
            calendar: calendar
        )
        var result: [UpcomingCharge] = []

        // GitHub 这类月费加超额，档位也在 snapshot 的 committed 里，不能只认纯订阅。
        let (groups, _) = SnapshotGrouping.byAccount(
            snapshots.filter { $0.kind == .subscription || $0.kind == .planAndUsage }
        )
        for group in groups {
            let id = group.id
            guard let snapshot = group.ordered.last else { continue }
            if manualOwners.contains(id) { continue }
            guard
                let amount = snapshot.committedMonthlyUSD,
                amount > .zero,
                let day = snapshot.chargeDayOfMonth,
                let date = nextMonthlyChargeDate(dayOfMonth: day, now: now, calendar: calendar),
                isWithin(date, now: now, calendar: calendar, days: withinDays)
            else {
                continue
            }
            result.append(
                UpcomingCharge(
                    name: "",
                    accountID: id,
                    providerID: snapshot.providerID,
                    amount: amount,
                    chargeDate: date
                )
            )
        }

        result.append(
            contentsOf: annualCharges(
                subscriptions,
                now: now,
                calendar: calendar,
                withinDays: withinDays
            )
        )
        return result.sorted { $0.chargeDate < $1.chargeDate }
    }

    /// 读物化账本那条路。**「哪条读数算数」在折叠时已经判过了**，
    /// 这里拿到的就是每账号一行，不再回头去分组。
    public static func charges(
        latest: [AccountLatest],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        withinDays: Int = 7
    ) -> [UpcomingCharge] {
        let manualOwners = subscriptions.accountsSupersedingAPISubscriptions(
            on: now,
            calendar: calendar
        )
        var result: [UpcomingCharge] = []
        for account in latest where !manualOwners.contains(account.accountID) {
            guard
                let amount = account.committedMonthlyUSD,
                amount > .zero,
                let day = account.chargeDayOfMonth,
                let date = nextMonthlyChargeDate(dayOfMonth: day, now: now, calendar: calendar),
                isWithin(date, now: now, calendar: calendar, days: withinDays)
            else {
                continue
            }
            result.append(
                UpcomingCharge(
                    name: "",
                    accountID: account.accountID,
                    providerID: account.providerID,
                    amount: amount,
                    chargeDate: date
                )
            )
        }
        result.append(
            contentsOf: annualCharges(
                subscriptions,
                now: now,
                calendar: calendar,
                withinDays: withinDays
            )
        )
        return result.sorted { $0.chargeDate < $1.chargeDate }
    }

    /// 年付的手动订阅。两条路共用——它只看订阅规则，和读数无关。
    private static func annualCharges(
        _ subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        withinDays: Int
    ) -> [UpcomingCharge] {
        var result: [UpcomingCharge] = []
        for subscription in subscriptions {
            guard
                subscription.period == .annual,
                // 退掉的不再预告下一次扣款——那笔钱不会再扣了。
                !subscription.hasEnded(by: now, calendar: calendar),
                subscription.amount > .zero,
                let date = nextChargeDate(subscription, now: now, calendar: calendar),
                isWithin(date, now: now, calendar: calendar, days: withinDays)
            else {
                continue
            }
            result.append(
                UpcomingCharge(
                    name: subscription.name,
                    accountID: subscription.accountID,
                    providerID: subscription.providerID,
                    amount: subscription.amount,
                    chargeDate: date
                )
            )
        }

        return result.sorted { $0.chargeDate < $1.chargeDate }
    }

    // MARK: - Next charge

    public static func nextChargeDate(
        _ subscription: MonthlySubscription,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        switch subscription.period {
        case .monthly:
            return nextMonthlyChargeDate(
                dayOfMonth: calendar.component(.day, from: subscription.anchorDate),
                now: now,
                calendar: calendar,
                firstEligibleMonth: calendar.date(
                    from: calendar.dateComponents([.year, .month], from: subscription.anchorDate)
                )
            )
        case .annual:
            return nextAnnualChargeDate(
                anchorDate: subscription.anchorDate,
                now: now,
                calendar: calendar
            )
        }
    }

    public static func nextMonthlyChargeDate(
        dayOfMonth: Int,
        now: Date,
        calendar: Calendar,
        firstEligibleMonth: Date? = nil
    ) -> Date? {
        guard (1...31).contains(dayOfMonth) else { return nil }
        let today = calendar.startOfDay(for: now)
        guard
            let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        else {
            return nil
        }

        let startMonth: Date
        if let firstEligibleMonth, firstEligibleMonth > thisMonth {
            startMonth = firstEligibleMonth
        } else {
            startMonth = thisMonth
        }

        if let date = chargeDate(dayOfMonth: dayOfMonth, in: startMonth, calendar: calendar),
           calendar.startOfDay(for: date) >= today {
            return date
        }
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startMonth) else {
            return nil
        }
        return chargeDate(dayOfMonth: dayOfMonth, in: nextMonth, calendar: calendar)
    }

    private static func nextAnnualChargeDate(
        anchorDate: Date,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        let today = calendar.startOfDay(for: now)
        let month = calendar.component(.month, from: anchorDate)
        let day = calendar.component(.day, from: anchorDate)
        let thisYear = calendar.component(.year, from: now)
        let anchorYear = calendar.component(.year, from: anchorDate)
        let startYear = max(thisYear, anchorYear)

        if let date = annualChargeDate(year: startYear, month: month, day: day, calendar: calendar),
           calendar.startOfDay(for: date) >= today {
            return date
        }
        return annualChargeDate(year: startYear + 1, month: month, day: day, calendar: calendar)
    }

    private static func chargeDate(dayOfMonth: Int, in monthDate: Date, calendar: Calendar) -> Date? {
        MonthDay.date(
            dayOfMonth: dayOfMonth,
            in: monthDate,
            hour: 12,
            minute: 0,
            calendar: calendar
        )
    }

    private static func annualChargeDate(year: Int, month: Int, day: Int, calendar: Calendar) -> Date? {
        var seed = DateComponents()
        seed.year = year
        seed.month = month
        seed.day = 1
        seed.hour = 12
        guard let monthStart = calendar.date(from: seed) else {
            return nil
        }
        return MonthDay.date(
            dayOfMonth: day,
            in: monthStart,
            hour: 12,
            minute: 0,
            calendar: calendar
        )
    }

    private static func isWithin(
        _ date: Date,
        now: Date,
        calendar: Calendar,
        days: Int
    ) -> Bool {
        let delta = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: date)
        ).day ?? .max
        return (0...days).contains(delta)
    }
}
