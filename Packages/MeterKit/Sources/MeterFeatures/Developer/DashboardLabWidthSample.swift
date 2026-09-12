#if DEBUG
import CoreGraphics
import Foundation
import MeterDesign
import MeterModules

/// 宽壳卡要看的四档宽度。内容宽写死，对着 `ModuleSize` 注释里那些壳——
/// 实验室量自己再回填，就是第一版把主线程转死的那条路。
enum DashboardLabWidthSample: String, CaseIterable, Identifiable {
    case compact
    case regular
    case wide
    case expanded

    var id: String { rawValue }

    var width: ModuleWidth {
        switch self {
        case .compact: .compact
        case .regular: .regular
        case .wide: .wide
        case .expanded: .expanded
        }
    }

    /// 模块拿到的内容宽。卡的左右 `md` 内边距要另加。
    var contentWidth: CGFloat {
        switch self {
        case .compact: 155
        case .regular: 218
        case .wide: 460
        case .expanded: 628
        }
    }

    var outerWidth: CGFloat { contentWidth + MeterSpacing.md * 2 }
    var outerHeight: CGFloat { MeterSpacing.dashboardTileHeight }

    /// `ModuleSize` 注释里 iPhone 列表行约 345。
    static let listContentWidth: CGFloat = 345

    var title: LocalizedStringResource {
        switch self {
        case .compact: L("挤")
        case .regular: L("基准")
        case .wide: L("宽")
        case .expanded: L("很宽")
        }
    }

    var caption: LocalizedStringResource {
        switch self {
        case .compact: L("widget 小格、被挤到 0.75 格的 bento")
        case .regular: L("一格 bento、侧栏卡")
        case .wide: L("Mac 宽窗口的 bento")
        case .expanded: L("外接大屏上的 bento")
        }
    }
}
#endif
