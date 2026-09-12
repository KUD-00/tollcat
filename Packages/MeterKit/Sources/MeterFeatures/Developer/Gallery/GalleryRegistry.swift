#if DEBUG
import SwiftUI

/// 画廊条目注册表。加一组状态只改这里，再加一个 View 文件。
enum GalleryItemID: String, CaseIterable, Identifiable, Hashable {
    case empty
    case errors
    case amounts
    case composition
    case comparison
    case charts
    case attention
    case overflow
    case glyphs
    case rows
    case cats
    case setupGuides
    case usageGuides
    case verifyConnection
    case refresh
    case credentialFields
    case tips
    case monthRange

    var id: String { rawValue }

    var title: String {
        switch self {
        case .empty: String(localized: L("空态"))
        case .errors: String(localized: L("错误态"))
        case .amounts: String(localized: L("金额"))
        case .composition: String(localized: L("构成"))
        case .comparison: String(localized: L("较上月同期"))
        case .charts: String(localized: L("图表"))
        case .attention: String(localized: L("需要注意"))
        case .overflow: String(localized: L("超长名称"))
        case .glyphs: "ProviderGlyph"
        case .rows: String(localized: L("列表行"))
        case .cats: String(localized: L("猫猫"))
        case .setupGuides: String(localized: L("接入向导"))
        case .usageGuides: String(localized: L("使用指南"))
        case .verifyConnection: String(localized: L("测试连接"))
        case .refresh: String(localized: L("刷新按钮"))
        case .credentialFields: String(localized: L("凭据输入"))
        case .tips: String(localized: L("打赏"))
        case .monthRange: String(localized: L("月份区间"))
        }
    }

    var section: GallerySection {
        switch self {
        case .empty: .empty
        case .errors: .errors
        case .amounts, .composition, .comparison, .charts, .attention, .overflow: .boundaries
        case .glyphs, .rows, .cats, .setupGuides, .usageGuides, .verifyConnection, .refresh, .credentialFields, .tips, .monthRange: .components
        }
    }
}

enum GallerySection: String, CaseIterable, Identifiable {
    case empty
    case errors
    case boundaries
    case components

    var id: String { rawValue }

    var title: String {
        switch self {
        case .empty: String(localized: L("空态"))
        case .errors: String(localized: L("错误态"))
        case .boundaries: String(localized: L("数据边界"))
        case .components: String(localized: L("组件"))
        }
    }

    var items: [GalleryItemID] {
        GalleryItemID.allCases.filter { $0.section == self }
    }
}

@MainActor
enum GalleryRegistry {
    @ViewBuilder
    static func view(id: GalleryItemID) -> some View {
        switch id {
        case .empty: GalleryEmptyStatesView()
        case .errors: GalleryErrorStatesView()
        case .amounts: GalleryAmountStatesView()
        case .composition: GalleryCompositionStatesView()
        case .comparison: GalleryComparisonStatesView()
        case .charts: GalleryChartStatesView()
        case .attention: GalleryAttentionStatesView()
        case .overflow: GalleryOverflowStatesView()
        case .glyphs: GalleryGlyphStatesView()
        case .rows: GalleryRowStatesView()
        case .cats: GalleryCatStatesView()
        case .setupGuides: GallerySetupGuidesView()
        case .usageGuides: GalleryUsageGuidesView()
        case .verifyConnection: GalleryVerifyConnectionView()
        case .refresh: GalleryRefreshView()
        case .credentialFields: GalleryCredentialFieldsView()
        case .tips: GalleryTipStatesView()
        case .monthRange: GalleryMonthRangeView()
        }
    }
}
#endif
