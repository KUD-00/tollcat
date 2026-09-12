#if DEBUG
import Foundation
import MeterModules

/// 实验室目录的分组。跟编辑面同一份模块清单，不另开名单。
enum DashboardLabSection: String, CaseIterable, Identifiable {
    case hero
    case attention
    case optional

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .hero: L("英雄区")
        case .attention: L("需要注意")
        case .optional: L("可选项")
        }
    }

    var ids: [DashboardModuleID] {
        DashboardModuleID.defaultOrder.filter { Self.section(for: $0) == self }
    }

    static func section(for id: DashboardModuleID) -> DashboardLabSection {
        if id.isPinned || id.isFixedSlot { return .hero }
        if id.isAttention { return .attention }
        return .optional
    }
}
#endif
