import Foundation
import MeterCore
import MeterFormat

public enum AnomalyBuilder {
    public static func make(
        from monthToDate: MonthToDate,
        connections: [ProviderConnectionState],
        calendar: Calendar,
        presentation: MoneyPresentation = .usd
    ) -> AnomalyModuleContent? {
        guard let window = monthToDate.comparisonWindow else { return nil }
        let month = window.month(calendar: calendar)

        let items: [AnomalyItem] = monthToDate.facts.compactMap { fact in
            guard
                contributes(fact),
                let accountID = fact.accountID,
                let providerID = fact.providerID,
                let ratio = fact.changeRatio,
                ratio >= CatMoodResolver.shockedChangeRatio,
                let comparison = fact.comparisonUSD
            else {
                return nil
            }
            let descriptor = ProviderIdentity.known(providerID)
            let vendorName = descriptor?.displayName ?? providerID.rawValue
            let title = AccountTitle.context(
                for: accountID,
                connections: connections,
                providerDisplayName: vendorName
            )
            return AnomalyItem(
                accountID: accountID,
                providerID: providerID,
                displayName: title.visual,
                colorKey: descriptor?.colorKey ?? providerID.rawValue,
                changeRatio: ratio,
                comparisonUSD: comparison,
                comparisonMonth: month,
                presentation: presentation
            )
        }
        .sorted { lhs, rhs in
            if lhs.changeRatio != rhs.changeRatio { return lhs.changeRatio > rhs.changeRatio }
            return lhs.displayName < rhs.displayName
        }

        guard !items.isEmpty else { return nil }
        return AnomalyModuleContent(items: items)
    }

    private static func contributes(_ fact: Fact) -> Bool {
        switch fact.type {
        case .monthToDateUsage, .prepaidConsumption, .subscriptionIncluded:
            return true
        case .subscriptionSuperseded, .freeQuota, .fetchFailed:
            return false
        }
    }
}
