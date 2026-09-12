import Foundation
import MeterCore
import MeterFormat

/// 口径跟着取景框走：算进订阅时，涨跌幅和分家列表都带上订阅
/// （订阅两边同额，方向仍由从量驱动，但量级和大数字说同一笔钱）。
public enum ComparisonBuilder {
    public static func make(
        from monthToDate: MonthToDate,
        connections: [ProviderConnectionState] = [],
        calendar: Calendar,
        presentation: MoneyPresentation = .usd,
        sublines: [SpendAttribution: [SpendSubline]] = [:]
    ) -> ComparisonModuleContent {
        let includesSubscriptions = monthToDate.filter.includesSubscriptions
        let currentLabel = String(localized: L("本月"))
        let previousLabel = String(localized: L("上月"))
        let monthName: String
        if let window = monthToDate.comparisonWindow {
            monthName = MeterDateFormat.monthName(now: window.start, calendar: calendar)
        } else {
            monthName = previousLabel
        }
        let items = items(
            from: monthToDate,
            connections: connections,
            presentation: presentation,
            sublines: sublines
        )

        guard let comparison = VariableComparison.make(
            from: monthToDate,
            includingSubscriptions: includesSubscriptions
        ) else {
            let unavailable = String(localized: L("还不能对比"))
            return ComparisonModuleContent(
                percentText: "—",
                caption: unavailable,
                windowCaption: unavailable,
                spokenLabel: String(localized: L("还不能和上月同期对比")),
                current: NSDecimalNumber(decimal: presentation.amount(from: monthToDate.totalUSD)).doubleValue,
                previous: 0,
                currentLabel: currentLabel,
                previousLabel: previousLabel,
                tone: .unknown,
                previousMonthName: monthName,
                items: items
            )
        }

        let ratio = comparison.ratio ?? 0
        let percentText = comparison.ratio.map(DashboardPercentFormat.signed) ?? String(localized: L("持平"))
        let previousAmount = comparison.previous.formatted(using: presentation)
        // 口径写在窗口说明里：两种口径的这一页不该「看起来一样」。
        let scopeWord = includesSubscriptions
            ? String(localized: L("含订阅"))
            : String(localized: L("仅按量"))
        var captionParts = [
            String(localized: L("对比 \(monthName)同期 \(previousAmount)")),
        ]
        if comparison.skippedCount > 0 {
            captionParts.append(
                String(
                    localized: L("含还不能对比 \(comparison.skippedCurrent.formatted(using: presentation))")
                )
            )
        }
        captionParts.append(scopeWord)
        let windowCaption = captionParts.joined(separator: " · ")
        let caption = windowCaption
        let spoken = includesSubscriptions
            ? String(localized: L("合计较上月同期 \(DashboardPercentFormat.spokenSigned(ratio))，\(caption)"))
            : String(localized: L("按量较上月同期 \(DashboardPercentFormat.spokenSigned(ratio))，\(caption)"))
        let tone: ComparisonModuleContent.Tone
        if let ratio = comparison.ratio {
            if ratio > 0 { tone = .up }
            else if ratio < 0 { tone = .down }
            else { tone = .flat }
        } else {
            tone = .flat
        }

        return ComparisonModuleContent(
            percentText: percentText,
            caption: caption,
            windowCaption: windowCaption,
            spokenLabel: spoken,
            current: NSDecimalNumber(decimal: presentation.amount(from: comparison.current)).doubleValue,
            previous: NSDecimalNumber(decimal: presentation.amount(from: comparison.previous)).doubleValue,
            currentLabel: currentLabel,
            previousLabel: previousLabel,
            tone: tone,
            previousMonthName: monthName,
            items: items
        )
    }

    /// 分家列表和构成条共用 `SpendAttribution` 的归属：无主订阅也占一行，
    /// 否则「含订阅」口径下顶部涨跌幅里有它、下面的明细里却找不到。
    private static func items(
        from monthToDate: MonthToDate,
        connections: [ProviderConnectionState],
        presentation: MoneyPresentation,
        sublines: [SpendAttribution: [SpendSubline]]
    ) -> [ComparisonItem] {
        var current: [SpendAttribution: Money] = [:]
        var previous: [SpendAttribution: Money] = [:]
        var comparable: [SpendAttribution: Bool] = [:]
        var providers: [AccountID: ProviderID] = [:]
        var seen: [SpendAttribution] = []

        for fact in monthToDate.facts {
            guard fact.type.contributesToTotal,
                  let amount = fact.amountUSD else { continue }
            let hasComparison = fact.comparisonUSD != nil
            if amount <= .zero, !hasComparison { continue }

            let key = SpendAttribution.attribute(fact, connections: connections)
            if case .account(let id) = key, providers[id] == nil, let providerID = fact.providerID {
                providers[id] = providerID
            }
            if current[key] == nil {
                seen.append(key)
                comparable[key] = true
            }
            current[key, default: .zero] += amount
            if let comparison = fact.comparisonUSD {
                previous[key, default: .zero] += comparison
            } else if amount > .zero {
                comparable[key] = false
            }
        }

        let items: [ComparisonItem] = seen.compactMap { key in
            guard let amount = current[key] else { return nil }
            let canCompare = comparable[key] == true
            let previousAmount = canCompare ? previous[key] : nil
            let changeRatio = ChangeRatio.compute(current: amount, previous: previousAmount)
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
                return ComparisonItem(
                    accountID: id,
                    providerID: providerID,
                    displayName: title.visual,
                    colorKey: descriptor?.colorKey ?? providerID.rawValue,
                    currentUSD: amount,
                    previousUSD: previousAmount,
                    changeRatio: changeRatio,
                    presentation: presentation,
                    sublines: sublines[key] ?? []
                )
            case .vendor(let providerID):
                let descriptor = ProviderIdentity.known(providerID)
                return ComparisonItem(
                    accountID: nil,
                    providerID: providerID,
                    displayName: descriptor?.displayName ?? providerID.rawValue,
                    colorKey: descriptor?.colorKey ?? providerID.rawValue,
                    currentUSD: amount,
                    previousUSD: previousAmount,
                    changeRatio: changeRatio,
                    presentation: presentation,
                    sublines: sublines[key] ?? []
                )
            case .manual:
                return ComparisonItem(
                    accountID: nil,
                    providerID: nil,
                    displayName: String(localized: L("手动订阅")),
                    colorKey: "manual",
                    currentUSD: amount,
                    previousUSD: previousAmount,
                    changeRatio: changeRatio,
                    presentation: presentation,
                    sublines: sublines[key] ?? []
                )
            }
        }

        let comparableItems = items.filter(\.isComparable).sorted { lhs, rhs in
            let left = lhs.currentUSD - (lhs.previousUSD ?? .zero)
            let right = rhs.currentUSD - (rhs.previousUSD ?? .zero)
            if left != right { return left > right }
            return lhs.displayName < rhs.displayName
        }
        let skippedItems = items.filter { !$0.isComparable }.sorted { lhs, rhs in
            if lhs.currentUSD != rhs.currentUSD { return lhs.currentUSD > rhs.currentUSD }
            return lhs.displayName < rhs.displayName
        }
        return comparableItems + skippedItems
    }
}
