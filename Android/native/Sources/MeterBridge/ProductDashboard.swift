import Foundation
import MeterCore
import MeterDashboard
import MeterFormat

/// 仪表盘那一屏的 JSON。
///
/// **这里不折算。** 各模块怎么从账本算出来，全在 `MeterDashboard` 的
/// `DashboardContentsBuilder`——iOS、Mac、widget 调的是同一个函数。这一层只做三件事：
/// 把 Kotlin 递来的快照日志折成读模型、钉住语言、把算好的值写成字典。
///
/// 以前这里抄了一份 builder（MeterDashboard 那时还和 SwiftUI 视图住在一个 target 里，
/// Android 链不到），抄的那份悄悄漂走：固定订阅只按月付算，年付的 ChatGPT Plus
/// 在卡上变成了 $1.67 却看不出是年付。别再在这里写规则——缺什么，加到 builder 的值类型上。
package enum ProductDashboard {
    package static func json(
        snapshotsJSON: String,
        subscriptionsJSON: String,
        nowMillis: Int64,
        currency: String,
        localeTag: String,
        filterJSON: String
    ) -> String {
        let calendar = ProductClock.calendar()
        let now = ProductClock.date(millis: nowMillis)
        let snapshots = JNIJSON.array(snapshotsJSON).compactMap(ProductSnapshotCodec.snapshot(from:))
        let subscriptions = JNIJSON.array(subscriptionsJSON).compactMap {
            ProductSnapshotCodec.subscription(from: $0, calendar: calendar)
        }
        return json(
            snapshots: snapshots,
            subscriptions: subscriptions,
            now: now,
            calendar: calendar,
            currency: currency,
            localeTag: localeTag,
            filter: filter(from: filterJSON),
            layout: layout(from: filterJSON)
        )
    }

    package static func layout(from json: String) -> DashboardLayout {
        let object = JNIJSON.object(json)
        let pinned = (object["pinnedAccounts"] as? [String] ?? [])
            .compactMap(UUID.init(uuidString:))
            .map(AccountID.init(rawValue:))
        let budget = (object["monthlyBudgetUSD"] as? String)
            .flatMap { Decimal(string: $0, locale: Locale(identifier: "en_US_POSIX")) }
        return DashboardLayout(
            pinnedAccounts: pinned,
            monthlyBudgetUSD: budget
        )
    }

    /// 和 iOS 同一个取景框模型：按账号排除、整月区间、订阅开关。
    ///
    /// `periodKind` / `monthCount` 缺省时退化成单月，也就是加多月区间之前的行为——
    /// 旧版 Kotlin 送上来的 JSON 不带这两个字段，不能因此算出别的月份。
    package static func filter(from json: String) -> DashboardFilter {
        let object = JNIJSON.object(json)
        let excluded = (object["excludedAccounts"] as? [String] ?? [])
            .compactMap(UUID.init(uuidString:))
            .map(AccountID.init(rawValue:))
        return DashboardFilter(
            period: DashboardPeriod.fromStorage(
                kind: object["periodKind"] as? String ?? "months",
                monthsBack: object["monthsBack"] as? Int ?? 0,
                monthCount: object["monthCount"] as? Int ?? 1
            ),
            includesSubscriptions: object["includesSubscriptions"] as? Bool ?? true,
            excludedAccounts: Set(excluded)
        )
    }

    package static func json(
        snapshots: [Snapshot],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        currency: String,
        localeTag: String,
        filter: DashboardFilter = .unfiltered,
        layout: DashboardLayout = .default
    ) -> String {
        // builder 里的 `L(…)` 和 `MeterDateFormat` 在这个作用域里按 localeTag 出字；
        // Android 上没有 String Catalog，也没有可靠的 `Locale.current`。
        PortableLocale.$languageTag.withValue(localeTag.isEmpty ? "zh-Hans" : localeTag) {
            render(
                snapshots: snapshots,
                subscriptions: subscriptions,
                now: now,
                calendar: calendar,
                currency: currency,
                localeTag: localeTag,
                filter: filter,
                layout: layout
            )
        }
    }

    private static func render(
        snapshots: [Snapshot],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        currency: String,
        localeTag: String,
        filter: DashboardFilter,
        layout: DashboardLayout
    ) -> String {
        let presentation = ProductRates.presentation(currency)
        let anchor = filter.anchor(now: now, calendar: calendar)
        let monthTitle = MeterDateFormat.monthName(now: anchor, calendar: calendar)
        guard !snapshots.isEmpty || !subscriptions.isEmpty else {
            return emptyJSON(monthTitle: monthTitle, localeTag: localeTag)
        }

        let view = ledger(snapshots: snapshots, subscriptions: subscriptions, now: now, calendar: calendar)
        let connections = connections(in: view)
        // 合计只走账本这一条路（widget 同款）。先算一遍拿「哪几家没刷上来」，
        // builder 里再调同一个闭包——纯函数，两次结果一样。
        let compute: MonthToDateCompute = { view, now, calendar, filter in
            LedgerProjection.compute(
                rollups: view.rollups,
                subscriptions: view.subscriptions,
                now: now,
                calendar: calendar,
                filter: filter
            )
        }
        let marks = providerMarks(in: compute(view, now, calendar, filter))
        let (contents, runways) = DashboardContentsBuilder.make(
            view: view,
            filter: filter,
            now: now,
            calendar: calendar,
            presentation: presentation,
            connections: connections,
            providerMarks: marks,
            layout: layout,
            compute: compute
        )
        guard let result = contents.monthToDate, let headline = contents.monthToDateContent else {
            return emptyJSON(monthTitle: monthTitle, localeTag: localeTag)
        }

        let mood = CatMoodResolver.mood(
            for: result,
            hasAnyProvider: true,
            hasAnyReadableData: CatMoodResolver.hasReadableData(in: result),
            hasBalanceAlert: CatMoodResolver.hasBalanceAlert(in: runways),
            hasAnomaly: CatMoodResolver.hasAnomaly(in: result),
            hasStaleData: !marks.isEmpty
        )
        let leadAnomaly = contents.anomalyContent?.items.first
        let changePercent = result.changeRatio.map { Int(($0 * 100).rounded()) }
        let speech = ProductSpeech.line(
            ProductSpeech.Facts(
                mood: mood,
                hasAnyProvider: true,
                // 和首屏主角同一笔钱、同一个口径（iOS `CatSpeechFacts` 同）。
                totalText: headline.amountText,
                projectedText: headline.projectedAmountText ?? "",
                allowsProjection: filter.allowsProjection,
                changePercent: changePercent,
                leadAnomalyName: leadAnomaly?.displayName,
                leadAnomalyPercent: leadAnomaly.map { Int(($0.changeRatio * 100).rounded()) },
                leadBalanceName: contents.balanceAlertContent?.items.first?.displayName,
                includesSubscriptions: filter.includesSubscriptions
            ),
            localeTag: localeTag
        )

        let slices = CompositionSliceBuilder.make(
            from: contents.compositionContent?.segments ?? [],
            presentation: presentation
        )
        var object: [String: Any] = [
            "empty": false,
            "jniSchema": JNISchema.version,
            "monthTitle": monthTitle,
            // 期间标题和 iOS 分享卡 / 筛选条同一个函数：「有数据以来」「近 3 个月」不会被写成当月月名。
            "periodCaption": DashboardFilterSummary.periodHeading(
                period: filter.period,
                window: result.window,
                asOf: anchor,
                calendar: calendar
            ),
            "allowsProjection": filter.allowsProjection,
            // 首屏那一对数直接取 iOS 首屏用的同一份 `MonthToDateModuleContent`，
            // 口径（算没算订阅）已经跟着 filter 算好。各端照着画，不再自己挑字段拼。
            "formattedTotal": headline.amountText,
            "confidence": result.confidence.rawValue,
            // 估算名单保持账号粒度：压成 ProviderID 会把「这家的其中一份是估的」
            // 说成「这家全是估的」。
            "estimatedAccountIDs": result.estimatedAccounts.map(\.rawValue.uuidString),
            "composition": (contents.compositionContent?.segments ?? []).map { composition($0, presentation) },
            // 「前几名 + 其他」合并好的图例段。跟随端直接画，不再自己把金额字符串加起来。
            "compositionSlices": slices.map { compositionSlice($0, presentation) },
            // 冷启动过渡：口袋里每枚圆牌落到哪一段图例（段 id）。落点规则只在 LaunchTokenTargets 写一份。
            "launchTargets": Dictionary(
                uniqueKeysWithValues: LaunchTokenTargets.make(from: slices).map { ($0.key.rawValue, $0.value) }
            ),
            "vendorSpend": vendorSpend(result: result, connections: connections, presentation: presentation),
            "upcoming": (contents.upcomingChargesContent?.items ?? []).map { upcoming($0, presentation) },
            "freeQuota": (contents.freeQuotaContent?.items ?? []).map(freeQuota),
            "anomalies": (contents.anomalyContent?.items ?? []).map(anomaly),
            "balanceAlerts": (contents.balanceAlertContent?.items ?? []).map(balanceAlert),
            "trend": trend(contents.trendContent, calendar: calendar),
            "heatmap": (contents.heatmapContent?.months ?? []).map(heatmap),
            "categories": (contents.categoriesContent?.slices ?? []).map(category),
            "superlatives": (contents.superlativesContent?.items ?? []).map(superlative),
            "pinnedServices": (contents.servicesContent?.items ?? []).map(service),
            "comparisonItems": (contents.comparisonContent?.items ?? []).map(comparisonItem),
            "catMood": mood.rawValue,
            "catSpeech": speech,
            "currencyCode": presentation.currencyCode,
        ]
        // 回看过去的月份没有「月底」：这个键就不出现，不写一个空串让各端再猜。
        object["formattedProjected"] = headline.projectedAmountText
        object["currencyNote"] = headline.currencyNote
        object["staleCaption"] = headline.staleCaption
        object["filterNote"] = headline.filterNote
        // 订阅那行和 iOS 首屏同一条规则：只在算进订阅时出现。多月取景框里它是这几个月的合计，
        // 所以跟随端配的标签只能写「订阅」，不能写「本月订阅」。
        object["subscriptionCaption"] = headline.subscriptionCaption
        object["subscriptionAmountText"] = headline.subscriptionAmountText
        object["showsSubscriptionScope"] = headline.showsSubscriptionScope
        if let comparison = contents.comparisonContent, comparison.tone != .unknown {
            object["formattedComparison"] = comparison.previousText
            object["formattedComparisonCurrent"] = comparison.currentText
            // 两根柱按这两个数画（已按显示币种），不要拿取整后的百分比倒推。
            object["comparisonCurrentValue"] = comparison.current
            object["comparisonPreviousValue"] = comparison.previous
            object["comparisonCaption"] = comparison.caption
            object["comparisonPercentText"] = comparison.percentText
            object["comparisonTone"] = tone(comparison.tone)
        }
        if let changePercent {
            object["changePercent"] = changePercent
        }
        object["budget"] = contents.budgetContent.map(budget)
        object["subscriptionsModule"] = contents.subscriptionsContent.map(subscriptionsModule)
        return JNIJSON.stringify(object)
    }

    // MARK: - 读模型

    /// 这一端手上是整条快照日志（Kotlin 从 SQLite 递过来的），折成读模型只做一次。
    /// 「哪条读数算数」仍然只有 `LedgerFolder` 一个出处。
    private static func ledger(
        snapshots: [Snapshot],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar
    ) -> LedgerView {
        var rollups: [MonthlyRollup] = []
        for accountID in Set(snapshots.compactMap(\.accountID)) {
            rollups.append(
                contentsOf: LedgerFolder.fold(
                    accountID: accountID,
                    snapshots: snapshots,
                    now: now,
                    calendar: calendar
                )
            )
        }
        return LedgerView(
            rollups: rollups,
            latest: Array(AccountLatest.reduceAll(snapshots: snapshots, calendar: calendar).values),
            subscriptions: subscriptions
        )
    }

    /// builder 要的接入表。这一端没有接入记录（昵称、归档都在 Kotlin 的库里），
    /// 从账本里每个账号最近一次读数拼一份：有读数就算开着，最后成功的时刻就是那条读数。
    private static func connections(in view: LedgerView) -> [ProviderConnectionState] {
        view.latest
            .sorted { $0.accountID.rawValue.uuidString < $1.accountID.rawValue.uuidString }
            .enumerated()
            .map { index, latest in
                ProviderConnectionState(
                    accountID: latest.accountID,
                    providerID: latest.providerID,
                    isEnabled: true,
                    sortIndex: index,
                    lastSuccessfulRefreshAt: latest.fetchedAt,
                    credentialReference: "",
                    includeInGlobalRefresh: true
                )
            }
    }

    /// 没刷上来的那几份：折算里出现了取数失败的 fact。
    private static func providerMarks(in result: MonthToDate) -> [AccountID: ProviderDataMark] {
        var marks: [AccountID: ProviderDataMark] = [:]
        for fact in result.facts where fact.type == .fetchFailed {
            if let accountID = fact.accountID {
                marks[accountID] = .stale
            }
        }
        return marks
    }

    // MARK: - 值 → 字典

    private static func composition(_ segment: CompositionSegment, _ presentation: MoneyPresentation) -> [String: Any] {
        [
            "accountID": segment.accountID?.rawValue.uuidString ?? "",
            "providerID": segment.providerID?.rawValue ?? "",
            "displayName": segment.displayName,
            "colorKey": segment.colorKey,
            "amount": segment.amount.formatted(using: presentation),
            // 排序用的数（已按显示币种）。跟随端别把 `amount` 那串字解析回数字。
            "amountValue": displayValue(segment.amount, presentation),
            "percent": segment.percent,
            "fraction": segment.fraction,
        ]
    }

    private static func displayValue(_ amount: Money, _ presentation: MoneyPresentation) -> Double {
        NSDecimalNumber(decimal: presentation.amount(from: amount)).doubleValue
    }

    private static func compositionSlice(_ slice: CompositionSlice, _ presentation: MoneyPresentation) -> [String: Any] {
        [
            "id": slice.id,
            "accountID": slice.accountID?.rawValue.uuidString ?? "",
            "providerID": slice.providerID?.rawValue ?? "",
            "displayName": slice.displayName,
            "colorKey": slice.colorKey,
            "amount": slice.amountText,
            "amountValue": displayValue(slice.amount, presentation),
            "percent": slice.percent,
            "fraction": slice.fraction,
            "isOther": slice.isOther,
            "mergedNames": slice.mergedNames,
        ]
    }

    /// 服务页每一行、详情页大数字那一家的钱：和 iOS `ServiceRowBuilder` / `ProviderDetailModel`
    /// 同一份 `VendorSpend`。挂在厂商上的无主订阅也算进这家。
    private static func vendorSpend(
        result: MonthToDate,
        connections: [ProviderConnectionState],
        presentation: MoneyPresentation
    ) -> [[String: Any]] {
        let live = Dictionary(grouping: connections.filter(\.isLive), by: \.providerID)
        let providers = Set(live.keys).union(result.facts.compactMap(\.providerID))
        return providers.sorted { $0.rawValue < $1.rawValue }.compactMap { providerID in
            let spend = VendorSpend.make(
                providerID: providerID,
                accounts: Set((live[providerID] ?? []).map(\.accountID)),
                facts: result.facts
            )
            guard spend.contributingCount > 0 else { return nil }
            var row: [String: Any] = [
                "providerID": providerID.rawValue,
                "totalText": spend.total.formatted(using: presentation),
                "totalValue": displayValue(spend.total, presentation),
            ]
            row["compositionCaption"] = spend.compositionCaption(presentation: presentation)
            return row
        }
    }

    private static func upcoming(_ item: UpcomingChargeItem, _ presentation: MoneyPresentation) -> [String: Any] {
        [
            "name": item.displayName,
            "accountID": item.accountID?.rawValue.uuidString ?? "",
            "providerID": item.providerID?.rawValue ?? "",
            "colorKey": item.colorKey ?? item.providerID?.rawValue ?? "",
            "amount": item.amount.formatted(using: presentation),
            "dateCaption": item.dateCaption,
        ]
    }

    private static func freeQuota(_ item: FreeQuotaItem) -> [String: Any] {
        [
            "accountID": item.accountID.rawValue.uuidString,
            "providerID": item.providerID.rawValue,
            "displayName": item.displayName,
            "colorKey": item.colorKey,
            "usedPercent": Int((item.usedRatio * 100).rounded()),
            "caption": item.caption,
        ]
    }

    private static func anomaly(_ item: AnomalyItem) -> [String: Any] {
        [
            "accountID": item.accountID.rawValue.uuidString,
            "providerID": item.providerID.rawValue,
            "displayName": item.displayName,
            "signedPercent": item.signedPercent,
            "caption": item.caption,
            "changeRatio": item.changeRatio,
        ]
    }

    private static func balanceAlert(_ item: BalanceAlertItem) -> [String: Any] {
        [
            "accountID": item.accountID.rawValue.uuidString,
            "providerID": item.providerID.rawValue,
            "displayName": item.displayName,
            "balance": item.balanceUSD.formatted(using: item.presentation),
            "daysRemaining": item.daysRemaining,
            "caption": item.caption,
        ]
    }

    /// 柱高按这组里最高的那根归一，横轴写短月名（zh「8月」/ en "Aug"）。
    private static func trend(_ content: TrendModuleContent?, calendar: Calendar) -> [[String: Any]] {
        guard let bars = content?.bars, let peak = bars.map(\.amount).max(), peak > 0 else { return [] }
        return bars.map { bar in
            [
                "month": shortMonthSymbol(calendar.component(.month, from: bar.date), calendar: calendar),
                "amount": bar.amountText,
                "fraction": bar.amount / peak,
            ]
        }
    }

    private static func heatmap(_ month: HeatmapMonth) -> [String: Any] {
        var row: [String: Any] = [
            "monthStartMillis": Int(ProductClock.millis(month.monthStart)),
            "title": month.title,
            "monthTitle": month.monthTitle,
            "values": month.values.map { value -> Any in value ?? NSNull() },
            "leadingEmptyDays": month.leadingEmptyDays,
            "totalText": month.totalText,
            "dayLabels": month.dayLabels,
        ]
        row["peakCaption"] = month.peakCaption
        return row
    }

    private static func category(_ slice: CategorySlice) -> [String: Any] {
        [
            "category": slice.category.rawValue,
            "amountText": slice.amountText,
            "percent": slice.percent,
            "fraction": slice.fraction,
            "colorKey": slice.colorKey,
            "memberNames": slice.memberNames,
        ]
    }

    private static func budget(_ content: BudgetModuleContent) -> [String: Any] {
        [
            "spentText": content.spentText,
            "budgetText": content.budgetText,
            "remainingText": content.remainingText,
            "overText": content.overText,
            "fraction": content.fraction,
            "usedPercent": content.usedPercent,
            "isOver": content.isOver,
            "isClose": content.isClose,
        ]
    }

    private static func superlative(_ item: SuperlativeItem) -> [String: Any] {
        [
            "kind": item.kind.rawValue,
            "displayName": item.displayName,
            "value": item.value,
            "colorKey": item.colorKey,
            "accountID": item.accountID?.rawValue.uuidString ?? "",
            "providerID": item.providerID?.rawValue ?? "",
        ]
    }

    private static func service(_ item: ServiceCardItem) -> [String: Any] {
        var row: [String: Any] = [
            "accountID": item.accountID.rawValue.uuidString,
            "providerID": item.providerID.rawValue,
            "displayName": item.displayName,
            "colorKey": item.colorKey,
            "amountText": item.amountText,
            "spark": item.spark,
            "changeIsUp": item.changeIsUp,
        ]
        row["changeText"] = item.changeText
        return row
    }

    private static func comparisonItem(_ item: ComparisonItem) -> [String: Any] {
        var row: [String: Any] = [
            "accountID": item.accountID?.rawValue.uuidString ?? "",
            "providerID": item.providerID?.rawValue ?? "",
            "displayName": item.displayName,
            "colorKey": item.colorKey,
            "currentText": item.currentUSD.formatted(using: item.presentation),
            "isComparable": item.isComparable,
        ]
        row["previousText"] = item.previousUSD?.formatted(using: item.presentation)
        if let ratio = item.changeRatio {
            row["signedPercent"] = item.trailingText
            row["changeRatio"] = ratio
        }
        return row
    }

    private static func subscriptionsModule(_ content: SubscriptionsModuleContent) -> [String: Any] {
        var object: [String: Any] = [
            "monthlyTotalText": content.monthlyTotalText,
            "headlineCaption": content.headlineCaption,
            "countCaption": content.countCaption,
            "items": content.items.map { item -> [String: Any] in
                var row: [String: Any] = [
                    "id": item.id,
                    "name": item.name,
                    "amountText": item.amountText,
                    "periodCaption": item.periodCaption,
                    "accountID": item.accountID?.rawValue.uuidString ?? "",
                    "providerID": item.providerID?.rawValue ?? "",
                    "quantity": item.quantity,
                ]
                row["colorKey"] = item.colorKey
                return row
            },
        ]
        object["nextChargeCaption"] = content.nextChargeCaption
        return object
    }

    private static func tone(_ tone: ComparisonModuleContent.Tone) -> String {
        switch tone {
        case .up: "up"
        case .down: "down"
        case .flat: "flat"
        case .unknown: "unknown"
        }
    }

    // MARK: - 只有这一端要的字

    private static func emptyJSON(monthTitle: String, localeTag: String) -> String {
        JNIJSON.stringify([
            "empty": true,
            "jniSchema": JNISchema.version,
            "monthTitle": monthTitle,
            "catSpeech": ProductSpeech.line(
                ProductSpeech.Facts(
                    mood: .sleeping,
                    hasAnyProvider: false,
                    totalText: "",
                    projectedText: "",
                    allowsProjection: true,
                    changePercent: nil,
                    leadAnomalyName: nil,
                    leadAnomalyPercent: nil,
                    leadBalanceName: nil,
                    includesSubscriptions: true
                ),
                localeTag: localeTag
            ),
            "anomalies": [],
            "balanceAlerts": [],
            "trend": [],
            "catMood": CatMood.sleeping.rawValue,
        ])
    }

    package static func locale(_ localeTag: String) -> Locale {
        Locale(identifier: localeTag.isEmpty ? "zh-Hans" : localeTag)
    }

    /// 短月名，跟着 `PortableLocale` 钉住的语言。
    private static func shortMonthSymbol(_ month: Int, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = PortableLocale.formatting
        let symbols = formatter.shortStandaloneMonthSymbols ?? []
        guard symbols.indices.contains(month - 1) else { return "\(month)" }
        return symbols[month - 1]
    }
}
