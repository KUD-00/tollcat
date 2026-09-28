import Foundation
import MeterCore
import MeterDashboard
import MeterFormat
import MeterGlance

/// 仪表内容 → 手表和锁屏那一眼（`Glance`）。
///
/// **不折算**：读的是 `DashboardContentsBuilder.widget` 出来的那一份，
/// 字也尽量直接拿模块内容里排好的——锁屏、表盘、主屏 widget、App 首屏说的是同一个数、同一句话。
/// 这里只补模块内容里没有的那几样：短金额、累计走势、「按当前速度会超预算」。
public enum GlanceBuilder {
    /// 手表 App 列几家。再多的并成「其他」。
    public static let serviceLimit = 5

    /// - Parameters:
    ///   - isEmpty: 一条账单读数都还没有（`SharedStoreContents.isEmpty`）。
    ///   - canSpeak: 账本说得了 `now` 那个月（`SharedStoreContents.canSpeak`）。
    ///   - budgetUSD: 用户设的月预算；「月底会不会超」要拿外推去比它。
    public static func make(
        contents: DashboardContents,
        isEmpty: Bool,
        canSpeak: Bool,
        budgetUSD: Decimal?,
        lastRefreshAt: Date?,
        presentation: MoneyPresentation,
        now: Date,
        calendar: Calendar
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
            now: now,
            calendar: calendar
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
        now: Date,
        calendar: Calendar
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
            trend: trend(
                heatmap: contents.heatmapContent,
                total: result.totalUSD,
                projected: projects ? result.projectedMonthEndUSD : nil,
                now: now,
                calendar: calendar
            ),
            budget: budget(
                contents.budgetContent,
                projected: projects ? result.projectedMonthEndUSD : nil,
                budgetUSD: budgetUSD,
                presentation: presentation
            ),
            services: services(contents.compositionContent, presentation: presentation)
        )
    }

    /// 热力图那份按天读数累加到今天。
    ///
    /// 日读数只有从量；订阅按扣款日整笔进合计，不在日线上。所以累计线按比例缩到
    /// 正好落在大数字上——这条线只表示**怎么涨上来的**，不标数，终点和大数字对不上反而是错的。
    static func trend(
        heatmap: HeatmapModuleContent?,
        total: Money,
        projected: Money?,
        now: Date,
        calendar: Calendar
    ) -> GlanceTrend? {
        guard let days = heatmap?.months.first(where: {
            calendar.isDate($0.monthStart, equalTo: now, toGranularity: .month)
        })?.values else {
            return nil
        }
        let today = calendar.component(.day, from: now)
        guard today >= 2, days.count >= today else { return nil }
        var running = 0.0
        let raw = days.prefix(today).map { value -> Double in
            running += value ?? 0
            return running
        }
        let totalValue = NSDecimalNumber(decimal: total.usd).doubleValue
        guard running > 0, totalValue > 0 else { return nil }
        let projectedValue = projected.map { NSDecimalNumber(decimal: $0.usd).doubleValue }
        let top = max(totalValue, projectedValue ?? 0)
        let scale = totalValue / running / top
        return GlanceTrend(
            cumulative: raw.map { $0 * scale },
            projectedEnd: projectedValue.map { $0 / top },
            dayCount: days.count
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
        presentation: MoneyPresentation
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
                spokenAmount: SpokenMoney.label(for: segment.amount, presentation: presentation)
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
}
