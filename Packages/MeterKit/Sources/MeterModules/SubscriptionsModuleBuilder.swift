import Foundation
import MeterCore
import MeterFormat

public enum SubscriptionsModuleBuilder {
    public static func make(
        subscriptions: [MonthlySubscription],
        connections: [ProviderConnectionState],
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation
    ) -> SubscriptionsModuleContent? {
        // 只列 `now` 那个月还在付的。**退掉的不属于这张卡**——
        // 它回答的是「我现在每月固定要出多少钱」，把上个季度退掉的那几笔加进来，
        // 合计会比首屏那行「本月订阅」多出一截，两个数字当场对不上。
        //
        // 起点那把闸也在这里（`isActive` 两把一起判）：下个月才首扣的订阅，
        // 这个月同样不该进合计。
        //
        // 用 `now` 不是「此刻」而是取景框锚点——回看七月时，列的是七月还在付的那几笔。
        let subscriptions = subscriptions.filter { $0.isActive(on: now, calendar: calendar) }
        guard !subscriptions.isEmpty else { return nil }
        // 年付按 12 摊成每月，合计才和「本月订阅」那一行同一个口径。
        let monthly = subscriptions.reduce(Money.zero) { total, item in
            switch item.period {
            case .monthly: total + item.amount
            case .annual: total + item.amount / 12
            }
        }
        let next = subscriptions
            .compactMap { item in
                UpcomingChargeCalculator.nextChargeDate(item, now: now, calendar: calendar).map { (item, $0) }
            }
            .min { $0.1 < $1.1 }
        let items = subscriptions
            .sorted { $0.amount.usd > $1.amount.usd }
            .map { item in
                let colorKey = item.providerID.flatMap { ProviderIdentity.known($0)?.colorKey }
                let period = item.period == .monthly
                    ? String(localized: L("每月"))
                    : String(localized: L("每年"))
                return SubscriptionRowItem(
                    id: "\(item.name)|\(item.anchorDate.timeIntervalSince1970)|\(item.providerID?.rawValue ?? "")",
                    name: item.name,
                    amountText: item.amount.formatted(using: presentation),
                    amountValue: NSDecimalNumber(decimal: presentation.amount(from: item.amount)).doubleValue,
                    periodCaption: period,
                    accountID: item.accountID,
                    providerID: item.providerID,
                    colorKey: colorKey,
                    spokenLabel: "\(item.name)，\(SpokenMoney.label(for: item.amount, presentation: presentation))，\(period)"
                )
            }
        return SubscriptionsModuleContent(
            monthlyTotalText: monthly.formatted(using: presentation),
            monthlyTotalValue: NSDecimalNumber(decimal: presentation.amount(from: monthly)).doubleValue,
            spokenTotal: SpokenMoney.label(for: monthly, presentation: presentation),
            countCaption: String(localized: L("\(subscriptions.count) 笔，折算每月。年付按 12 摊。")),
            nextChargeCaption: next.map { item, date in
                String(localized: L("下一笔：\(item.name)，\(MeterDateFormat.monthAndDay(date, calendar: calendar))"))
            },
            items: items
        )
    }
}
