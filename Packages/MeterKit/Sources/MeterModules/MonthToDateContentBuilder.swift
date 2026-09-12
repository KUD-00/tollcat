import Foundation
import MeterCore
import MeterFormat

/// 把账本折算成首屏那一块的字。折算住在 MeterFeatures：它要认取景框、
/// 认接入状态，这些都不是 widget 该链进来的东西。
extension MonthToDateModuleContent {
    public static func make(
        from monthToDate: MonthToDate,
        estimatedNames: [String],
        staleCaption: String?,
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation = .usd,
        connections: [ProviderConnectionState] = []
    ) -> MonthToDateModuleContent {
        // 大数字说的是**当前口径下的本月账单**：算进订阅时是从量 + 订阅，
        // 关掉时 `totalUSD == variableUSD`，数字自动回到纯从量。
        // Widget 一直显示 `totalUSD`——首屏跟上之后两边才说同一个数。
        let spent = monthToDate.totalUSD
        let projected = monthToDate.projectedMonthEndUSD
        let filter = monthToDate.filter
        let months = monthToDate.window.monthCount
        let period = DashboardMonthFormat.period(now: now, calendar: calendar, monthCount: months)
        let spokenPeriod = DashboardMonthFormat.spokenPeriod(
            now: now,
            calendar: calendar,
            monthCount: months
        )
        let subscription = monthToDate.subscriptionUSD
        let subscriptionLine = Self.subscriptionLine(
            amount: subscription,
            included: filter.includesSubscriptions,
            accountIDs: monthToDate.subscriptionAccountIDs,
            presentation: presentation
        )

        return MonthToDateModuleContent(
            estimateCaption: monthToDate.confidence != .exact
                ? String(localized: L("含估算"))
                : nil,
            amountText: spent.formatted(using: presentation),
            totalValue: NSDecimalNumber(decimal: presentation.amount(from: spent)).doubleValue,
            spokenTotal: SpokenMoney.label(for: spent, presentation: presentation),
            // 外推那半句。过去某个月已经结束，没有可推的东西，这一半就没有。
            projectedCaption: filter.allowsProjection
                ? String(localized: L("预计月底 \(projected.formatted(using: presentation))"))
                : nil,
            // 统计区间那半句。当月能外推、多月区间：日期自己说话，前面不加「合计」。
            // 过去某个整月已经结束，才用「整月」把时态说清楚。
            periodCaption: Self.periodCaption(
                allowsProjection: filter.allowsProjection,
                monthCount: months,
                period: period
            ),
            projectedValue: NSDecimalNumber(decimal: presentation.amount(from: projected)).doubleValue,
            spokenProjected: filter.allowsProjection
                ? String(localized: L("预计月底 \(SpokenMoney.label(for: projected, presentation: presentation))，统计区间 \(spokenPeriod)"))
                : String(localized: L("统计区间 \(spokenPeriod)")),
            estimatedNames: estimatedNames,
            staleCaption: staleCaption,
            // 这个 `now` 是 `DashboardModel` 折算时用的锚点，不是真正的此刻。
            filterNote: DashboardFilterSummary.full(
                filter: filter,
                window: monthToDate.window,
                asOf: now,
                calendar: calendar,
                connections: connections
            ),
            currencyNote: presentation.isUSD ? nil : DisplayCurrencyCopy.shownAs(presentation.currencyCode),
            subscriptionCaption: subscriptionLine?.caption,
            spokenSubscription: subscriptionLine?.spoken,
            subscriptionAccountID: subscriptionLine?.accountID,
            includesSubscriptions: filter.includesSubscriptions,
            showsSubscriptionScope: subscription > .zero
        )
    }

    private static func periodCaption(
        allowsProjection: Bool,
        monthCount: Int,
        period: String
    ) -> String {
        // 前面已经有「预计月底 …」了，这里再写一遍前缀是重复。
        // 多月的日期自己就是一段，再加「合计」是废话。
        if allowsProjection || monthCount > 1 {
            return period
        }
        return String(localized: L("整月 · \(period)"))
    }

    private static func subscriptionLine(
        amount: Money,
        included: Bool,
        accountIDs: [AccountID],
        presentation: MoneyPresentation
    ) -> (caption: String, spoken: String, accountID: AccountID?)? {
        // 关掉订阅时这行不出现：口径切换已经说明「按量」，再写「未计入」是同一句话两遍。
        // 算进时也不写「已计入」——括号里的金额就是分解，不是限定语。
        guard included, amount > .zero else { return nil }
        let formatted = amount.formatted(using: presentation)
        let spokenAmount = SpokenMoney.label(for: amount, presentation: presentation)
        let accountID = accountIDs.count == 1 ? accountIDs[0] : nil
        // 订阅已经在大数字里，不能再写 `+`——那会被读成「另加」。
        return (
            String(localized: L("（订阅 \(formatted)）")),
            String(localized: L("订阅 \(spokenAmount)")),
            accountID
        )
    }
}
