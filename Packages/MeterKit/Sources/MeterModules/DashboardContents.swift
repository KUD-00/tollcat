import Foundation
import MeterCore
import MeterFormat

/// 一次重算产出的全部仪表内容。折成一个值类型：
/// 清空是 `.init()`，赋值是一次整体替换，不会出现「换了一半」的中间态。
/// 「这批数据在这个取景框下的本月至今」。折算本身在 MeterCore，这里只是把它做成
/// 可替换的一步——测试和演示种子要塞固定值，不该去改 builder。
public typealias MonthToDateCompute = @Sendable (
    /// 读模型整份。**没有快照日志**——「哪条读数算数」在折叠时判过了，
    /// 展示路径不该再有第二次机会去判它。
    ///
    /// （这道边界有闸守着，扫的是类型名的字面量，所以连注释里都不写出那个词。）
    _ view: LedgerView,
    _ now: Date,
    _ calendar: Calendar,
    _ filter: DashboardFilter
) -> MonthToDate

public struct DashboardContents: DashboardModuleContents, Sendable {
    public var monthToDate: MonthToDate?
    public var monthToDateContent: MonthToDateModuleContent?
    public var compositionContent: CompositionModuleContent?
    public var comparisonContent: ComparisonModuleContent?
    public var trendContent: TrendModuleContent?
    public var anomalyContent: AnomalyModuleContent?
    public var balanceAlertContent: BalanceAlertModuleContent?
    public var upcomingChargesContent: UpcomingChargesModuleContent?
    public var freeQuotaContent: FreeQuotaModuleContent?
    public var servicesContent: ServicesModuleContent?
    public var subscriptionsContent: SubscriptionsModuleContent?
    public var heatmapContent: HeatmapModuleContent?
    public var categoriesContent: CategoriesModuleContent?
    public var superlativesContent: SuperlativesModuleContent?
    public var budgetContent: BudgetModuleContent?

    /// 空的一份：还没有任何账单时用它。
    public init() {}

    public init(
        monthToDate: MonthToDate? = nil,
        monthToDateContent: MonthToDateModuleContent? = nil,
        compositionContent: CompositionModuleContent? = nil,
        comparisonContent: ComparisonModuleContent? = nil,
        trendContent: TrendModuleContent? = nil,
        anomalyContent: AnomalyModuleContent? = nil,
        balanceAlertContent: BalanceAlertModuleContent? = nil,
        upcomingChargesContent: UpcomingChargesModuleContent? = nil,
        freeQuotaContent: FreeQuotaModuleContent? = nil,
        servicesContent: ServicesModuleContent? = nil,
        subscriptionsContent: SubscriptionsModuleContent? = nil,
        heatmapContent: HeatmapModuleContent? = nil,
        categoriesContent: CategoriesModuleContent? = nil,
        superlativesContent: SuperlativesModuleContent? = nil,
        budgetContent: BudgetModuleContent? = nil
    ) {
        self.monthToDate = monthToDate
        self.monthToDateContent = monthToDateContent
        self.compositionContent = compositionContent
        self.comparisonContent = comparisonContent
        self.trendContent = trendContent
        self.anomalyContent = anomalyContent
        self.balanceAlertContent = balanceAlertContent
        self.upcomingChargesContent = upcomingChargesContent
        self.freeQuotaContent = freeQuotaContent
        self.servicesContent = servicesContent
        self.subscriptionsContent = subscriptionsContent
        self.heatmapContent = heatmapContent
        self.categoriesContent = categoriesContent
        self.superlativesContent = superlativesContent
        self.budgetContent = budgetContent
    }
}

/// 一次重算的全部输入。收成一个 Sendable 的值，整场组装才好整个搬到后台线程去做
/// （`DashboardModel.rebuildPresentationOffMain()`）。
public struct DashboardContentInputs: Sendable {
    /// 仪表盘那一屏的全部输入。**这里说不出「快照的集合」那个类型**——
    /// 那是这一层存在的全部意义（见 `LedgerView` 的类型注释）。
    public var view: LedgerView
    public var filter: DashboardFilter
    public var now: Date
    public var calendar: Calendar
    public var presentation: MoneyPresentation
    public var connections: [ProviderConnectionState]
    public var providerMarks: [AccountID: ProviderDataMark]
    public var layout: DashboardLayout
    public var compute: MonthToDateCompute

    public init(
        view: LedgerView,
        filter: DashboardFilter,
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation,
        connections: [ProviderConnectionState],
        providerMarks: [AccountID: ProviderDataMark],
        layout: DashboardLayout,
        compute: @escaping MonthToDateCompute
    ) {
        self.view = view
        self.filter = filter
        self.now = now
        self.calendar = calendar
        self.presentation = presentation
        self.connections = connections
        self.providerMarks = providerMarks
        self.layout = layout
        self.compute = compute
    }
}

/// 仪表内容的组装。纯函数：入参给全（快照、订阅、取景框、时钟、货币、接入、标记），
/// 出参是一份 `DashboardContents` —— 于是整个组装可以脱离 `DashboardModel` 单测。
///
/// 顺手把预充值跑道一并返回：余额告急卡和猫都要它，别算两遍。
///
/// **不带隔离**：里面没有一处碰 UI，刷新时整场搬去后台线程算，算完只把结果送回主线程。
public enum DashboardContentsBuilder {
    /// `accountID` → 结束那天。没结束的不进表。
    public static func endedAccounts(
        in connections: [ProviderConnectionState]
    ) -> [AccountID: Date] {
        var result: [AccountID: Date] = [:]
        for connection in connections {
            if let archivedAt = connection.archivedAt {
                result[connection.accountID] = archivedAt
            }
        }
        return result
    }

    public static func make(
        _ inputs: DashboardContentInputs
    ) -> (contents: DashboardContents, runways: [PrepaidRunway]) {
        make(
            view: inputs.view,
            filter: inputs.filter,
            now: inputs.now,
            calendar: inputs.calendar,
            presentation: inputs.presentation,
            connections: inputs.connections,
            providerMarks: inputs.providerMarks,
            layout: inputs.layout,
            compute: inputs.compute
        )
    }

    public static func make(
        view unscoped: LedgerView,
        filter: DashboardFilter,
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation,
        connections: [ProviderConnectionState],
        providerMarks: [AccountID: ProviderDataMark],
        layout: DashboardLayout = .default,
        compute: MonthToDateCompute
    ) -> (contents: DashboardContents, runways: [PrepaidRunway]) {
        guard !unscoped.isEmpty else {
            return (DashboardContents(), [])
        }

        // 取景框在这一处折进去，下游各 builder 一律只看筛过的数据。
        //
        // 「此刻」也由它决定：往前翻月份时 `asOf` 是那个月的最后一瞬，
        // 于是外推、上月同期、订阅归属全都自动落到那个月，各 builder 不必知道。
        let asOf = filter.anchor(now: now, calendar: calendar)
        let view = unscoped.scoped(to: filter)
        let scopedSubscriptions = view.subscriptions

        let runways = filter.showsPresentTenseModules
            ? PrepaidRunwayCalculator.compute(
                latest: view.latest,
                rollups: view.rollups,
                now: now,
                calendar: calendar
            )
            : []

        var contents = DashboardContents()
        // **合计走账本**：「近 3 个月」不再是把全部快照扫 3 遍，而是把 3×账号数 行加起来。
        // 账本不可用时（冷启动只读了一截、或刚落完盘还没折）回落到全量重算——
        // 同一批数，只是慢；`LedgerSelfCheck` 守着两条路逐项相同。
        let result = compute(unscoped, now, calendar, filter)
        contents.monthToDate = result
        contents.monthToDateContent = MonthToDateModuleContent.make(
            from: result,
            estimatedNames: estimatedDisplayNames(in: result, connections: connections),
            staleCaption: staleCaption(providerMarks: providerMarks),
            now: asOf,
            calendar: calendar,
            presentation: presentation,
            connections: connections
        )
        // 构成页和对比页各算一份子行：对比页带上同期涨跌，构成页不能跟着
        // 把「较上月」读出来。都吃取景框筛过的数据——回看七月时挂出来的
        // 必须是七月那条明细，不是今天的。
        // 订阅只在口径放行时列进去：段合计来自订阅 fact，fact 不存在时
        // 子行加起来会比段还多。
        let scopedSubsForSublines = filter.includesSubscriptions ? scopedSubscriptions : []
        // 多月区间不给子行。子行取的是「截止 asOf 最新一条带明细的快照」——
        // 那是**某一刻**的构成，不是一段时间的和。段合计已经按月加过了，
        // 再挂一份只覆盖最新那个月的明细，两个数字会当场对不上。
        let showsSublines = result.window.isSingleMonth
        func sublines(window: ComparisonWindow? = nil) -> [SpendAttribution: [SpendSubline]] {
            guard showsSublines else { return [:] }
            return SpendSublineBuilder.byAttribution(
                lines: view.lines(onOrBefore: asOf),
                previousLines: window.map {
                    view.lines(onOrBefore: $0.end, notBefore: $0.start)
                } ?? [:],
                subscriptions: scopedSubsForSublines,
                connections: connections,
                asOf: asOf,
                calendar: calendar,
                presentation: presentation,
                comparisonWindow: window
            )
        }
        contents.compositionContent = CompositionBuilder.make(
            from: result,
            connections: connections,
            presentation: presentation,
            sublines: sublines()
        )
        // 对比卡要有同期窗口才成立。多月区间下 `PeriodTotalCalculator` 不给同期
        // （逐月的「上月同期」加起来是一个重叠的窗口，是错的），这里跟着不建。
        if contents.compositionContent != nil, result.comparisonWindow != nil {
            contents.comparisonContent = ComparisonBuilder.make(
                from: result,
                connections: connections,
                calendar: calendar,
                presentation: presentation,
                sublines: sublines(window: result.comparisonWindow)
            )
        }
        if contents.compositionContent != nil {
            // 趋势柱和合计读同一批行。以前它自己跑一遍 `MonthSpendHistoryCalculator`，
            // 等于把合计已经逐月算过的东西再算一遍——实测常常比合计本身还贵。
            contents.trendContent = TrendBuilder.make(
                history: LedgerProjection.monthlyHistory(
                    rollups: unscoped.rollups,
                    subscriptions: unscoped.subscriptions,
                    now: now,
                    calendar: calendar,
                    filter: filter
                ),
                calendar: calendar,
                filter: filter,
                presentation: presentation
            )
        }
        contents.anomalyContent = AnomalyBuilder.make(
            from: result,
            connections: connections,
            calendar: calendar,
            presentation: presentation
        )
        // 余额告急和即将扣款说的都是「此刻」。回看七月时它们没有意义，
        // 直接不建——留着会和页面顶上那句「七月」互相矛盾。
        if filter.showsPresentTenseModules {
            contents.balanceAlertContent = BalanceAlertBuilder.make(
                runways: runways,
                connections: connections,
                presentation: presentation
            )
            // 「即将扣款」不跟订阅口径走：口径管的是**合计怎么算**，
            // 这张卡说的是「几天后要扣一笔钱」——只看从量的人也该被提醒。
            // （以前跟着关，是因为顶上还挂着「不含订阅」的限定语会自相矛盾；
            // 订阅口径成为一等公民切换后，那句限定语已经不存在了。）
            // 这块目前整个下架，理由写在 `DashboardModuleThresholds` 那个开关上。
            if DashboardModuleThresholds.showsUpcomingCharges {
                contents.upcomingChargesContent = UpcomingChargesBuilder.make(
                    latest: view.latest,
                    subscriptions: scopedSubscriptions,
                    now: now,
                    calendar: calendar,
                    presentation: presentation
                )
            }
        }
        // 免费额度用的是最新那条快照上的 ratio，不是那个月的历史值。
        // 回看七月时把「Vercel 已用 84%」摆出来，那个 84% 其实是今天的数。
        contents.freeQuotaContent = filter.showsPresentTenseModules
            ? FreeQuotaBuilder.make(from: result, connections: connections)
            : nil

        // 用户可选的几块。没数据照样 nil，页面上自动不出现；开没开由 layout 决定，
        // 这里全算——编辑面开关一按就要有东西，不能等下一次刷新。
        contents.servicesContent = ServicesModuleBuilder.make(
            pinned: layout.pinnedAccounts.filter { !filter.excludedAccounts.contains($0) },
            connections: connections,
            dailySpend: { unscoped.dailySpend(for: $0) },
            composition: contents.compositionContent,
            comparison: contents.comparisonContent,
            now: asOf,
            calendar: calendar,
            presentation: presentation
        )
        // 订阅模块不跟订阅口径走：它说的是「有哪些固定订阅」，和合计怎么算是两件事。
        contents.subscriptionsContent = SubscriptionsModuleBuilder.make(
            subscriptions: scopedSubscriptions,
            connections: connections,
            now: asOf,
            calendar: calendar,
            presentation: presentation,
            window: result.window
        )
        // 热力图自己翻月份，不跟 monthsBack 走；账号排除仍然生效。
        contents.heatmapContent = HeatmapBuilder.make(
            dailyTotals: view.dailyTotals(),
            now: now,
            calendar: calendar,
            presentation: presentation
        )
        contents.categoriesContent = CategoriesBuilder.make(
            composition: contents.compositionContent,
            presentation: presentation
        )
        contents.superlativesContent = SuperlativesBuilder.make(
            comparison: contents.comparisonContent,
            composition: contents.compositionContent,
            connections: connections,
            now: now,
            showsStalest: filter.showsPresentTenseModules
        )
        // 预算是**月度**的。拿一个月的额度去比三个月的花费，进度条必然爆表，
        // 而那不是超支，是量错了尺子。
        if filter.allowsMonthlyBudget {
            contents.budgetContent = BudgetBuilder.make(
                monthToDate: result,
                budgetUSD: layout.monthlyBudgetUSD,
                presentation: presentation
            )
        }
        return (contents, runways)
    }

    private static func estimatedDisplayNames(
        in result: MonthToDate,
        connections: [ProviderConnectionState]
    ) -> [String] {
        result.estimatedAccounts.map { id in
            let providerID = connections.first { $0.accountID == id }?.providerID
            let vendor = providerID.flatMap { ProviderIdentity.known($0)?.displayName }
                ?? providerID?.rawValue
                ?? id.rawValue.uuidString
            return AccountTitle.context(
                for: id,
                connections: connections,
                providerDisplayName: vendor
            ).visual
        }
    }

    private static func staleCaption(
        providerMarks: [AccountID: ProviderDataMark]
    ) -> String? {
        let marked = providerMarks.filter { $0.value == .stale || $0.value == .failed }
        guard !marked.isEmpty else { return nil }
        return String(localized: L("部分数据陈旧，仍显示上次成功的数字"))
    }
}
