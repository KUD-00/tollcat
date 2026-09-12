import Foundation
import MeterCore
import MeterFormat
import MeterProviders

/// 可选仪表模块的 JSON。
///
/// **规则一条都不在这里。** 格子怎么排、类别怎么加、之最挑谁、预算条读数多少、
/// 明细怎么分组，全在 `MeterCore`（`HeatmapMonths` / `CategoryShares` /
/// `SuperlativeSelection` / `BudgetGauge`）——`MeterModules` 里的 builder 调的是
/// 同一批函数。这一层只做两件事：把值写成字、把字塞进字典。
///
/// 为什么不直接链 `MeterModules`：那一层有 SwiftUI（经 `MeterDesign`），
/// Android SDK 上编不出来。所以共享的那一半下沉到了零依赖的 `MeterCore`。
enum ProductDashboardModules {
    static func attach(
        to object: inout [String: Any],
        ledger: LedgerView,
        subscriptions: [MonthlySubscription],
        result: MonthToDate,
        composition: [CompositionEntry],
        comparisons: [ComparisonEntry],
        filter: DashboardFilter,
        layout: DashboardLayout,
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation,
        localeTag: String
    ) {
        object["heatmap"] = heatmap(
            ledger: ledger,
            now: now,
            calendar: calendar,
            presentation: presentation,
            localeTag: localeTag
        )
        object["categories"] = categories(composition: composition, presentation: presentation)
        if filter.showsPresentTenseModules, filter.period.allowsProjection {
            object["budget"] = budget(
                result: result,
                layout: layout,
                presentation: presentation
            ) as Any
        }
        object["superlatives"] = superlatives(
            composition: composition,
            comparisons: comparisons,
            ledger: ledger,
            now: now,
            localeTag: localeTag
        )
        object["pinnedServices"] = pinnedServices(
            pinned: layout.pinnedAccounts,
            ledger: ledger,
            composition: composition,
            comparisons: comparisons,
            now: now,
            calendar: calendar,
            presentation: presentation,
            localeTag: localeTag
        )
        object["subscriptionsModule"] = subscriptionsModule(
            subscriptions: filter.scope(subscriptions),
            now: now,
            calendar: calendar,
            presentation: presentation,
            localeTag: localeTag
        ) as Any
    }

    // MARK: - 日历热力图

    private static func heatmap(
        ledger: LedgerView,
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation,
        localeTag: String
    ) -> [[String: Any]] {
        HeatmapMonths.make(dailyTotals: ledger.dailyTotals(), now: now, calendar: calendar)
            .map { month in
                var row: [String: Any] = [
                    "monthStartMillis": Int(ProductClock.millis(month.monthStart)),
                    "title": MeterDateFormat.yearMonth(month.monthStart, calendar: calendar),
                    "monthTitle": MeterDateFormat.monthName(now: month.monthStart, calendar: calendar),
                    "values": month.values.map { value -> Any in
                        guard let value else { return NSNull() }
                        return NSDecimalNumber(decimal: value.usd).doubleValue
                    },
                    "leadingEmptyDays": month.leadingEmptyDays,
                    "totalText": month.total.formatted(using: presentation),
                    "dayLabels": month.days.map { MeterDateFormat.monthAndDay($0, calendar: calendar) },
                ]
                if let day = month.peakDay, let amount = month.peakAmount {
                    row["peakCaption"] = JNICopy.format(
                        "花得最多：%@，%@",
                        localeTag,
                        MeterDateFormat.monthAndDay(day, calendar: calendar),
                        amount.formatted(using: presentation)
                    )
                }
                return row
            }
    }

    // MARK: - 按类别构成

    private static func categories(
        composition: [CompositionEntry],
        presentation: MoneyPresentation
    ) -> [[String: Any]] {
        CategoryShares.make(
            from: composition.map { entry in
                CategoryShareMember(
                    providerID: entry.providerID,
                    displayName: entry.displayName,
                    colorKey: entry.colorKey,
                    amount: entry.amount
                )
            }
        ).map { share in
            [
                "category": share.category.rawValue,
                "amountText": share.amount.formatted(using: presentation),
                "percent": share.percent,
                "fraction": share.fraction,
                "colorKey": share.colorKey,
                "memberNames": share.memberNames,
            ]
        }
    }

    // MARK: - 预算线

    private static func budget(
        result: MonthToDate,
        layout: DashboardLayout,
        presentation: MoneyPresentation
    ) -> [String: Any]? {
        guard let gauge = BudgetGauge.make(
            spent: result.totalUSD,
            budgetUSD: layout.monthlyBudgetUSD
        ) else { return nil }
        return [
            "spentText": gauge.spent.formatted(using: presentation),
            "budgetText": gauge.budget.formatted(using: presentation),
            "remainingText": gauge.remaining.formatted(using: presentation),
            "overText": gauge.overspend.formatted(using: presentation),
            "fraction": gauge.fraction,
            // 「用了 N%」那个整数在这里定：Kotlin 原来自己 `toInt()` 截断，
            // iOS 是 `rounded()`——同一根条两端能差一个百分点。句子仍归各端拼。
            "usedPercent": Int((gauge.fraction * 100).rounded()),
            "isOver": gauge.isOver,
            "isClose": gauge.isClose,
        ]
    }

    // MARK: - 本月之最

    private static func superlatives(
        composition: [CompositionEntry],
        comparisons: [ComparisonEntry],
        ledger: LedgerView,
        now: Date,
        localeTag: String
    ) -> [[String: Any]] {
        // 「最久没刷」的名单和 iOS 一样按账号来，只是这一端手上没有接入表，
        // 拿的是账本里每个账号最近一次读数的时刻。
        let latest = ledger.latest.sorted { $0.accountID.rawValue.uuidString < $1.accountID.rawValue.uuidString }

        var items: [[String: Any]] = []
        for kind in SuperlativeSelection.order {
            switch kind {
            case .biggestRise:
                guard let index = SuperlativeSelection.biggestRise(
                    changeRatios: comparisons.map(\.changeRatio)
                ), let ratio = comparisons[index].changeRatio else { continue }
                let rise = comparisons[index]
                items.append(row(
                    kind: kind,
                    displayName: rise.displayName,
                    value: signedPercent(ratio, localeTag: localeTag),
                    colorKey: rise.colorKey,
                    accountID: rise.accountID,
                    providerID: rise.providerID
                ))
            case .biggestShare:
                guard let index = SuperlativeSelection.biggestShare(
                    fractions: composition.map(\.fraction)
                ) else { continue }
                let biggest = composition[index]
                items.append(row(
                    kind: kind,
                    displayName: biggest.displayName,
                    value: "\(biggest.percent)%",
                    colorKey: biggest.colorKey,
                    accountID: biggest.accountID,
                    providerID: biggest.providerID
                ))
            case .stalest:
                guard let index = SuperlativeSelection.stalest(
                    lastRefreshedAt: latest.map(\.fetchedAt)
                ) else { continue }
                let stale = latest[index]
                let descriptor = ProviderCatalog.descriptor(id: stale.providerID)
                items.append(row(
                    kind: kind,
                    displayName: descriptor?.displayName ?? stale.providerID.rawValue,
                    // 「N 天前」怎么写是 Kotlin 的事：那一端有 DateUtils，档位和详情页一套。
                    value: "\(max(0, Int(now.timeIntervalSince(stale.fetchedAt) / 86_400)))",
                    colorKey: descriptor?.colorKey ?? stale.providerID.rawValue,
                    accountID: stale.accountID,
                    providerID: stale.providerID
                ))
            }
        }
        return items
    }

    private static func row(
        kind: SuperlativeKind,
        displayName: String,
        value: String,
        colorKey: String,
        accountID: AccountID?,
        providerID: ProviderID?
    ) -> [String: Any] {
        [
            "kind": kind.rawValue,
            "displayName": displayName,
            "value": value,
            "colorKey": colorKey,
            "accountID": accountID?.rawValue.uuidString ?? "",
            "providerID": providerID?.rawValue ?? "",
        ]
    }

    // MARK: - 特别关心

    private static func pinnedServices(
        pinned: [AccountID],
        ledger: LedgerView,
        composition: [CompositionEntry],
        comparisons: [ComparisonEntry],
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation,
        localeTag: String
    ) -> [[String: Any]] {
        guard !pinned.isEmpty else { return [] }
        let latest = ledger.latestByAccount()
        let today = calendar.startOfDay(for: now)
        return pinned.compactMap { accountID in
            guard let state = latest[accountID] else { return nil }
            let descriptor = ProviderCatalog.descriptor(id: state.providerID)
            let entry = composition.first { $0.accountID == accountID }
            let compared = comparisons.first { $0.accountID == accountID }
            let amount = entry?.amount ?? .zero
            var row: [String: Any] = [
                "accountID": accountID.rawValue.uuidString,
                "providerID": state.providerID.rawValue,
                "displayName": descriptor?.displayName ?? state.providerID.rawValue,
                "colorKey": descriptor?.colorKey ?? state.providerID.rawValue,
                "amountText": amount.formatted(using: presentation),
                // 近 30 天一天一格，旧到新。**日额来自折叠后的账本**，
                // 不要自己去扫原始快照——那等于第二次决定"哪条读数算数"。
                "spark": spark(daily: ledger.dailySpend(for: accountID), today: today, calendar: calendar),
            ]
            if let ratio = compared?.changeRatio {
                row["changeText"] = signedPercent(ratio, localeTag: localeTag)
                row["changeIsUp"] = ratio > 0
            }
            return row
        }
    }

    private static func spark(
        daily: [Date: Money],
        today: Date,
        calendar: Calendar,
        days: Int = 30
    ) -> [Double] {
        // 拿不到按日粒度的家返回空数组，行上就不画这条线——**不要拿月额除以天数糊一条**。
        guard !daily.isEmpty else { return [] }
        return (0..<days).reversed().compactMap { back in
            guard let day = calendar.date(byAdding: .day, value: -back, to: today) else { return nil }
            return NSDecimalNumber(decimal: (daily[day] ?? .zero).usd).doubleValue
        }
    }

    // MARK: - 固定订阅

    private static func subscriptionsModule(
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation,
        localeTag: String
    ) -> [String: Any]? {
        // 只列 `now` 那个月还在付的。退掉的不属于这张卡——它回答的是
        // 「我现在每月固定要出多少钱」。口径和 `SubscriptionsModuleBuilder` 一字不差。
        let active = subscriptions.filter { $0.isActive(on: now, calendar: calendar) }
        guard !active.isEmpty else { return nil }
        // 年付按 12 摊成每月，合计才和「本月订阅」那一行同一个口径。
        let monthly = active.reduce(Money.zero) { total, item in
            switch item.period {
            case .monthly: total + item.amount
            case .annual: total + item.amount / 12
            }
        }
        let next = active
            .compactMap { item in
                UpcomingChargeCalculator.nextChargeDate(item, now: now, calendar: calendar).map { (item, $0) }
            }
            .min { $0.1 < $1.1 }
        // **不截断。**列不下是版式的事，不是把第 9 笔悄悄丢掉的理由。
        let items = active.sorted { $0.amount.usd > $1.amount.usd }.map { item -> [String: Any] in
            let period = item.period == .monthly
                ? JNICopy.text("每月", localeTag)
                : JNICopy.text("每年", localeTag)
            var row: [String: Any] = [
                "id": "\(item.name)|\(item.anchorDate.timeIntervalSince1970)|\(item.providerID?.rawValue ?? "")",
                "name": item.name,
                "amountText": item.amount.formatted(using: presentation),
                "periodCaption": period,
                "accountID": item.accountID?.rawValue.uuidString ?? "",
                "providerID": item.providerID?.rawValue ?? "",
                "quantity": item.quantity,
            ]
            if let colorKey = item.providerID.flatMap({ ProviderIdentity.known($0)?.colorKey }) {
                row["colorKey"] = colorKey
            }
            return row
        }
        var object: [String: Any] = [
            "monthlyTotalText": monthly.formatted(using: presentation),
            "countCaption": JNICopy.format("%lld 笔，折算每月。年付按 12 摊。", localeTag, "\(active.count)"),
            "items": items,
        ]
        if let (item, date) = next {
            object["nextChargeCaption"] = JNICopy.format(
                "下一笔：%@，%@",
                localeTag,
                item.name,
                MeterDateFormat.monthAndDay(date, calendar: calendar)
            )
        }
        return object
    }

    private static func signedPercent(_ ratio: Double, localeTag: String) -> String {
        ProductDashboard.signedPercent(ratio, localeTag: localeTag)
    }
}

/// 构成里的一份钱。JSON 之外还留着 `Money`，因为按类别那张图要拿它继续做加法——
/// 拿格式化过的字符串再解析回数字是另一种漂移。
struct CompositionEntry {
    var accountID: AccountID
    var providerID: ProviderID
    var displayName: String
    var colorKey: String
    var amount: Money
    var percent: Int
    var fraction: Double
}

/// 和上月同期比，一个账号一条。`changeRatio` 为 nil 是这家还不能比。
struct ComparisonEntry {
    var accountID: AccountID?
    var providerID: ProviderID?
    var displayName: String
    var colorKey: String
    var changeRatio: Double?
}
