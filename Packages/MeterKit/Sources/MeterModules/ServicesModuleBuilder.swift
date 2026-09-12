import Foundation
import MeterCore
import MeterFormat

public enum ServicesModuleBuilder {
    public static func make(
        pinned: [AccountID],
        connections: [ProviderConnectionState],
        dailySpend: (AccountID) -> [Date: Money],
        composition: CompositionModuleContent?,
        comparison: ComparisonModuleContent?,
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation
    ) -> ServicesModuleContent? {
        let enabled = Dictionary(uniqueKeysWithValues: connections.filter(\.isEnabled).map { ($0.accountID, $0) })
        let items: [ServiceCardItem] = pinned.compactMap { accountID in
            guard let connection = enabled[accountID],
                  let descriptor = ProviderIdentity.known(connection.providerID)
            else { return nil }
            let segment = composition?.segments.first { $0.accountID == accountID }
            let compared = comparison?.items.first { $0.accountID == accountID }
            let amount = segment?.amount ?? compared?.currentUSD ?? .zero
            let title = AccountTitle.context(
                for: accountID,
                connections: connections,
                providerDisplayName: descriptor.displayName
            ).visual
            return ServiceCardItem(
                accountID: accountID,
                providerID: connection.providerID,
                displayName: title,
                colorKey: descriptor.colorKey,
                amountText: amount.formatted(using: presentation),
                amountValue: NSDecimalNumber(decimal: presentation.amount(from: amount)).doubleValue,
                spokenAmount: SpokenMoney.label(for: amount, presentation: presentation),
                changeText: compared?.changeRatio.map(DashboardPercentFormat.signed),
                changeIsUp: (compared?.changeRatio ?? 0) > 0,
                spark: spark(daily: dailySpend(accountID), now: now, calendar: calendar)
            )
        }
        return items.isEmpty ? nil : ServicesModuleContent(items: items)
    }

    /// 近 30 天，一天一格，旧到新，缺的天记 0。
    ///
    /// **日线不是月线**：这块叫「特别关心」，盯的是这几家最近怎么花的。
    /// 月线一个月才动一格，「昨天忽然涨了」在上面根本看不出来——那正是要盯的东西。
    ///
    /// 日额来自快照自带的 `dailyUSD`（`SnapshotDailyMap` 只认按量那几类）。
    /// 拿不到按日粒度的家返回空数组，行上就不画这条线——**不要拿月额除以天数糊一条**，
    /// 那是一条假的平线，比没有更误导。
    /// 收**现成的按天花费**（`LedgerView.dailySpend(for:)`）。
    public static func spark(
        daily: [Date: Money],
        now: Date,
        calendar: Calendar,
        days: Int = 30
    ) -> [Double] {
        guard !daily.isEmpty else { return [] }
        let today = calendar.startOfDay(for: now)
        return (0..<days).reversed().compactMap { back in
            guard let day = calendar.date(byAdding: .day, value: -back, to: today) else { return nil }
            return NSDecimalNumber(decimal: (daily[day] ?? .zero).usd).doubleValue
        }
    }
}
