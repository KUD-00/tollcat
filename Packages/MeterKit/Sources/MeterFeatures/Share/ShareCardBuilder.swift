import Foundation
import MeterCore
import MeterDesign
import MeterModules

/// 把仪表的数据折成分享卡要画的东西。
///
/// 格式化全在这一层做完：`MeterDesign` 不认识 `Money`，
/// 卡上要画什么字必须在传进去之前定死。
enum ShareCardBuilder: Sendable {
    /// 图例只留前 5 名；再多的合并成「其他」，跟仪表构成环同一条线。
    static let namedLimit = CompositionSlices.namedLimit

    /// 二维码指向的地址。**写死在这里**，和 `ProviderDescriptor` 的 URL 同一条红线：
    /// 远程可改的地址等于让别人替你决定这张卡把人送到哪。
    static let shareHost = "tollcat.app"
    static let shareURL = "https://\(shareHost)"

    /// `now` 收的是**折算锚点**，不是真正的此刻：回看七月时卡上那个月份
    /// 必须写「七月」。调用方负责先过 `DashboardFilter.anchor`。
    static func content(
        monthToDate: MonthToDate?,
        composition: [CompositionSegment],
        comparison: ComparisonModuleContent? = nil,
        trend: TrendModuleContent? = nil,
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation = .usd,
        connections: [ProviderConnectionState] = []
    ) -> ShareCardContent {
        // 卡上那个期间名跟取景框走。多月区间下写「九月」会把一张三个月的合计
        // 冒充成一个月的账单——而这张图是唯一会离开 App 的东西。
        let periodTitle = monthToDate.map { month in
            DashboardFilterSummary.periodHeading(
                period: month.filter.period,
                window: month.window,
                asOf: now,
                calendar: calendar
            )
        } ?? MeterDateFormat.monthName(now: now, calendar: calendar)
        let hero = monthToDate.map { month in
            MonthToDateModuleContent.make(
                from: month,
                estimatedNames: [],
                staleCaption: nil,
                now: now,
                calendar: calendar,
                presentation: presentation,
                connections: connections
            )
        }
        return ShareCardContent(
            periodTitle: periodTitle,
            totalText: totalText(hero),
            projectionText: hero?.fullProjectedCaption,
            subscriptionText: hero?.subscriptionCaption,
            currencyNote: hero?.currencyNote,
            segments: segments(composition, presentation: presentation),
            comparison: comparisonContent(comparison, monthToDate: monthToDate),
            trend: trendContent(trend),
            filterNote: hero?.filterNote,
            qrPayload: shareURL,
            // 落款和站点页脚同一句。这张图会离开 App，不许另写自我介绍（BRAND.md）。
            qrCaption: String(localized: L("把各家云账单，装进口袋。")),
            // 主机名不进 catalog：它是地址，不是句子。码被压糊时还能手打。
            footnote: shareHost
        )
    }

    private static func totalText(_ hero: MonthToDateModuleContent?) -> String {
        guard let hero else { return String(localized: L("还没有账单")) }
        return hero.amountText
    }

    private static func comparisonContent(
        _ comparison: ComparisonModuleContent?,
        monthToDate: MonthToDate?
    ) -> ShareCardContent.Comparison? {
        if let comparison {
            return ShareCardContent.Comparison(
                title: String(localized: L("较上月同期")),
                percentText: comparison.percentText,
                caption: comparison.caption,
                current: comparison.current,
                previous: comparison.tone == .unknown ? nil : comparison.previous,
                currentLabel: comparison.currentLabel,
                previousLabel: comparison.previousLabel,
                tone: tone(comparison.tone),
                showsBars: comparison.tone != .unknown || comparison.current > 0
            )
        }
        guard let ratio = monthToDate?.changeRatio, ratio.isFinite, abs(ratio) >= 0.01 else {
            return nil
        }
        return ShareCardContent.Comparison(
            title: String(localized: L("较上月同期")),
            percentText: DashboardPercentFormat.signed(ratio),
            caption: nil,
            current: 0,
            previous: nil,
            currentLabel: String(localized: L("本月")),
            previousLabel: String(localized: L("上月")),
            tone: ratio > 0 ? .up : ratio < 0 ? .down : .flat,
            showsBars: false
        )
    }

    private static func tone(_ tone: ComparisonModuleContent.Tone) -> ShareCardContent.Comparison.Tone {
        switch tone {
        case .up: .up
        case .down: .down
        case .flat: .flat
        case .unknown: .unknown
        }
    }

    private static func trendContent(_ trend: TrendModuleContent?) -> ShareCardContent.Trend? {
        guard let trend, !trend.points.isEmpty else { return nil }
        return ShareCardContent.Trend(
            title: String(localized: L("近几个月")),
            points: trend.points,
            xStart: trend.xStart,
            xEnd: trend.xEnd,
            highlight: trend.highlight
        )
    }

    private static func segments(
        _ composition: [CompositionSegment],
        presentation: MoneyPresentation
    ) -> [ShareCardContent.Segment] {
        func item(_ segment: CompositionSegment, isOther: Bool = false) -> ShareCardContent.Segment {
            ShareCardContent.Segment(
                name: segment.displayName,
                amountText: segment.amount.formatted(using: presentation),
                fraction: segment.fraction,
                isOther: isOther
            )
        }
        guard composition.count > namedLimit else {
            return composition.map { item($0) }
        }

        let named = composition.prefix(namedLimit).map { item($0) }
        let rest = composition.dropFirst(namedLimit)
        let amount = rest.reduce(Money.zero) { $0 + $1.amount }
        let fraction = rest.reduce(0.0) { $0 + $1.fraction }
        let other = ShareCardContent.Segment(
            name: String(localized: L("其他")),
            amountText: amount.formatted(using: presentation),
            fraction: fraction,
            isOther: true
        )
        return named + [other]
    }
}
