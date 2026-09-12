import Foundation
import MeterCore
import MeterFormat
import MeterProviders
import MeterModules

enum ServiceRowBuilder {
    static func rows(
        memberships: [ProviderMembership],
        connections: [ProviderConnectionState],
        /// 每账号此刻的状态。**不是快照日志**——「哪条读数算数」在折叠时判过了。
        latest: [AccountID: AccountLatest],
        monthToDate: MonthToDate?,
        marks: [AccountID: ProviderDataMark],
        subscriptions: [MonthlySubscription],
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation = .usd
    ) -> [ServiceRowItem] {
        let enabled = connections.filter(\.isLive)
        let byProvider = Dictionary(grouping: enabled, by: \.providerID)
        let archivedByProvider = Dictionary(
            grouping: connections.filter(\.isArchived),
            by: \.providerID
        )
        let ordered = memberships.sorted { $0.sortIndex < $1.sortIndex }

        return ordered.compactMap { membership in
            guard let descriptor = ProviderCatalog.descriptor(id: membership.providerID) else {
                return nil
            }
            let accounts = byProvider[membership.providerID] ?? []
            let accountIDs = Set(accounts.map(\.accountID))
            let vendorFacts = factsForVendor(
                membership.providerID,
                accounts: accountIDs,
                monthToDate: monthToDate
            )
            let allVendorSubscriptions = subscriptions.filter { $0.providerID == membership.providerID }
            // 退掉的订阅不参与这一行的任何一个数：它既不在本月合计里，
            // 也不该让副标题继续写着「ChatGPT Plus」。
            let vendorSubscriptions = allVendorSubscriptions.filter {
                !$0.hasEnded(by: now, calendar: calendar)
            }
            let archivedAccounts = archivedByProvider[membership.providerID] ?? []
            if accounts.isEmpty, vendorSubscriptions.isEmpty {
                let endedSubscriptions = allVendorSubscriptions.filter {
                    $0.hasEnded(by: now, calendar: calendar)
                }
                if !archivedAccounts.isEmpty || !endedSubscriptions.isEmpty {
                    return endedRow(
                        membership.providerID,
                        descriptor: descriptor,
                        endedAt: endedDate(
                            accounts: archivedAccounts,
                            subscriptions: endedSubscriptions
                        ),
                        calendar: calendar
                    )
                }
            }
            let snapshot: AccountLatest?
            let lastSuccess: Date?
            let usesInbox: Bool
            let mark: ProviderDataMark?
            if accounts.count == 1, let account = accounts.first {
                snapshot = latest[account.accountID]
                lastSuccess = latestSuccess(
                    stamped: account.lastSuccessfulRefreshAt,
                    snapshot: snapshot
                )
                usesInbox = account.usesInbox
                mark = marks[account.accountID]
            } else {
                snapshot = accounts
                    .compactMap { latest[$0.accountID] }
                    .max(by: { $0.fetchedAt < $1.fetchedAt })
                lastSuccess = latestSuccess(
                    stamped: accounts.compactMap(\.lastSuccessfulRefreshAt).max(),
                    snapshot: snapshot
                )
                usesInbox = accounts.contains(where: \.usesInbox)
                mark = accounts.compactMap { marks[$0.accountID] }.max { lhs, rhs in
                    rank(lhs) < rank(rhs)
                }
            }
            let fact = preferredFact(vendorFacts)
            let reportsCommitted = snapshot?.committedMonthlyUSD != nil
            let superseded = vendorSubscriptions.contains { subscription in
                guard let id = subscription.accountID else { return false }
                return accountIDs.contains(id)
            } && reportsCommitted

            return makeRow(
                providerID: membership.providerID,
                nickname: nil,
                displayName: descriptor.displayName,
                spokenName: descriptor.displayName,
                descriptor: descriptor,
                isConnected: true,
                mark: mark,
                snapshot: snapshot,
                fact: fact,
                facts: vendorFacts,
                lastSuccess: lastSuccess,
                supersededByManual: superseded,
                usesInbox: usesInbox,
                usageCount: accounts.count,
                subscriptionNames: vendorSubscriptions.map(\.name),
                now: now,
                calendar: calendar,
                presentation: presentation
            )
        }
    }

    /// 已经结束的那一行。**不摆金额**——这家这个月不花钱，写个 $0 会让人以为
    /// 它还在跑；写最后一次的读数更糟，那是过去的钱。
    private static func endedRow(
        _ providerID: ProviderID,
        descriptor: ProviderDescriptor,
        endedAt: Date?,
        calendar: Calendar
    ) -> ServiceRowItem {
        let caption = endedAt.map {
            String(localized: L("已结束 · \(MeterDateFormat.yearMonth($0, calendar: calendar))"))
        } ?? String(localized: L("已结束"))
        return ServiceRowItem(
            id: providerID,
            kind: descriptor.kind,
            category: descriptor.category,
            nickname: nil,
            displayName: descriptor.displayName,
            spokenName: descriptor.displayName,
            colorKey: descriptor.colorKey,
            value: "—",
            spokenValue: caption,
            subtitle: caption,
            usesSecondaryValue: true,
            isConnected: true,
            isStale: false,
            valueCaption: nil,
            amountValue: 0,
            supersededByManual: false,
            isEnded: true
        )
    }

    private static func endedDate(
        accounts: [ProviderConnectionState],
        subscriptions: [MonthlySubscription]
    ) -> Date? {
        (accounts.compactMap(\.archivedAt) + subscriptions.compactMap(\.endDate)).max()
    }

    private static func rank(_ mark: ProviderDataMark) -> Int {
        switch mark {
        case .failed: 2
        case .stale: 1
        default: 0
        }
    }

    private static func factsForVendor(
        _ providerID: ProviderID,
        accounts: Set<AccountID>,
        monthToDate: MonthToDate?
    ) -> [Fact] {
        (monthToDate?.facts ?? []).filter { fact in
            guard fact.providerID == providerID else { return false }
            if let id = fact.accountID {
                return accounts.contains(id)
            }
            return true
        }
    }

    private static func makeRow(
        providerID: ProviderID,
        nickname: String?,
        displayName: String,
        spokenName: String,
        descriptor: ProviderDescriptor,
        isConnected: Bool,
        mark: ProviderDataMark?,
        snapshot: AccountLatest?,
        fact: Fact?,
        facts: [Fact],
        lastSuccess: Date?,
        supersededByManual: Bool,
        usesInbox: Bool,
        usageCount: Int,
        subscriptionNames: [String],
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation
    ) -> ServiceRowItem {
        if !isConnected {
            return ServiceRowItem(
                id: providerID,
                kind: descriptor.kind,
                category: descriptor.category,
                nickname: nickname,
                displayName: displayName,
                spokenName: spokenName,
                colorKey: descriptor.colorKey,
                value: String(localized: L("未接入")),
                spokenValue: String(localized: L("未接入")),
                subtitle: nil,
                usesSecondaryValue: true,
                isConnected: false,
                isStale: false,
                valueCaption: nil,
                amountValue: 0,
                supersededByManual: false
            )
        }

        let isStale = mark == .stale || mark == .failed
        let kind = snapshot?.kind ?? descriptor.kind

        if kind == .freeTier, let ratio = snapshot?.freeQuotaUsedRatio ?? fact?.freeQuotaUsedRatio {
            let percent = Int((ratio * 100).rounded())
            let paid = paidHint(descriptor, isStale: isStale)
            return ServiceRowItem(
                id: providerID,
                kind: kind,
                category: descriptor.category,
                nickname: nickname,
                displayName: displayName,
                spokenName: spokenName,
                colorKey: descriptor.colorKey,
                value: String(localized: L("免费额度")),
                spokenValue: String(localized: L("免费额度，用了百分之 \(percent)")),
                subtitle: mergedSubtitle(
                    mergedSubtitle(
                        String(localized: L("用了 \(percent)%")),
                        paidHint: subscriptionBreakdown(facts, presentation: presentation)
                    ),
                    paidHint: paid.mergedIntoSubtitle
                ),
                usesSecondaryValue: true,
                isConnected: true,
                isStale: isStale,
                valueCaption: paid.caption,
                amountValue: ratio,
                supersededByManual: supersededByManual
            )
        }

        let amount = displayAmount(
            fact: fact,
            snapshot: snapshot,
            facts: facts,
            now: now,
            calendar: calendar
        )
        let hasAmount = amount != nil
        let value: String
        let spoken: String
        let amountValue: Double
        if let amount {
            value = amount.formatted(using: presentation)
            spoken = SpokenMoney.label(for: amount, presentation: presentation)
            amountValue = NSDecimalNumber(decimal: presentation.amount(from: amount)).doubleValue
        } else if usageCount == 0, let name = subscriptionNames.first {
            value = "—"
            spoken = name
            amountValue = 0
        } else {
            value = "—"
            if usesInbox, lastSuccess == nil {
                spoken = String(localized: L("等待第一次投递"))
            } else if usageCount == 0 {
                spoken = String(localized: L("还没有用量"))
            } else {
                spoken = isStale
                    ? String(localized: L("数据陈旧，暂无读数"))
                    : String(localized: L("暂无读数"))
            }
            amountValue = 0
        }

        let paid = paidHint(descriptor, isStale: isStale)
        let baseSubtitle = vendorSubtitle(
            descriptor: descriptor,
            kind: kind,
            snapshot: snapshot,
            lastSuccess: lastSuccess,
            isStale: isStale,
            hasAmount: hasAmount,
            supersededByManual: supersededByManual,
            usesInbox: usesInbox,
            usageCount: usageCount,
            subscriptionNames: subscriptionNames,
            now: now,
            calendar: calendar,
            presentation: presentation
        )
        return ServiceRowItem(
            id: providerID,
            kind: kind,
            category: descriptor.category,
            nickname: nickname,
            displayName: displayName,
            spokenName: spokenName,
            colorKey: descriptor.colorKey,
            value: value,
            spokenValue: spoken,
            subtitle: mergedSubtitle(
                mergedSubtitle(
                    baseSubtitle.text,
                    paidHint: subscriptionBreakdown(
                        facts,
                        disclosed: baseSubtitle.disclosedSubscription,
                        presentation: presentation
                    )
                ),
                paidHint: paid.mergedIntoSubtitle
            ),
            usesSecondaryValue: !hasAmount,
            isConnected: true,
            isStale: isStale,
            valueCaption: paid.caption,
            amountValue: amountValue,
            supersededByManual: supersededByManual
        )
    }

    /// 行首那个数字里有多少来自订阅。
    ///
    /// **必须从 facts 读，不能从原始订阅列表推。** `displayAmount` 把
    /// `.subscriptionIncluded` 的 fact 加进了行首那个数——照订阅列表另写一句
    /// 「另有订阅」等于同一笔钱报两遍。这里只做拆解：说清那个数由什么组成。
    ///
    /// 折算层还没算出 fact 时（`monthToDate` 为 nil）返回 nil：那会儿行首显示的是
    /// 快照原值，本来就不含订阅，硬加一句拆解只会更糊。
    ///
    /// - Parameter disclosed: 副标题里已经写出来的那部分订阅（「含月费 $4.00」）。
    ///   减掉它，否则 GitHub 这种「月费来自 API」的家会写成
    ///   「含月费 $4.00 · 含订阅 $4.00」——同一笔钱换个词说了两遍。
    private static func subscriptionBreakdown(
        _ facts: [Fact],
        disclosed: Money = .zero,
        presentation: MoneyPresentation
    ) -> String? {
        let subscription = facts
            .filter { $0.type == .subscriptionIncluded }
            .compactMap(\.amountUSD)
            .reduce(Money.zero, +)
        let remaining = subscription - disclosed
        guard remaining > .zero else { return nil }
        return String(localized: L("含订阅 \(remaining.formatted(using: presentation))"))
    }

    private static func paidHint(
        _ descriptor: ProviderDescriptor,
        isStale: Bool
    ) -> (caption: String?, mergedIntoSubtitle: String?) {
        guard descriptor.costsMoneyToRefresh else {
            return (nil, nil)
        }
        let hint = String(localized: L("约 $0.01"))
        if isStale {
            return (nil, hint)
        }
        return (hint, nil)
    }

    private static func mergedSubtitle(_ subtitle: String?, paidHint: String?) -> String? {
        mergedSubtitle(subtitle ?? "", paidHint: paidHint)
    }

    private static func mergedSubtitle(_ subtitle: String, paidHint: String?) -> String? {
        if let paidHint {
            if subtitle.isEmpty { return paidHint }
            return "\(subtitle) · \(paidHint)"
        }
        return subtitle.isEmpty ? nil : subtitle
    }

    /// 副标题，外加**它自己已经写出来的订阅金额**。
    ///
    /// 「含月费 $4.00」这句已经把 API 报回来的月费说了一遍。哪一条分支胜出只有
    /// `subtitle` 自己知道，所以由它一起带出来，别让调用方照着那串优先级重推一遍。
    private struct Subtitle {
        var text: String
        var disclosedSubscription: Money = .zero
    }

    private static func vendorSubtitle(
        descriptor: ProviderDescriptor,
        kind: ProviderKind,
        snapshot: AccountLatest?,
        lastSuccess: Date?,
        isStale: Bool,
        hasAmount: Bool,
        supersededByManual: Bool,
        usesInbox: Bool,
        usageCount: Int,
        subscriptionNames: [String],
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation
    ) -> Subtitle {
        if usageCount == 0, let name = subscriptionNames.first {
            return Subtitle(text: name)
        }
        if usageCount > 1 {
            return Subtitle(text: String(localized: L("\(usageCount) 份用量")))
        }
        return subtitle(
            descriptor: descriptor,
            kind: kind,
            snapshot: snapshot,
            lastSuccess: lastSuccess,
            isStale: isStale,
            hasAmount: hasAmount,
            supersededByManual: supersededByManual,
            usesInbox: usesInbox,
            now: now,
            calendar: calendar,
            presentation: presentation
        )
    }

    private static func subtitle(
        descriptor: ProviderDescriptor,
        kind: ProviderKind,
        snapshot: AccountLatest?,
        lastSuccess: Date?,
        isStale: Bool,
        hasAmount: Bool,
        supersededByManual: Bool,
        usesInbox: Bool,
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation
    ) -> Subtitle {
        if supersededByManual {
            return Subtitle(text: String(localized: L("订阅以手动录入为准")))
        }
        if snapshot?.source == .manual {
            return Subtitle(text: String(localized: L("你填入的")))
        }
        if usesInbox, lastSuccess == nil {
            return Subtitle(text: String(localized: L("等待第一次投递")))
        }
        if descriptor.costsMoneyToRefresh {
            return Subtitle(text: String(localized: L("手动刷新")))
        }
        switch kind {
        case .prepaid:
            if let balance = snapshot?.balanceUSD {
                return Subtitle(
                    text: String(localized: L("余额 \(presentation.string(from: balance, originalCurrency: snapshot?.balanceOriginalCurrency, usdPerUnit: snapshot?.balanceUSDPerUnit))"))
                )
            }
        case .planAndUsage:
            if let committed = snapshot?.committedMonthlyUSD {
                return Subtitle(
                    text: String(localized: L("含月费 \(committed.formatted(using: presentation))")),
                    disclosedSubscription: committed
                )
            }
        case .subscription:
            if let day = snapshot?.chargeDayOfMonth {
                var components = DateComponents()
                components.year = calendar.component(.year, from: now)
                components.month = calendar.component(.month, from: now)
                components.day = day
                let date = calendar.date(from: components) ?? now
                let dayText = MeterDateFormat.monthAndDay(date, calendar: calendar)
                return Subtitle(text: String(localized: L("\(dayText)扣款")))
            }
        case .usage, .freeTier:
            break
        }
        // 刷新时刻只在数据陈旧时才有信息量：读数是新的，「3 分钟前」只是噪声。
        // 陈旧时它回答的是「这个数放了多久」——那句要留。
        if isStale, let lastSuccess {
            return Subtitle(
                text: ServiceRelativeTime.caption(from: lastSuccess, now: now, calendar: calendar)
            )
        }
        return Subtitle(text: hasAmount ? "" : String(localized: L("暂无读数")))
    }

    private static func displayAmount(
        fact: Fact?,
        snapshot: AccountLatest?,
        facts: [Fact],
        now: Date,
        calendar: Calendar
    ) -> Money? {
        let contributing = facts.compactMap { item -> Money? in
            switch item.type {
            case .monthToDateUsage, .prepaidConsumption, .subscriptionIncluded:
                return item.amountUSD
            case .subscriptionSuperseded, .freeQuota, .fetchFailed:
                return nil
            }
        }
        if contributing.count > 1 {
            return contributing.reduce(.zero, +)
        }
        if let fact, fact.type != .subscriptionSuperseded, fact.type != .fetchFailed {
            return fact.amountUSD
        }
        // 折算给不出金额时的兜底：这家自己报的账单金额。
        // 「按 kind 该读哪个字段」这条规则已经在折叠时判过（`AccountLatest.reportedAmountUSD`），
        // 这里不再判第二遍。
        //
        // 「这笔钱算不算这个月的」**在这里判**，不在折叠时判：手填花费可以是给
        // 上个月补的，而那一行会落盘——折叠时用 `now` 判过一次的话，跨月那一刻
        // 盘上那一行就悄悄错了。见 `AccountLatest` 的准入准则第 2 条。
        return snapshot?.reportedAmount(inMonth: MonthKey(now, calendar: calendar))
    }

    private static func preferredFact(_ facts: [Fact]) -> Fact? {
        facts.first { $0.type != .subscriptionSuperseded && $0.type != .fetchFailed }
            ?? facts.first
    }

    /// 内存里的 lastSuccessfulRefreshAt 可能落后于刚写入的 snapshot。取更近的。
    private static func latestSuccess(stamped: Date?, snapshot: AccountLatest?) -> Date? {
        [stamped, snapshot?.fetchedAt].compactMap { $0 }.max()
    }

}
