import Foundation
import MeterPersistence

extension ProviderHistoryRange {
    var title: String {
        switch self {
        case .days7: String(localized: L("7 天"))
        case .days30: String(localized: L("30 天"))
        case .months12: String(localized: L("12 个月"))
        }
    }
}
