import Foundation
import MeterCore
import MeterFormat

/// 从折算 facts 抽出构成条。没有正金额就不建这个模块。
///
/// 口径跟着取景框走：算进订阅时订阅也要占段（订阅 fact 只在取景框放行时
/// 才存在，这里不用再判 filter）。归属规则见 `SpendAttribution`——
/// 少任何一段，「含订阅」口径下饼图都加不回大数字。
public enum CompositionBuilder {
    public static func make(
        from monthToDate: MonthToDate,
        connections: [ProviderConnectionState],
        presentation: MoneyPresentation = .usd,
        sublines: [SpendAttribution: [SpendSubline]] = [:]
    ) -> CompositionModuleContent? {
        var amounts: [SpendAttribution: Money] = [:]
        var providers: [AccountID: ProviderID] = [:]
        var seen: [SpendAttribution] = []

        for fact in monthToDate.facts {
            guard fact.type.contributesToTotal,
                  let amount = fact.amountUSD,
                  amount > .zero else {
                continue
            }
            let key = SpendAttribution.attribute(fact, connections: connections)
            if case .account(let id) = key, providers[id] == nil, let providerID = fact.providerID {
                providers[id] = providerID
            }
            if amounts[key] == nil {
                seen.append(key)
            }
            amounts[key, default: .zero] += amount
        }

        let ordered = seen.sorted { lhs, rhs in
            let left = amounts[lhs] ?? .zero
            let right = amounts[rhs] ?? .zero
            if left != right { return left > right }
            return lhs.sortKey < rhs.sortKey
        }

        let weights = ordered.map { amounts[$0]?.usd ?? 0 }
        let percents = IntegerPercents.from(weights: weights)
        let total = weights.reduce(0, +)
        guard total > 0 else { return nil }

        let segments: [CompositionSegment] = zip(ordered, percents).compactMap { key, percent in
            guard let amount = amounts[key] else { return nil }
            let fraction = NSDecimalNumber(decimal: amount.usd / total).doubleValue
            switch key {
            case .account(let id):
                let providerID = providers[id]
                    ?? connections.first { $0.accountID == id }?.providerID
                guard let providerID else { return nil }
                let descriptor = ProviderIdentity.known(providerID)
                let vendorName = descriptor?.displayName ?? providerID.rawValue
                let title = AccountTitle.context(
                    for: id,
                    connections: connections,
                    providerDisplayName: vendorName
                )
                return CompositionSegment(
                    accountID: id,
                    providerID: providerID,
                    displayName: title.visual,
                    colorKey: descriptor?.colorKey ?? providerID.rawValue,
                    amount: amount,
                    fraction: fraction,
                    percent: percent,
                    sublines: sublines[key] ?? []
                )
            case .vendor(let providerID):
                let descriptor = ProviderIdentity.known(providerID)
                return CompositionSegment(
                    accountID: nil,
                    providerID: providerID,
                    displayName: descriptor?.displayName ?? providerID.rawValue,
                    colorKey: descriptor?.colorKey ?? providerID.rawValue,
                    amount: amount,
                    fraction: fraction,
                    percent: percent,
                    sublines: sublines[key] ?? []
                )
            case .manual:
                return CompositionSegment(
                    accountID: nil,
                    providerID: nil,
                    displayName: String(localized: L("手动订阅")),
                    colorKey: "manual",
                    amount: amount,
                    fraction: fraction,
                    percent: percent,
                    sublines: sublines[key] ?? []
                )
            }
        }

        guard let leader = segments.first else { return nil }

        return CompositionModuleContent(
            segments: segments,
            totalText: monthToDate.totalUSD.formatted(using: presentation),
            spokenTotal: SpokenMoney.label(for: monthToDate.totalUSD, presentation: presentation),
            destination: leader.accountID
        )
    }
}
