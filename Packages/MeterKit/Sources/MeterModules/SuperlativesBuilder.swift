import Foundation
import MeterCore
import MeterFormat

public enum SuperlativesBuilder {
    /// 挑谁在 `MeterCore/SuperlativeSelection`（连三块的顺序也在那里），这里只写字。
    public static func make(
        comparison: ComparisonModuleContent?,
        composition: CompositionModuleContent?,
        connections: [ProviderConnectionState],
        now: Date
    ) -> SuperlativesModuleContent? {
        let compared = comparison?.items ?? []
        let segments = composition?.segments ?? []
        let enabled = connections.filter(\.isEnabled)

        var items: [SuperlativeItem] = []
        for kind in SuperlativeSelection.order {
            switch kind {
            case .biggestRise:
                guard
                    let index = SuperlativeSelection.biggestRise(
                        changeRatios: compared.map(\.changeRatio)
                    ),
                    let ratio = compared[index].changeRatio
                else { continue }
                let rise = compared[index]
                items.append(SuperlativeItem(
                    kind: .biggestRise,
                    displayName: rise.displayName,
                    value: DashboardPercentFormat.signed(ratio),
                    colorKey: rise.colorKey,
                    accountID: rise.accountID,
                    providerID: rise.providerID
                ))
            case .biggestShare:
                guard let index = SuperlativeSelection.biggestShare(
                    fractions: segments.map(\.fraction)
                ) else { continue }
                let biggest = segments[index]
                items.append(SuperlativeItem(
                    kind: .biggestShare,
                    displayName: biggest.displayName,
                    value: "\(biggest.percent)%",
                    colorKey: biggest.colorKey,
                    accountID: biggest.accountID,
                    providerID: biggest.providerID
                ))
            case .stalest:
                guard
                    let index = SuperlativeSelection.stalest(
                        lastRefreshedAt: enabled.map(\.lastSuccessfulRefreshAt)
                    )
                else { continue }
                let stale = enabled[index]
                guard let descriptor = ProviderIdentity.known(stale.providerID) else { continue }
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .short
                let when = stale.lastSuccessfulRefreshAt
                    .map { formatter.localizedString(for: $0, relativeTo: now) }
                    ?? String(localized: L("还没刷过"))
                items.append(SuperlativeItem(
                    kind: .stalest,
                    displayName: AccountTitle.context(
                        for: stale.accountID,
                        connections: connections,
                        providerDisplayName: descriptor.displayName
                    ).visual,
                    value: when,
                    colorKey: descriptor.colorKey,
                    accountID: stale.accountID,
                    providerID: stale.providerID
                ))
            }
        }
        return items.isEmpty ? nil : SuperlativesModuleContent(items: items)
    }
}
