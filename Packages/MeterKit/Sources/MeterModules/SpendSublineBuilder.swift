import Foundation
import MeterCore
import MeterFormat

/// 快照明细 + 手动订阅 → 各归属段的子服务小行。给仪表盘两张详情页（构成 / 较上月同期）用。
///
/// 键是 `SpendAttribution` 而不是账号：仅订阅的家（挂厂商的无主订阅、手动订阅段）
/// 也有自己的段，它们的子行是一笔笔订阅套餐，不是用量类别。
public enum SpendSublineBuilder {
    /// 和 `SpendGrouping.maxGroups` 同一档：再多没人看，尾巴并成「其他」。
    public static let maxSublines = 6

    /// - Parameters:
    ///   - subscriptions: **只在取景框算进订阅时传**。段合计来自 fact，订阅 fact
    ///     不存在时把订阅列进子行，加起来会比段还多。
    ///   - asOf: 取景框的「此刻」。回看七月时是七月最后一瞬，年付是否记在当月由它定。
    ///   - comparisonWindow: 有值时，同窗口内刷到过的明细会带上同期金额和涨跌。
    ///     构成页不传——那一页只回答「钱去了哪」。
    /// - Parameters:
    ///   - lines: 每个账号截止 `asOf` 最近的一份明细（`LedgerView.lines(onOrBefore:)`）。
    ///   - previousLines: 同期窗口**内**观测到的那一份。判据和上面那个不同，
    ///     所以是两个参数而不是让这里自己去挑——挑的规则只该有一处实现。
    public static func byAttribution(
        lines: [AccountID: [SpendLine]],
        previousLines: [AccountID: [SpendLine]] = [:],
        subscriptions: [MonthlySubscription],
        connections: [ProviderConnectionState],
        asOf: Date,
        calendar: Calendar,
        presentation: MoneyPresentation,
        comparisonWindow: ComparisonWindow? = nil
    ) -> [SpendAttribution: [SpendSubline]] {
        var entries: [SpendAttribution: [Entry]] = [:]
        let previousMonthName: String
        if let window = comparisonWindow {
            previousMonthName = MeterDateFormat.monthName(now: window.start, calendar: calendar)
        } else {
            previousMonthName = ""
        }

        // 明细**不合并历次**——它是「这一刻这家的构成」，把历次加起来会把 $10 加成 $800。
        // 挑哪一份是账本折叠时的事，这里只负责摆。
        for (id, entryLines) in lines {
            let usage = usageEntries(lines: entryLines)
            guard !usage.isEmpty else { continue }
            let previousByID: [String: Money]
            if let previous = previousLines[id] {
                previousByID = Dictionary(
                    uniqueKeysWithValues: usageEntries(lines: previous).map { ($0.id, $0.amount) }
                )
            } else {
                previousByID = [:]
            }
            let merged = usage.map { entry in
                var result = entry
                result.previous = previousByID[entry.id]
                return result
            }
            entries[.account(id), default: []].append(contentsOf: merged)
        }

        // 订阅逐笔列，不并类——「具体是哪个套餐」正是这行要回答的。
        // 本月没扣的（年付非周年月、还没开始）计 0，也就不占行。
        for subscription in subscriptions {
            let amount = MonthToDateCalculator.subscriptionAmount(
                subscription,
                now: asOf,
                calendar: calendar
            )
            guard amount > .zero else { continue }
            let key = SpendAttribution.attribute(
                accountID: subscription.accountID,
                providerID: subscription.providerID,
                connections: connections
            )
            let title = subscription.quantity > 1
                ? "\(subscription.name) ×\(subscription.quantity)"
                : subscription.name
            var entry = Entry(id: "subscription|\(title)", title: title, amount: amount)
            if let window = comparisonWindow {
                let previous = MonthToDateCalculator.subscriptionAmount(
                    subscription,
                    now: window.end,
                    calendar: calendar
                )
                if previous > .zero {
                    entry.previous = previous
                }
            }
            entries[key, default: []].append(entry)
        }

        return entries.compactMapValues { list in
            let sublines = collapsed(
                list,
                presentation: presentation,
                previousMonthName: previousMonthName
            )
            return sublines.isEmpty ? nil : sublines
        }
    }

    /// 只有用量明细的版本，给测试和单独取数用。
    public static func make(
        lines: [SpendLine],
        presentation: MoneyPresentation
    ) -> [SpendSubline] {
        collapsed(usageEntries(lines: lines), presentation: presentation, previousMonthName: "")
    }

    // MARK: - 聚合

    private struct Entry {
        var id: String
        var title: String
        var amount: Money
        var previous: Money? = nil
    }

    /// 按类别聚合，丢掉 $0 的行。用量说明不带——这两页的问题是「钱去了哪」，
    /// Minutes / GigabyteHours 在这里只会把一行撑成两行；要看用量去详情页的「花在哪了」。
    private static func usageEntries(lines: [SpendLine]) -> [Entry] {
        var order: [String] = []
        var amounts: [String: Money] = [:]
        for line in lines where line.amountUSD > .zero {
            if amounts[line.category] == nil {
                order.append(line.category)
            }
            amounts[line.category, default: .zero] += line.amountUSD
        }
        return order.map { Entry(id: $0, title: $0, amount: amounts[$0] ?? .zero) }
    }

    /// 排序 + 超出 `maxSublines` 的尾巴并成「其他」+ 格式化。
    private static func collapsed(
        _ list: [Entry],
        presentation: MoneyPresentation,
        previousMonthName: String
    ) -> [SpendSubline] {
        var entries = list.sorted { lhs, rhs in
            if lhs.amount != rhs.amount { return lhs.amount > rhs.amount }
            return lhs.title < rhs.title
        }
        if entries.count > maxSublines {
            let tail = Array(entries.suffix(from: maxSublines - 1))
            let other = tail.reduce(Money.zero) { $0 + $1.amount }
            let otherPrevious: Money?
            if tail.allSatisfy({ $0.previous != nil }) {
                otherPrevious = tail.reduce(Money.zero) { $0 + ($1.previous ?? .zero) }
            } else {
                otherPrevious = nil
            }
            entries = Array(entries.prefix(maxSublines - 1))
            entries.append(
                Entry(
                    id: "__other__",
                    title: String(localized: L("其他")),
                    amount: other,
                    previous: otherPrevious
                )
            )
        }
        return entries.map { format($0, presentation: presentation, previousMonthName: previousMonthName) }
    }

    private static func format(
        _ entry: Entry,
        presentation: MoneyPresentation,
        previousMonthName: String
    ) -> SpendSubline {
        let amountCaption = entry.amount.formatted(using: presentation)
        var spoken = String(
            localized: L(
                "\(entry.title)，\(SpokenMoney.label(for: entry.amount, presentation: presentation))"
            )
        )
        var comparisonSubtitle: String?
        var changeCaption: String?
        var changeRatio: Double?
        if let previous = entry.previous, previous > .zero {
            let previousCaption = previous.formatted(using: presentation)
            let subtitle = String(
                localized: L("本月 \(amountCaption) · \(previousMonthName)同期 \(previousCaption)")
            )
            comparisonSubtitle = subtitle
            if let ratio = ChangeRatio.compute(current: entry.amount, previous: previous) {
                changeCaption = DashboardPercentFormat.signed(ratio)
                changeRatio = ratio
                spoken = String(
                    localized: L(
                        "\(entry.title) 较上月同期 \(DashboardPercentFormat.spokenSigned(ratio))，\(subtitle)"
                    )
                )
            } else {
                changeCaption = String(localized: L("持平"))
                spoken = String(
                    localized: L("\(entry.title) 较上月同期持平，本月 \(amountCaption)")
                )
            }
        }
        return SpendSubline(
            id: entry.id,
            title: entry.title,
            amountCaption: amountCaption,
            spokenLabel: spoken,
            comparisonSubtitle: comparisonSubtitle,
            changeCaption: changeCaption,
            changeRatio: changeRatio
        )
    }
}
