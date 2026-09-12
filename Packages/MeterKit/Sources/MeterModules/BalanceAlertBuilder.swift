import Foundation
import MeterCore
import MeterFormat

public enum BalanceAlertBuilder {
    public static func make(
        runways: [PrepaidRunway],
        connections: [ProviderConnectionState],
        presentation: MoneyPresentation = .usd
    ) -> BalanceAlertModuleContent? {
        let items: [BalanceAlertItem] = runways.compactMap { runway in
            guard runway.daysRemaining <= CatMoodResolver.prepaidAlertDays else {
                return nil
            }
            let descriptor = ProviderIdentity.known(runway.providerID)
            let vendorName = descriptor?.displayName ?? runway.providerID.rawValue
            let title = AccountTitle.context(
                for: runway.accountID,
                connections: connections,
                providerDisplayName: vendorName
            )
            return BalanceAlertItem(
                accountID: runway.accountID,
                providerID: runway.providerID,
                displayName: title.visual,
                colorKey: descriptor?.colorKey ?? runway.providerID.rawValue,
                balanceUSD: runway.balanceUSD,
                daysRemaining: runway.daysRemaining,
                presentation: presentation
            )
        }
        .sorted { lhs, rhs in
            if lhs.daysRemaining != rhs.daysRemaining { return lhs.daysRemaining < rhs.daysRemaining }
            return lhs.displayName < rhs.displayName
        }

        guard !items.isEmpty else { return nil }
        return BalanceAlertModuleContent(items: items)
    }
}
