import Foundation
import MeterCore
import MeterDesign
import MeterFormat

public enum TrendBuilder {
    /// 收**现成的逐月数据**，自己不去算。
    ///
    /// 算法有两条路（读物化账本 / 全量重算），谁来算是调用方的事；这一层只负责
    /// 把点画成柱。以前它自己跑折算器，于是"用哪条路"这个决定被埋在了画图的代码里。
    public static func make(
        history: [MonthSpendPoint],
        calendar: Calendar,
        filter: DashboardFilter,
        presentation: MoneyPresentation = .usd
    ) -> TrendModuleContent? {
        guard let first = history.first, let last = history.last else { return nil }

        // 柱子的口径跟大数字同一个：算进订阅画合计，关掉画从量。
        let includesSubscriptions = filter.includesSubscriptions
        let points = history.compactMap { point -> PlotPoint? in
            let amount = includesSubscriptions ? point.totalUSD : point.variableUSD
            guard amount > .zero else { return nil }
            return PlotPoint(
                date: point.monthStart,
                amount: NSDecimalNumber(decimal: presentation.amount(from: amount)).doubleValue
            )
        }
        guard !points.isEmpty else { return nil }

        // 不含本月：本月还没过完，摊进去会把月均往下拉。
        let past = history.dropLast().map { includesSubscriptions ? $0.totalUSD : $0.variableUSD }.filter { $0 > .zero }
        let averageText: String? = past.isEmpty
            ? nil
            : (past.reduce(Money.zero, +) / Decimal(past.count)).formatted(using: presentation)

        let names = points.map { point in
            MeterDateFormat.monthName(now: point.date, calendar: calendar)
        }
        let spoken: String
        if names.count == 1, let only = names.first {
            spoken = includesSubscriptions
                ? String(localized: L("近几个月合计，只有 \(only)"))
                : String(localized: L("近几个月按量，只有 \(only)"))
        } else if let firstName = names.first, let lastName = names.last {
            spoken = includesSubscriptions
                ? String(localized: L("近几个月合计，从 \(firstName) 到 \(lastName)"))
                : String(localized: L("近几个月按量，从 \(firstName) 到 \(lastName)"))
        } else {
            spoken = includesSubscriptions
                ? String(localized: L("近几个月合计"))
                : String(localized: L("近几个月按量"))
        }

        return TrendModuleContent(
            points: points,
            xStart: first.monthStart,
            xEnd: CompactMonthBarChart.domainEnd(
                afterLastMonthStart: last.monthStart,
                calendar: calendar
            ),
            highlight: last.monthStart,
            spokenLabel: spoken,
            averageText: averageText
        )
    }
}
