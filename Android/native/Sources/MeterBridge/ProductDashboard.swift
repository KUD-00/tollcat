import Foundation
import MeterCore
import MeterFormat
import MeterProviders

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
        let presentation = ProductRates.presentation(currency)
        let anchor = filter.anchor(now: now, calendar: calendar)
        let monthTitle = MeterDateFormat.monthName(
            now: anchor,
            calendar: calendar,
            locale: locale(localeTag)
        )
        guard !snapshots.isEmpty || !subscriptions.isEmpty else {
            return emptyJSON(monthTitle: monthTitle, localeTag: localeTag)
        }

        let result = MonthToDateCalculator.compute(
            snapshots: snapshots,
            subscriptions: subscriptions,
            now: now,
            calendar: calendar,
            filter: filter
        )
        let entries = compositionEntries(from: result)
        let composition = compositionRows(entries: entries, presentation: presentation)
        // 「即将扣款」暂时下架，开关和理由在 DashboardModuleThresholds。
        let upcoming = filter.showsPresentTenseModules && DashboardModuleThresholds.showsUpcomingCharges
            ? upcomingRows(
                snapshots: filter.scope(snapshots),
                subscriptions: filter.scope(subscriptions),
                now: now,
                calendar: calendar,
                presentation: presentation,
                localeTag: localeTag
            )
            : []
        let quota = filter.showsPresentTenseModules
            ? quotaRows(from: result, localeTag: localeTag)
            : []
        let runways = filter.showsPresentTenseModules
            ? PrepaidRunwayCalculator.compute(
                snapshots: filter.scope(snapshots),
                now: now,
                calendar: calendar
            )
            : []
        let anomalies = anomalyRows(
            from: result,
            calendar: calendar,
            presentation: presentation,
            localeTag: localeTag
        )
        let balanceAlerts = balanceAlertRows(
            from: runways,
            presentation: presentation,
            localeTag: localeTag
        )
        let trend = trendRows(
            snapshots: filter.scope(snapshots),
            subscriptions: filter.scope(subscriptions),
            now: now,
            calendar: calendar,
            presentation: presentation,
            localeTag: localeTag
        )
        let mood = CatMoodResolver.mood(
            for: result,
            hasAnyProvider: true,
            hasAnyReadableData: CatMoodResolver.hasReadableData(in: result),
            hasBalanceAlert: CatMoodResolver.hasBalanceAlert(in: runways),
            hasAnomaly: CatMoodResolver.hasAnomaly(in: result),
            hasStaleData: result.facts.contains { $0.type == .fetchFailed }
        )

        // 估算名单保持账号粒度：压成 ProviderID 会把「这家的其中一份是估的」
        // 说成「这家全是估的」。
        let estimatedIDs: [String] = result.estimatedAccounts.map(\.rawValue.uuidString)

        let changePercent = result.changeRatio.map { Int(($0 * 100).rounded()) }
        let speech = ProductSpeech.line(
            ProductSpeech.Facts(
                mood: mood,
                hasAnyProvider: true,
                // 从量口径：和首屏主角（formattedVariable）同一笔钱，iOS 同。
                totalText: result.variableUSD.formatted(using: presentation),
                projectedText: result.projectedVariableUSD.formatted(using: presentation),
                allowsProjection: filter.allowsProjection,
                changePercent: changePercent,
                leadAnomalyName: anomalies.first?["displayName"] as? String,
                leadAnomalyPercent: (anomalies.first?["changeRatio"] as? Double)
                    .map { Int(($0 * 100).rounded()) },
                leadBalanceName: balanceAlerts.first?["displayName"] as? String
            ),
            localeTag: localeTag
        )

        var object: [String: Any] = [
            "empty": false,
            "jniSchema": JNISchema.version,
            "monthTitle": monthTitle,
            "periodCaption": periodCaption(
                filter: filter,
                now: now,
                calendar: calendar,
                localeTag: localeTag,
                monthTitle: monthTitle
            ),
            "allowsProjection": filter.allowsProjection,
            "formattedTotal": result.formattedTotal(using: presentation),
            "formattedVariable": result.variableUSD.formatted(using: presentation),
            "formattedProjected": result.projectedVariableUSD.formatted(using: presentation),
            "confidence": result.confidence.rawValue,
            "estimatedAccountIDs": estimatedIDs,
            "composition": composition,
            "upcoming": upcoming,
            "freeQuota": quota,
            "anomalies": anomalies,
            "balanceAlerts": balanceAlerts,
            "trend": trend,
            "catMood": mood.rawValue,
            "currencyCode": presentation.currencyCode,
        ]
        if !presentation.isUSD {
            object["currencyNote"] = JNICopy.format("按 %@ 显示", localeTag, presentation.currencyCode)
        }
        if result.subscriptionUSD > .zero {
            let formatted = result.subscriptionUSD.formatted(using: presentation)
            object["subscriptionFormatted"] = formatted
            object["subscriptionCaption"] = JNICopy.format(
                filter.includesSubscriptions ? "本月订阅 %@ · 已计入" : "本月订阅 %@ · 未计入",
                localeTag,
                formatted
            )
        }
        ProductDashboardModules.attach(
            to: &object,
            // 折叠只做一次，热力图 / 特别关心 / 最久没刷共用同一份读模型。
            ledger: ledger(snapshots: filter.scope(snapshots), now: now, calendar: calendar),
            subscriptions: subscriptions,
            result: result,
            composition: entries,
            comparisons: comparisonEntries(from: result),
            filter: filter,
            layout: layout,
            now: now,
            calendar: calendar,
            presentation: presentation,
            localeTag: localeTag
        )
        object["catSpeech"] = speech
        if let comparison = VariableComparison.make(from: result) {
            let formatted = comparison.previous.formatted(using: presentation)
            object["formattedComparison"] = formatted
            if let window = result.comparisonWindow {
                let monthName = monthSymbol(
                    window.month(calendar: calendar),
                    calendar: calendar,
                    localeTag: localeTag
                )
                var caption = JNICopy.format(
                    "对比 %@同期 %@", localeTag, monthName, formatted
                )
                if comparison.skippedCount > 0 {
                    caption = [
                        caption,
                        JNICopy.format(
                            "含还不能对比 %@",
                            localeTag,
                            comparison.skippedCurrent.formatted(using: presentation)
                        ),
                    ].joined(separator: " · ")
                }
                object["comparisonCaption"] = caption
            }
            if let ratio = comparison.ratio {
                object["comparisonPercentText"] = signedPercent(ratio, localeTag: localeTag)
                object["comparisonTone"] = ratio > 0 ? "up" : (ratio < 0 ? "down" : "flat")
            } else {
                object["comparisonPercentText"] = JNICopy.text("持平", localeTag)
                object["comparisonTone"] = "flat"
            }
        }
        if let ratio = result.changeRatio {
            object["changePercent"] = Int((ratio * 100).rounded())
        }
        object["comparisonItems"] = comparisonItemRows(
            from: result,
            calendar: calendar,
            presentation: presentation,
            localeTag: localeTag
        )
        if result.facts.contains(where: { $0.type == .fetchFailed }) {
            object["staleCaption"] = JNICopy.text("部分数据陈旧，仍显示上次成功的数字", localeTag)
        }
        return JNIJSON.stringify(object)
    }

    /// 按 AccountID 出键（与 iOS `CompositionBuilder` 同粒）：
    /// 同一家两份账号是两段，压成 ProviderID 会并成一家。
    /// 构成的**值**。写字的那一半在 `compositionRows`；按类别那张图要的是这一半，
    /// 拿格式化过的字符串再解析回数字是另一种漂移。
    private static func compositionEntries(from monthToDate: MonthToDate) -> [CompositionEntry] {
        var amounts: [AccountID: Money] = [:]
        var providers: [AccountID: ProviderID] = [:]
        var seen: [AccountID] = []
        for fact in monthToDate.facts {
            guard fact.type.contributesToTotal,
                  let accountID = fact.accountID,
                  let providerID = fact.providerID,
                  let amount = fact.amountUSD,
                  amount > .zero else { continue }
            if amounts[accountID] == nil {
                seen.append(accountID)
                providers[accountID] = providerID
            }
            amounts[accountID, default: .zero] += amount
        }
        let ordered = seen.sorted { lhs, rhs in
            let left = amounts[lhs] ?? .zero
            let right = amounts[rhs] ?? .zero
            if left != right { return left > right }
            return lhs.rawValue.uuidString < rhs.rawValue.uuidString
        }
        let weights = ordered.map { amounts[$0]?.usd ?? 0 }
        let percents = IntegerPercents.from(weights: weights)
        let total = weights.reduce(0, +)
        guard total > 0 else { return [] }
        return zip(ordered, percents).compactMap { id, percent in
            guard let amount = amounts[id], let providerID = providers[id] else { return nil }
            let descriptor = ProviderCatalog.descriptor(id: providerID)
            return CompositionEntry(
                accountID: id,
                providerID: providerID,
                displayName: descriptor?.displayName ?? providerID.rawValue,
                colorKey: descriptor?.colorKey ?? providerID.rawValue,
                amount: amount,
                percent: percent,
                fraction: NSDecimalNumber(decimal: amount.usd / total).doubleValue
            )
        }
    }

    private static func compositionRows(
        entries: [CompositionEntry],
        presentation: MoneyPresentation
    ) -> [[String: Any]] {
        entries.map { entry in
            [
                "accountID": entry.accountID.rawValue.uuidString,
                "providerID": entry.providerID.rawValue,
                "displayName": entry.displayName,
                "colorKey": entry.colorKey,
                "amount": entry.amount.formatted(using: presentation),
                "percent": entry.percent,
                "fraction": entry.fraction,
            ]
        }
    }

    /// 对比详情按家行。金额和涨跌都来自 fact，不在 Kotlin 里再折一遍。
    private static func comparisonItemRows(
        from monthToDate: MonthToDate,
        calendar: Calendar,
        presentation: MoneyPresentation,
        localeTag: String
    ) -> [[String: Any]] {
        monthToDate.facts.compactMap { fact -> [String: Any]? in
            guard fact.type.contributesToTotal, let amount = fact.amountUSD, amount > .zero else {
                return nil
            }
            let providerID = fact.providerID
            let descriptor = providerID.flatMap { ProviderCatalog.descriptor(id: $0) }
            var row: [String: Any] = [
                "accountID": fact.accountID?.rawValue.uuidString ?? "",
                "providerID": providerID?.rawValue ?? "",
                "displayName": descriptor?.displayName ?? providerID?.rawValue ?? "",
                "colorKey": descriptor?.colorKey ?? providerID?.rawValue ?? "",
                "currentText": amount.formatted(using: presentation),
                "isComparable": fact.comparisonUSD != nil,
            ]
            if let previous = fact.comparisonUSD {
                row["previousText"] = previous.formatted(using: presentation)
            }
            if let ratio = fact.changeRatio {
                row["signedPercent"] = signedPercent(ratio, localeTag: localeTag)
                row["changeRatio"] = ratio
            }
            return row
        }
    }

    /// 每个账号和上月同期的涨跌。**没有阈值**——「涨得最多」要在全部里挑，
    /// 而不是先按异常阈值筛一遍再挑（那是 `anomalyRows` 的事）。
    private static func comparisonEntries(from monthToDate: MonthToDate) -> [ComparisonEntry] {
        monthToDate.facts.compactMap { fact in
            guard fact.type.contributesToTotal, let providerID = fact.providerID else { return nil }
            let descriptor = ProviderCatalog.descriptor(id: providerID)
            return ComparisonEntry(
                accountID: fact.accountID,
                providerID: providerID,
                displayName: descriptor?.displayName ?? providerID.rawValue,
                colorKey: descriptor?.colorKey ?? providerID.rawValue,
                changeRatio: fact.changeRatio
            )
        }
    }

    /// 这一端手上是整条快照日志（Kotlin 从 SQLite 递过来的），折成读模型只做一次。
    /// 「哪条读数算数」仍然只有 `LedgerFolder` 一个出处。
    private static func ledger(
        snapshots: [Snapshot],
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
            latest: Array(AccountLatest.reduceAll(snapshots: snapshots, calendar: calendar).values)
        )
    }

    private static func upcomingRows(
        snapshots: [Snapshot],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation,
        localeTag: String
    ) -> [[String: Any]] {
        let charges = UpcomingChargeCalculator.charges(
            snapshots: snapshots,
            subscriptions: subscriptions,
            now: now,
            calendar: calendar,
            withinDays: DashboardModuleThresholds.upcomingChargeDays
        )
        return charges.map { charge in
            let descriptor = charge.providerID.flatMap { ProviderCatalog.descriptor(id: $0) }
            let name: String
            if !charge.name.isEmpty {
                name = charge.name
            } else {
                name = descriptor?.displayName ?? charge.providerID?.rawValue ?? JNICopy.text("固定订阅", localeTag)
            }
            return [
                "name": name,
                "accountID": charge.accountID?.rawValue.uuidString ?? "",
                "providerID": charge.providerID?.rawValue ?? "",
                "colorKey": descriptor?.colorKey ?? charge.providerID?.rawValue ?? "",
                "amount": charge.amount.formatted(using: presentation),
                "dateCaption": dateCaption(charge.chargeDate, now: now, calendar: calendar, localeTag: localeTag),
            ] as [String: Any]
        }
    }

    private static func quotaRows(from monthToDate: MonthToDate, localeTag: String) -> [[String: Any]] {
        monthToDate.facts.compactMap { fact -> [String: Any]? in
            guard
                fact.type == .freeQuota,
                let providerID = fact.providerID,
                let ratio = fact.freeQuotaUsedRatio,
                ratio >= DashboardModuleThresholds.freeQuotaUsedRatio
            else {
                return nil
            }
            let descriptor = ProviderCatalog.descriptor(id: providerID)
            let percent = Int((ratio * 100).rounded())
            return [
                "accountID": fact.accountID?.rawValue.uuidString ?? "",
                "providerID": providerID.rawValue,
                "displayName": descriptor?.displayName ?? providerID.rawValue,
                "colorKey": descriptor?.colorKey ?? providerID.rawValue,
                "usedPercent": percent,
                "caption": JNICopy.format("用了 %lld%%", localeTag, String(percent)),
            ]
        }
        .sorted { lhs, rhs in
            let left = lhs["usedPercent"] as? Int ?? 0
            let right = rhs["usedPercent"] as? Int ?? 0
            return left > right
        }
    }

    /// 单家环比阈值和 `CatMoodResolver.shockedChangeRatio` 同一条线，不另写 0.5。
    private static func anomalyRows(
        from monthToDate: MonthToDate,
        calendar: Calendar,
        presentation: MoneyPresentation,
        localeTag: String
    ) -> [[String: Any]] {
        guard let window = monthToDate.comparisonWindow else { return [] }
        let monthName = monthSymbol(window.month(calendar: calendar), calendar: calendar, localeTag: localeTag)
        let items: [(ratio: Double, name: String, row: [String: Any])] = monthToDate.facts.compactMap { fact in
            guard
                fact.type.contributesToTotal,
                let providerID = fact.providerID,
                let ratio = fact.changeRatio,
                ratio >= CatMoodResolver.shockedChangeRatio,
                let comparison = fact.comparisonUSD
            else {
                return nil
            }
            let descriptor = ProviderCatalog.descriptor(id: providerID)
            let displayName = descriptor?.displayName ?? providerID.rawValue
            return (
                ratio,
                displayName,
                [
                    "accountID": fact.accountID?.rawValue.uuidString ?? "",
                    "providerID": providerID.rawValue,
                    "displayName": displayName,
                    "signedPercent": signedPercent(ratio, localeTag: localeTag),
                    "caption": JNICopy.format("对比 %@同期 %@", localeTag, monthName, comparison.formatted(using: presentation)),
                    "changeRatio": ratio,
                ]
            )
        }
        return items
            .sorted { lhs, rhs in
                if lhs.ratio != rhs.ratio { return lhs.ratio > rhs.ratio }
                return lhs.name < rhs.name
            }
            .map(\.row)
    }

    private static func balanceAlertRows(
        from runways: [PrepaidRunway],
        presentation: MoneyPresentation,
        localeTag: String
    ) -> [[String: Any]] {
        let items: [(days: Int, name: String, row: [String: Any])] = runways.compactMap { runway in
            guard runway.daysRemaining <= CatMoodResolver.prepaidAlertDays else { return nil }
            let descriptor = ProviderCatalog.descriptor(id: runway.providerID)
            let displayName = descriptor?.displayName ?? runway.providerID.rawValue
            let balance = runway.balanceUSD.formatted(using: presentation)
            return (
                runway.daysRemaining,
                displayName,
                [
                    "accountID": runway.accountID.rawValue.uuidString,
                    "providerID": runway.providerID.rawValue,
                    "displayName": displayName,
                    "balance": balance,
                    "daysRemaining": runway.daysRemaining,
                    "caption": JNICopy.format("%@ 余额 %@ · 按当前速度还能用 %lld 天", localeTag, displayName, balance, String(runway.daysRemaining)),
                ]
            )
        }
        return items
            .sorted { lhs, rhs in
                if lhs.days != rhs.days { return lhs.days < rhs.days }
                return lhs.name < rhs.name
            }
            .map(\.row)
    }

    private static func trendRows(
        snapshots: [Snapshot],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation,
        localeTag: String
    ) -> [[String: Any]] {
        let history = MonthSpendHistoryCalculator.compute(
            snapshots: snapshots,
            subscriptions: subscriptions,
            now: now,
            calendar: calendar
        )
        let peak = history.map(\.variableUSD).max() ?? .zero
        guard peak > .zero else { return [] }
        return history.map { point in
            let month = calendar.component(.month, from: point.monthStart)
            let fraction = NSDecimalNumber(decimal: point.variableUSD.usd / peak.usd).doubleValue
            return [
                "month": shortMonthSymbol(month, calendar: calendar, localeTag: localeTag),
                "amount": point.variableUSD.formatted(using: presentation),
                "fraction": fraction,
            ]
        }
    }

    private static func periodCaption(
        filter: DashboardFilter,
        now: Date,
        calendar: Calendar,
        localeTag: String,
        monthTitle: String
    ) -> String {
        let locale = locale(localeTag)
        switch filter.period.normalized {
        case .months(_, 1):
            return monthTitle
        case let .months(back, count):
            let newest = filter.period.anchor(now: now, calendar: calendar)
            guard
                let newestStart = calendar.date(from: calendar.dateComponents([.year, .month], from: newest)),
                let oldestStart = calendar.date(byAdding: .month, value: -(count - 1), to: newestStart)
            else {
                return monthTitle
            }
            _ = back
            return MeterDateFormat.monthRange(
                from: oldestStart,
                to: newestStart,
                calendar: calendar,
                locale: locale
            )
        case .yearToDate:
            let year = calendar.component(.year, from: now)
            guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else {
                return monthTitle
            }
            return MeterDateFormat.monthRange(from: start, to: now, calendar: calendar, locale: locale)
        case .allTime:
            return monthTitle
        }
    }

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
                    leadBalanceName: nil
                ),
                localeTag: localeTag
            ),
            "anomalies": [],
            "balanceAlerts": [],
            "trend": [],
            "catMood": CatMood.sleeping.rawValue,
        ])
    }

    static func signedPercent(_ ratio: Double, localeTag: String) -> String {
        let percent = Int((ratio * 100).rounded())
        if percent > 0 { return "+\(percent)%" }
        if percent < 0 { return "\(percent)%" }
        return JNICopy.text("持平", localeTag)
    }

    package static func locale(_ localeTag: String) -> Locale {
        Locale(identifier: localeTag.isEmpty ? "zh-Hans" : localeTag)
    }

    /// 独立式全月名（zh「一月」/ en "January"），跟 locale，不再钉死中文表。
    private static func monthSymbol(_ month: Int, calendar: Calendar, localeTag: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale(localeTag)
        let symbols = formatter.standaloneMonthSymbols ?? []
        guard symbols.indices.contains(month - 1) else { return "\(month)" }
        return symbols[month - 1]
    }

    /// 短月名（zh「8月」/ en "Aug"），给趋势条的横轴。
    private static func shortMonthSymbol(_ month: Int, calendar: Calendar, localeTag: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale(localeTag)
        let symbols = formatter.shortStandaloneMonthSymbols ?? []
        guard symbols.indices.contains(month - 1) else { return "\(month)" }
        return symbols[month - 1]
    }

    private static func dateCaption(_ date: Date, now: Date, calendar: Calendar, localeTag: String) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return JNICopy.text("今天", localeTag)
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return JNICopy.text("明天", localeTag)
        }
        return MeterDateFormat.monthAndDay(date, calendar: calendar, locale: locale(localeTag))
    }
}
