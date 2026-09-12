import Foundation
import MeterCore
import MeterFormat

public enum UpcomingChargesBuilder {
    /// 收**每账号一行的此刻状态**。「哪条读数报的档位算数」在折叠时判过了。
    public static func make(
        latest: [AccountLatest],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation = .usd
    ) -> UpcomingChargesModuleContent? {
        let charges = UpcomingChargeCalculator.charges(
            latest: latest,
            subscriptions: subscriptions,
            now: now,
            calendar: calendar,
            withinDays: DashboardModuleThresholds.upcomingChargeDays
        )
        let items = charges.map { charge in
            let descriptor = charge.providerID.flatMap { ProviderIdentity.known($0) }
            let displayName: String
            if !charge.name.isEmpty {
                displayName = charge.name
            } else {
                displayName = descriptor?.displayName ?? charge.providerID?.rawValue ?? String(localized: L("订阅"))
            }
            let identity = charge.accountID?.rawValue.uuidString ?? "manual"
            return UpcomingChargeItem(
                id: "\(identity)-\(charge.name)-\(charge.chargeDate.timeIntervalSince1970)",
                accountID: charge.accountID,
                providerID: charge.providerID,
                displayName: displayName,
                colorKey: descriptor?.colorKey,
                amount: charge.amount,
                chargeDate: charge.chargeDate,
                dateCaption: dateCaption(charge.chargeDate, now: now, calendar: calendar),
                presentation: presentation
            )
        }
        guard !items.isEmpty else { return nil }
        return UpcomingChargesModuleContent(items: items)
    }

    private static func dateCaption(_ date: Date, now: Date, calendar: Calendar) -> String {
        if let named = MeterDateFormat.todayOrTomorrow(date, now: now, calendar: calendar) {
            return named
        }
        return MeterDateFormat.monthAndDay(date, calendar: calendar)
    }
}
