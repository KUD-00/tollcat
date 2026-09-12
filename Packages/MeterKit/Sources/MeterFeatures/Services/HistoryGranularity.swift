import Foundation
import MeterDesign
import MeterPersistence

/// 历史图横轴按天还是按月。由所选范围决定，不给用户另选。
enum HistoryGranularity: Equatable, Sendable {
    case day
    case month

    var chartUnit: ChartTimeUnit {
        switch self {
        case .day: .day
        case .month: .month
        }
    }
}

extension ProviderHistoryRange {
    var granularity: HistoryGranularity {
        switch self {
        case .days7, .days30: .day
        case .months12: .month
        }
    }

    /// 7 / 30 天是看得见的宽度。12 个月已经是整段，不滑。
    var visibleDayCount: Int? {
        switch self {
        case .days7: 7
        case .days30: 30
        case .months12: nil
        }
    }
}
