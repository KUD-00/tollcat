import Foundation
import MeterCore
import MeterFormat

public enum SubscriptionsModuleBuilder {
    public static func make(
        subscriptions: [MonthlySubscription],
        connections: [ProviderConnectionState],
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation,
        window: MonthWindow = .currentMonth
    ) -> SubscriptionsModuleContent? {
        if window.isSingleMonth {
            return monthlyRunRate(
                subscriptions: subscriptions,
                now: now,
                calendar: calendar,
                presentation: presentation
            )
        }
        return periodCharges(
            subscriptions: subscriptions,
            now: now,
            calendar: calendar,
            presentation: presentation,
            window: window
        )
    }

    /// 单月：回答「那个月每月固定要出多少」。年付按 12 摊，和首屏那行对得上的
    /// 是「还在付」这件事，不是扣款日——非周年月金额是 $0，卡上仍要看见它。
    ///
    /// `now` 是取景框锚点：回看七月时，列的是七月还在付的那几笔。
    private static func monthlyRunRate(
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation
    ) -> SubscriptionsModuleContent? {
        let subscriptions = subscriptions.filter { $0.isActive(on: now, calendar: calendar) }
        guard !subscriptions.isEmpty else { return nil }
        let monthly = subscriptions.reduce(Money.zero) { total, item in
            switch item.period {
            case .monthly: total + item.amount
            case .annual: total + item.amount / 12
            }
        }
        return SubscriptionsModuleContent(
            monthlyTotalText: monthly.formatted(using: presentation),
            monthlyTotalValue: NSDecimalNumber(decimal: presentation.amount(from: monthly)).doubleValue,
            spokenTotal: SpokenMoney.label(for: monthly, presentation: presentation),
            headlineCaption: String(localized: L("每月")),
            isMonthlyRunRate: true,
            countCaption: String(localized: L("\(subscriptions.count) 笔，折算每月。年付按 12 摊。")),
            nextChargeCaption: nextChargeCaption(
                in: subscriptions,
                now: now,
                calendar: calendar
            ),
            items: subscriptions
                .sorted { $0.amount.usd > $1.amount.usd }
                .map { item in
                    row(
                        item,
                        amount: item.amount,
                        periodCaption: item.period == .monthly
                            ? String(localized: L("每月"))
                            : String(localized: L("每年")),
                        presentation: presentation
                    )
                }
        )
    }

    /// 多月：回答「这段时间订阅扣了多少」。和首屏那行同一个数——每个月各算一遍
    /// 再加起来，退掉的、周年月扣过的都在。折算每月在这里没有意义：三个月的
    /// Netflix 是三笔，不是一笔月费。
    ///
    /// `now` 仍是窗口最新那个月的锚点。往前数 `window.monthCount` 个整月，
    /// 不拿 `monthsBackNewestFirst`——那串整数相对的是今天，窗口若停在七月会指错月。
    private static func periodCharges(
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation,
        window: MonthWindow
    ) -> SubscriptionsModuleContent? {
        let anchors = monthAnchors(asOf: now, monthCount: window.monthCount, calendar: calendar)
        var rows: [(subscription: MonthlySubscription, charged: Money, chargedMonths: Int)] = []
        for subscription in subscriptions {
            var charged = Money.zero
            var chargedMonths = 0
            for asOf in anchors {
                let amount = MonthToDateCalculator.subscriptionAmount(
                    subscription,
                    now: asOf,
                    calendar: calendar
                )
                guard amount > .zero else { continue }
                charged += amount
                chargedMonths += 1
            }
            guard charged > .zero else { continue }
            rows.append((subscription, charged, chargedMonths))
        }
        guard !rows.isEmpty else { return nil }

        let total = rows.reduce(Money.zero) { $0 + $1.charged }
        let containsNow = window.newestBack == 0
        let activeNow = containsNow
            ? subscriptions.filter { $0.isActive(on: now, calendar: calendar) }
            : []
        return SubscriptionsModuleContent(
            monthlyTotalText: total.formatted(using: presentation),
            monthlyTotalValue: NSDecimalNumber(decimal: presentation.amount(from: total)).doubleValue,
            spokenTotal: SpokenMoney.label(for: total, presentation: presentation),
            headlineCaption: String(localized: L("合计")),
            isMonthlyRunRate: false,
            countCaption: String(localized: L("\(rows.count) 笔，这段时间合计。")),
            nextChargeCaption: nextChargeCaption(
                in: activeNow,
                now: now,
                calendar: calendar
            ),
            items: rows
                .sorted { $0.charged.usd > $1.charged.usd }
                .map { item, charged, chargedMonths in
                    row(
                        item,
                        amount: charged,
                        periodCaption: periodCaption(for: item, chargedMonths: chargedMonths),
                        presentation: presentation
                    )
                }
        )
    }

    private static func monthAnchors(
        asOf: Date,
        monthCount: Int,
        calendar: Calendar
    ) -> [Date] {
        (0..<monthCount).map { offset in
            DashboardPeriod.months(back: offset, count: 1).anchor(now: asOf, calendar: calendar)
        }
    }

    private static func periodCaption(
        for subscription: MonthlySubscription,
        chargedMonths: Int
    ) -> String {
        switch subscription.period {
        case .monthly:
            chargedMonths <= 1
                ? String(localized: L("每月"))
                : String(localized: L("每月 × \(chargedMonths)"))
        case .annual:
            String(localized: L("每年"))
        }
    }

    private static func nextChargeCaption(
        in subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar
    ) -> String? {
        subscriptions
            .compactMap { item in
                UpcomingChargeCalculator.nextChargeDate(item, now: now, calendar: calendar)
                    .map { (item, $0) }
            }
            .min { $0.1 < $1.1 }
            .map { item, date in
                String(localized: L("下一笔：\(item.name)，\(MeterDateFormat.monthAndDay(date, calendar: calendar))"))
            }
    }

    private static func row(
        _ item: MonthlySubscription,
        amount: Money,
        periodCaption: String,
        presentation: MoneyPresentation
    ) -> SubscriptionRowItem {
        let colorKey = item.providerID.flatMap { ProviderIdentity.known($0)?.colorKey }
        return SubscriptionRowItem(
            id: "\(item.name)|\(item.anchorDate.timeIntervalSince1970)|\(item.providerID?.rawValue ?? "")",
            name: item.name,
            amountText: amount.formatted(using: presentation),
            amountValue: NSDecimalNumber(decimal: presentation.amount(from: amount)).doubleValue,
            periodCaption: periodCaption,
            accountID: item.accountID,
            providerID: item.providerID,
            colorKey: colorKey,
            spokenLabel: "\(item.name)，\(SpokenMoney.label(for: amount, presentation: presentation))，\(periodCaption)"
        )
    }
}
