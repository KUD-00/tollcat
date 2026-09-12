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
            // 统计区间那半句。三种说法对应三种时态：当月能外推（区间自己说话），
            // 过去某个整月已经结束，多月区间是一段的合计——没有「月底」可言，
            // 也不该借用「整月」这个词。
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
        if allowsProjection {
            return period
        }
        if monthCount > 1 {
            return String(localized: L("合计 · \(period)"))
        }
        return String(localized: L("整月 · \(period)"))
    }

    private static func subscriptionLine(
        amount: Money,
        included: Bool,
        accountIDs: [AccountID],
        presentation: MoneyPresentation
    ) -> (caption: String, spoken: String, accountID: AccountID?)? {
        guard amount > .zero else { return nil }
        let formatted = amount.formatted(using: presentation)
        let spokenAmount = SpokenMoney.label(for: amount, presentation: presentation)
        let accountID = accountIDs.count == 1 ? accountIDs[0] : nil
        if included {
            // 订阅已经在大数字里，不能再写 `+`——那会被读成「另加」。
            return (
                String(localized: L("本月订阅 \(formatted) · 已计入")),
                String(localized: L("本月订阅 \(spokenAmount)，已计入合计，可查看详情")),
                accountID
            )
        }
        return (
            String(localized: L("本月订阅 \(formatted) · 未计入")),
            String(localized: L("本月订阅 \(spokenAmount)，未计入合计")),
            accountID
        )
    }
}
