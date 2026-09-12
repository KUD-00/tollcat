#if DEBUG
import Foundation

/// 实验室里模块吃哪份数。当前账本可能缺某一块；设计稿永远有。
enum DashboardLabDataSource: String, CaseIterable, Identifiable {
    case live
    case fixture

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .live: L("当前账本")
        case .fixture: L("设计稿")
        }
    }
}
#endif
