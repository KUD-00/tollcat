import Foundation
import MeterDesign

enum ProviderHistoryChartContent: Equatable, Sendable {
    case spend(
        points: [PlotPoint],
        start: Date,
        end: Date,
        granularity: HistoryGranularity,
        isIntervalSpend: Bool
    )
    case balance(
        points: [PlotPoint],
        start: Date,
        end: Date,
        granularity: HistoryGranularity,
        inferred: [PlotSegment]
    )
    case none

    var showsChart: Bool {
        if case .none = self { return false }
        return true
    }

    /// 图上至少有一个点。空 `.spend` / `.balance` 只配一句「还没有」，
    /// 三个范围都空的时候连范围切换也不该出现。
    var hasPlot: Bool {
        switch self {
        case .spend(let points, _, _, _, _):
            return !points.isEmpty
        case .balance(let points, _, _, _, _):
            return !points.isEmpty
        case .none:
            return false
        }
    }

    var readingNote: String? {
        guard case .spend(_, _, _, _, true) = self else { return nil }
        return String(localized: L("柱是两次读数之间新花的钱，记在读到的那天。"))
    }

    var plotWindow: (start: Date, end: Date, granularity: HistoryGranularity)? {
        switch self {
        case .spend(_, let start, let end, let granularity, _):
            (start, end, granularity)
        case .balance(_, let start, let end, let granularity, _):
            (start, end, granularity)
        case .none:
            nil
        }
    }
}
