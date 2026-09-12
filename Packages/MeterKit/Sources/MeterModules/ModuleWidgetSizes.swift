// GENERATED — 由 scripts/generate-shared.py 从 shared/widgets.json 生成。
// 不要手改：改 shared/widgets.json 后重跑生成器。


import CoreGraphics

/// 小组件的尺寸。和 WidgetKit 的 `WidgetFamily` 一一对应，但**不是它**：
/// MeterModules 不链 WidgetKit——模块这一层不该认识宿主框架。
/// 映射在 widget 壳里做（`TollCatWidgetBundle.swift`，生成物）。
public enum ModuleWidgetSize: String, CaseIterable, Sendable {
    /// 2×2。窄且矮：一个数加一行小字就满了。
    case small
    /// 4×2。比 small 宽，但一样矮。
    case medium
    /// 4×4。和 medium 一样宽，高 2 倍多。
    case large
}

public extension DashboardModuleID {
    /// 这块模块提供哪几种小组件尺寸。空 = 主屏上没有它。
    ///
    /// 判据是**装不装得下**，不是重不重要：给一个装不下的尺寸，
    /// 用户拿到的是被裁掉半行的东西，比没有更糟。理由写在 `shared/widgets.json`。
    var widgetSizes: [ModuleWidgetSize] {
        switch self {
        case .monthToDate: [.small, .medium]
        case .composition: [.medium]
        case .anomaly: []
        case .balanceAlert: []
        case .upcomingCharges: []
        case .freeQuota: []
        case .services: [.medium, .large]
        case .subscriptions: [.medium, .large]
        case .heatmap: [.small]
        case .categories: [.large]
        case .superlatives: []
        case .budget: [.small, .medium]
        }
    }

    /// 主屏上有没有它。
    var hasWidget: Bool { !widgetSizes.isEmpty }

    /// widget 里要不要在左上角写模块名。
    /// 自己带标题、或者一眼就认得出的（圆环、格子图）不写——那行字只是把内容往下挤。
    var widgetShowsTitle: Bool {
        switch self {
        case .monthToDate: true
        case .composition: false
        case .anomaly: false
        case .balanceAlert: false
        case .upcomingCharges: false
        case .freeQuota: false
        case .services: true
        case .subscriptions: true
        case .heatmap: false
        case .categories: true
        case .superlatives: false
        case .budget: true
        }
    }

    /// 有小组件的模块，按版式顺序。图库里就是这几行。
    static var widgetModules: [DashboardModuleID] { defaultOrder.filter(\.hasWidget) }
}

/// 一格小组件长在哪种机器上。**手机和 iPad 的一格不一样大**，
/// iPad 的 4×4 还是正方的——同一块模块在两边会落到不同的高度档。
public enum ModuleWidgetIdiom: String, CaseIterable, Sendable {
    /// 6.9" iPhone。
    case phone
    /// 11" iPad Pro。
    case pad
}

public extension ModuleWidgetSize {
    /// 一格在主屏上占多大（pt）。数在 `shared/widgets.json` 的 frames 里，
    /// 商店宣传图的主屏 mock-up 读的是同一份——图上那一格和用户装到主屏上的
    /// 那一格必须是同一个尺寸。
    func frameSize(_ idiom: ModuleWidgetIdiom) -> CGSize {
        switch (idiom, self) {
        case (.phone, .small): CGSize(width: 170, height: 170)
        case (.phone, .medium): CGSize(width: 364, height: 170)
        case (.phone, .large): CGSize(width: 364, height: 382)
        case (.pad, .small): CGSize(width: 155, height: 155)
        case (.pad, .medium): CGSize(width: 342, height: 155)
        case (.pad, .large): CGSize(width: 342, height: 342)
        }
    }

    /// WidgetKit 默认给内容留的边距。
    static let contentMargin: CGFloat = 16

    /// 主屏上那一格的圆角。渲图时用不到——底材是 mock-up 那一层画的。
    static let cornerRadius: CGFloat = 24

    /// 模块实际拿到的那块地方：`frameSize` 扣掉两边内容边距。
    func contentSize(_ idiom: ModuleWidgetIdiom) -> CGSize {
        let frame = frameSize(idiom)
        return CGSize(
            width: frame.width - 2 * Self.contentMargin,
            height: frame.height - 2 * Self.contentMargin
        )
    }
}
