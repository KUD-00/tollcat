import Foundation
import MeterCore
import MeterDashboard
import MeterFormat
import MeterGlance

/// 仪表内容 → 手表和锁屏那一眼（`Glance`）。
///
/// **不折算**：读的是 `DashboardContentsBuilder.widget` 出来的那一份，
/// 字也尽量直接拿模块内容里排好的——锁屏、表盘、主屏 widget、App 首屏说的是同一个数、同一句话。
/// 这里只补模块内容里没有的那几样：短金额、「按当前速度会超预算」、手表 App 里每家的详情页。
public enum GlanceBuilder {
    /// 手表 App 列几家。再多的并成「其他」。
    public static let serviceLimit = 5

    /// 详情页柱图画几天。
    public static let detailDays = 30

    /// 手表 App 详情页要、而 `DashboardContents` 里没有的那几样。
    ///
    /// 全是账本里现成的（`LedgerView.dailySpend(for:)`、`PrepaidRunwayCalculator`），
    /// 不读原始快照。锁屏那份不传：那几格从不点进去，白算一遍。
    public struct DetailSource {
        public var dailySpend: (AccountID) -> [Date: Money]
        public var runways: [PrepaidRunway]
        public var connections: [ProviderConnectionState]

        public init(
            dailySpend: @escaping (AccountID) -> [Date: Money],
            runways: [PrepaidRunway],
            connections: [ProviderConnectionState]
        ) {
            self.dailySpend = dailySpend
            self.runways = runways
            self.connections = connections
        }
    }

    /// - Parameters:
    ///   - isEmpty: 一条账单读数都还没有（`SharedStoreContents.isEmpty`）。
    ///   - canSpeak: 账本说得了 `now` 那个月（`SharedStoreContents.canSpeak`）。
    ///   - budgetUSD: 用户设的月预算；「月底会不会超」要拿外推去比它。
    ///   - details: 给了才建每家的详情页（只有推给手表那份给）。
    public static func make(
        contents: DashboardContents,
        isEmpty: Bool,
        canSpeak: Bool,
        budgetUSD: Decimal?,
        lastRefreshAt: Date?,
        presentation: MoneyPresentation,
        now: Date,
        calendar: Calendar,
        details: DetailSource? = nil
    ) -> Glance {
        let interval = calendar.dateInterval(of: .month, for: now)
            ?? DateInterval(start: now, duration: 0)
        let content: GlanceContent
        if isEmpty {
            content = .noBills
        } else if canSpeak, let month = month(
            contents: contents,
            budgetUSD: budgetUSD,
            presentation: presentation,
            details: details.map { DetailContext(source: $0, now: now, calendar: calendar) }
        ) {
            content = .month(month)
        } else {
            content = .waitingForMonth
        }
        return Glance(
            monthStart: interval.start,
            monthEnd: interval.end,
            generatedAt: now,
            lastRefreshAt: lastRefreshAt,
            content: content
        )
    }

    static func month(
        contents: DashboardContents,
        budgetUSD: Decimal?,
        presentation: MoneyPresentation,
        details: DetailContext? = nil
    ) -> GlanceMonth? {
        guard let result = contents.monthToDate, let headline = contents.monthToDateContent else {
            return nil
        }
        let projects = result.filter.allowsProjection
        return GlanceMonth(
            amountText: headline.amountText,
            compactAmountText: GlanceAmountFormat.compact(
                presentation.amount(from: result.totalUSD),
                code: presentation.currencyCode
            ),
            spokenAmount: headline.spokenTotal,
            projectionText: headline.projectedCaption,
            spokenProjection: projects ? headline.spokenProjected : nil,
            periodText: headline.periodCaption,
            budget: budget(
                contents.budgetContent,
                projected: projects ? result.projectedMonthEndUSD : nil,
                budgetUSD: budgetUSD,
                presentation: presentation
            ),
            services: services(
                contents.compositionContent,
                presentation: presentation,
                detail: details.map { context in
                    { segment in
                        detail(
                            for: segment,
                            facts: result.facts,
                            comparison: contents.comparisonContent,
                            context: context,
                            presentation: presentation
                        )
                    }
                }
            )
        )
    }

    static func budget(
        _ content: BudgetModuleContent?,
        projected: Money?,
        budgetUSD: Decimal?,
        presentation: MoneyPresentation
    ) -> GlanceBudget? {
        guard let content else { return nil }
        let level: GlanceBudgetLevel = content.isOver ? .over : (content.isClose ? .close : .normal)
        // 已经超了就不再说「会超」：那句由 caption 的「超出 $x」说。
        var projectedOverspend: String?
        if !content.isOver,
           let projected,
           let gauge = BudgetGauge.make(spent: projected, budgetUSD: budgetUSD),
           gauge.isOver {
            projectedOverspend = String(
                localized: L("预计超预算 \(gauge.overspend.formatted(using: presentation))")
            )
        }
        return GlanceBudget(
            fraction: content.fraction,
            percentText: content.percentText,
            limitText: content.budgetText,
            caption: content.caption,
            level: level,
            projectedOverspendText: projectedOverspend,
            spokenLabel: content.spokenLabel
        )
    }

    /// 构成图那几段，按金额从大到小。前几名各一行，其余并成「其他」。
    static func services(
        _ composition: CompositionModuleContent?,
        presentation: MoneyPresentation,
        detail: ((CompositionSegment) -> GlanceServiceDetail?)? = nil
    ) -> [GlanceService] {
        guard let segments = composition?.segments, !segments.isEmpty else { return [] }
        let ranked = segments.enumerated()
            .sorted { lhs, rhs in
                lhs.element.amount == rhs.element.amount
                    ? lhs.offset < rhs.offset
                    : lhs.element.amount > rhs.element.amount
            }
            .map(\.element)
        var rows = ranked.prefix(serviceLimit).enumerated().map { rank, segment in
            GlanceService(
                rank: rank,
                name: segment.displayName,
                amountText: segment.amount.formatted(using: presentation),
                spokenAmount: SpokenMoney.label(for: segment.amount, presentation: presentation),
                detail: detail?(segment)
            )
        }
        let rest = ranked.dropFirst(serviceLimit)
        if !rest.isEmpty {
            let sum = rest.reduce(Money.zero) { $0 + $1.amount }
            rows.append(
                GlanceService(
                    rank: rows.count,
                    name: String(localized: L("其他")),
                    amountText: sum.formatted(using: presentation),
                    spokenAmount: SpokenMoney.label(for: sum, presentation: presentation),
                    isRemainder: true
                )
            )
        }
        return rows
    }

    struct DetailContext {
        var source: DetailSource
        var now: Date
        var calendar: Calendar
    }

    /// 一家的详情页。数字和句子能拿现成的就拿现成的：
    /// 同期对比是对比卡那一行、明细是构成页那几行、余额和天数是余额告急那一套算法。
    static func detail(
        for segment: CompositionSegment,
        facts: [Fact],
        comparison: ComparisonModuleContent?,
        context: DetailContext,
        presentation: MoneyPresentation
    ) -> GlanceServiceDetail? {
        let attribution = attribution(of: segment)
        let days = segment.accountID.map {
            detailDays(daily: context.source.dailySpend($0), context: context, presentation: presentation)
        } ?? []

        // 柱只有按量的钱；这家本月的订阅是整笔扣的，得另外说一句，否则柱加起来对不上大数字。
        let subscriptionUSD = facts
            .filter { $0.type == .subscriptionIncluded }
            .filter { SpendAttribution.attribute($0, connections: context.source.connections) == attribution }
            .compactMap(\.amountUSD)
            .reduce(Money.zero, +)
        let subscriptionNote = !days.isEmpty && subscriptionUSD > .zero
            ? String(localized: L("订阅 \(subscriptionUSD.formatted(using: presentation)) 按月扣，不在柱上"))
            : nil

        // 只有一家的时候「占本月 100%」是一句废话。
        let shareText = segment.percent < 100
            ? String(localized: L("占本月 \((Double(segment.percent) / 100).formatted(.percent))"))
            : nil

        let detail = GlanceServiceDetail(
            shareText: shareText,
            change: change(for: attribution, in: comparison),
            days: days,
            subscriptionNote: subscriptionNote,
            sublines: segment.sublines.map {
                GlanceSubline(id: $0.id, title: $0.title, amountText: $0.amountCaption)
            },
            balance: segment.accountID.flatMap { id in
                context.source.runways.first { $0.accountID == id }
            }.map { balance($0, presentation: presentation) }
        )
        // 一样都没有就别让这一行能点：点进去只有一个和列表里一样的数。
        return detail == GlanceServiceDetail() ? nil : detail
    }

    /// 构成段和对比行是按同一个 `SpendAttribution` 建的（见两个 builder 的 switch），
    /// 这里从 (accountID, providerID) 还原回去，两边就能对上。
    private static func attribution(accountID: AccountID?, providerID: ProviderID?) -> SpendAttribution {
        if let accountID { return .account(accountID) }
        if let providerID { return .vendor(providerID) }
        return .manual
    }

    private static func attribution(of segment: CompositionSegment) -> SpendAttribution {
        attribution(accountID: segment.accountID, providerID: segment.providerID)
    }

    /// 近 30 天，一天一根，旧到新，缺的天记 0。
    /// 一整段都是 0（这家报不出按天的数，或者一个月没用）就不画——一排空柱什么也没说。
    static func detailDays(
        daily: [Date: Money],
        context: DetailContext,
        presentation: MoneyPresentation
    ) -> [GlanceDay] {
        guard !daily.isEmpty else { return [] }
        let today = context.calendar.startOfDay(for: context.now)
        let days: [GlanceDay] = (0..<detailDays).reversed().compactMap { back in
            guard let day = context.calendar.date(byAdding: .day, value: -back, to: today) else { return nil }
            let amount = daily[day] ?? .zero
            return GlanceDay(
                date: day,
                value: NSDecimalNumber(decimal: presentation.amount(from: amount)).doubleValue,
                amountText: amount.formatted(using: presentation)
            )
        }
        return days.contains { $0.value > 0 } ? days : []
    }

    private static func change(
        for attribution: SpendAttribution,
        in comparison: ComparisonModuleContent?
    ) -> GlanceChange? {
        guard let comparison,
              let item = comparison.items.first(where: {
                  Self.attribution(accountID: $0.accountID, providerID: $0.providerID) == attribution
              }),
              item.isComparable
        else {
            return nil
        }
        let direction: GlanceChange.Direction = switch item.tone {
        case .up: .up
        case .down: .down
        case .flat, .unknown: .flat
        }
        return GlanceChange(
            text: String(localized: L("较上月同期 \(item.trailingText)")),
            detailText: item.subtitle(previousMonthName: comparison.previousMonthName),
            direction: direction
        )
    }

    private static func balance(_ runway: PrepaidRunway, presentation: MoneyPresentation) -> GlanceBalance {
        GlanceBalance(
            balanceText: String(localized: L("余额 \(runway.balanceUSD.formatted(using: presentation))")),
            runwayText: String(localized: L("还能用 \(runway.daysRemaining) 天")),
            // 和余额告急卡同一条线：一周内见底标红。
            isLow: runway.daysRemaining < 7
        )
    }
}
