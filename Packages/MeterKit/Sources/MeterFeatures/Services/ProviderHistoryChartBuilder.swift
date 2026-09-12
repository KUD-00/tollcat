import Foundation
import MeterCore
import MeterDesign
import MeterPersistence

/// 分桶、做差、推断段的**计算**单源在 `HistoryChartMath`（MeterCore，Android 共用）。
/// 这里只把结果映射成 iOS 的 `PlotPoint` / `PlotSegment` 视图类型。
/// 取舍（缺失 ≠ 零、柱是独立事实、虚线是推断段）的说明也在那边。
enum ProviderHistoryChartBuilder {
    /// 收**原始读数**（`ReadingSeries`）——这一页画的就是"这家自己报过什么"，
    /// 账本回答不了它。范围由门决定，见 `DashboardModel.readings(for:since:)`。
    static func make(
        kind: ProviderKind,
        readings: ReadingSeries,
        range: ProviderHistoryRange,
        now: Date,
        calendar: Calendar,
        offset: Int = 0,
        spanLookback: Bool = false
    ) -> ProviderHistoryChartContent {
        switch HistoryChartMath.make(
            kind: kind,
            snapshots: Array(readings),
            range: range.chartRange,
            now: now,
            calendar: calendar,
            offset: offset,
            spanLookback: spanLookback
        ) {
        case .spend(let points, let start, let end, let monthly, let isIntervalSpend):
            return .spend(
                points: points.map { PlotPoint(date: $0.date, amount: $0.amount) },
                start: start,
                end: end,
                granularity: monthly ? .month : .day,
                isIntervalSpend: isIntervalSpend
            )
        case .balance(let points, let start, let end, let monthly, let inferredStarts):
            let plotted = points
                .sorted { $0.date < $1.date }
                .map { PlotPoint(date: $0.date, amount: $0.amount) }
            let starts = Set(inferredStarts)
            let inferred = zip(plotted, plotted.dropFirst()).compactMap { lhs, rhs -> PlotSegment? in
                guard starts.contains(lhs.date) else { return nil }
                return PlotSegment(start: lhs, end: rhs, isInferred: true)
            }
            return .balance(
                points: plotted,
                start: start,
                end: end,
                granularity: monthly ? .month : .day,
                inferred: inferred
            )
        case .none:
            return .none
        }
    }

    static func window(
        range: ProviderHistoryRange,
        now: Date,
        calendar: Calendar,
        offset: Int = 0
    ) -> (start: Date, end: Date) {
        HistoryChartMath.window(
            range: range.chartRange,
            now: now,
            calendar: calendar,
            offset: offset
        )
    }

}

private extension ProviderHistoryRange {
    var chartRange: HistoryChartRange {
        switch self {
        case .days7: return .days7
        case .days30: return .days30
        case .months12: return .months12
        }
    }
}
