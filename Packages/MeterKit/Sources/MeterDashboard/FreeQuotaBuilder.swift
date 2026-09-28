import Foundation
import MeterCore
import MeterFormat

public enum FreeQuotaBuilder {
    public static func make(
        from monthToDate: MonthToDate,
        connections: [ProviderConnectionState]
    ) -> FreeQuotaModuleContent? {
        let items: [FreeQuotaItem] = monthToDate.facts.compactMap { fact in
            guard
                fact.type == .freeQuota,
                let accountID = fact.accountID,
                let providerID = fact.providerID,
                let ratio = fact.freeQuotaUsedRatio,
                ratio >= DashboardModuleThresholds.freeQuotaUsedRatio
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
            return FreeQuotaItem(
                accountID: accountID,
                providerID: providerID,
                displayName: title.visual,
                colorKey: descriptor?.colorKey ?? providerID.rawValue,
                usedRatio: ratio
            )
        }
        .sorted { lhs, rhs in
            if lhs.usedRatio != rhs.usedRatio { return lhs.usedRatio > rhs.usedRatio }
            return lhs.displayName < rhs.displayName
        }

        guard !items.isEmpty else { return nil }
        return FreeQuotaModuleContent(items: items)
    }
}
