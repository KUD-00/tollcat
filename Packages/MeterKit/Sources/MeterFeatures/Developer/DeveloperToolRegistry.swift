#if DEBUG
import SwiftUI

/// 开发层工具注册表。加一项只改这里，再加一个 View 文件。
enum DeveloperToolID: String, CaseIterable, Identifiable, Hashable {
    case gallery
    case dashboardLab
    case clock
    case whatsNew
    case data
    case refreshLog
    case buildInfo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gallery: String(localized: L("组件画廊"))
        case .dashboardLab: String(localized: L("仪表盘实验室"))
        case .clock: String(localized: L("时间覆盖"))
        case .whatsNew: String(localized: L("更新说明"))
        case .data: String(localized: L("数据操作"))
        case .refreshLog: String(localized: L("调试日志"))
        case .buildInfo: String(localized: L("构建信息"))
        }
    }

    var systemImage: String {
        switch self {
        case .gallery: "square.grid.2x2"
        case .dashboardLab: "rectangle.3.group"
        case .clock: "calendar.badge.clock"
        case .whatsNew: "sparkles.rectangle.stack"
        case .data: "externaldrive"
        case .refreshLog: "list.bullet.rectangle"
        case .buildInfo: "info.circle"
        }
    }

    var section: DeveloperToolSection {
        switch self {
        case .gallery, .dashboardLab: .gallery
        case .clock, .whatsNew: .runtime
        case .data, .refreshLog: .data
        case .buildInfo: .build
        }
    }
}

enum DeveloperToolSection: String, CaseIterable, Identifiable {
    case gallery
    case runtime
    case data
    case build

    var id: String { rawValue }

    var title: String? {
        switch self {
        case .gallery: nil
        case .runtime: String(localized: L("运行时"))
        case .data: String(localized: L("数据"))
        case .build: String(localized: L("这次构建"))
        }
    }

    var items: [DeveloperToolID] {
        DeveloperToolID.allCases.filter { $0.section == self }
    }
}

@MainActor
enum DeveloperToolRegistry {
    @ViewBuilder
    static func view(
        id: DeveloperToolID,
        dashboard: DashboardModel,
        persistenceStatus: PersistenceStatus
    ) -> some View {
        switch id {
        case .gallery:
            ComponentGalleryView()
        case .dashboardLab:
            DeveloperDashboardLabView(dashboard: dashboard)
        case .clock:
            DeveloperClockView(dashboard: dashboard)
        case .whatsNew:
            DeveloperWhatsNewView(dashboard: dashboard)
        case .data:
            DeveloperDataView(dashboard: dashboard, persistenceStatus: persistenceStatus)
        case .refreshLog:
            DeveloperRefreshLogView(dashboard: dashboard)
        case .buildInfo:
            DeveloperBuildInfoView()
        }
    }
}
#endif
