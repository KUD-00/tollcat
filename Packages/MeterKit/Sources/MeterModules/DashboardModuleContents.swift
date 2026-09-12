import Foundation

/// 「这一块有没有内容」。
///
/// 仪表盘（`DashboardModel`）和 widget / 分享卡（`DashboardContents`）各有各的存法——
/// 前者把 14 个字段分开存，是为了 `@Observable` 的细粒度失效：刷新只动了热力图，
/// 不该把整页都标脏。但**「有哪些模块可摆」这件事只许有一份判断**，
/// 否则 widget 能选的模块和仪表盘能开的模块迟早对不上。
///
/// 所以两边都实现这个协议，模块清单（`availableModuleIDs`）和模块工厂
/// （`DashboardModuleFactory`）都只认它。加一块模块要改的地方仍然是那几处，
/// 但**不会漏掉 widget**——漏了就编译不过。
public protocol DashboardModuleContents {
    var monthToDateContent: MonthToDateModuleContent? { get }
    var compositionContent: CompositionModuleContent? { get }
    var comparisonContent: ComparisonModuleContent? { get }
    var trendContent: TrendModuleContent? { get }
    var anomalyContent: AnomalyModuleContent? { get }
    var balanceAlertContent: BalanceAlertModuleContent? { get }
    var upcomingChargesContent: UpcomingChargesModuleContent? { get }
    var freeQuotaContent: FreeQuotaModuleContent? { get }
    var servicesContent: ServicesModuleContent? { get }
    var subscriptionsContent: SubscriptionsModuleContent? { get }
    var heatmapContent: HeatmapModuleContent? { get }
    var categoriesContent: CategoriesModuleContent? { get }
    var superlativesContent: SuperlativesModuleContent? { get }
    var budgetContent: BudgetModuleContent? { get }
}

public extension DashboardModuleContents {
    /// 有数据、因而**可以**出现的模块。没数据的模块自动不出现，
    /// 和用户在「编辑」里开没开是两回事（那是 `DashboardLayout`）。
    ///
    /// 只读用得着的那一个字段——`DashboardModel` 上是 `@Observable`，
    /// 这里逐个读会把整页都订上，所以调用方要么一次性算清单，要么用
    /// `has(_:)` 只问一块。
    var availableModuleIDs: Set<DashboardModuleID> {
        Set(DashboardModuleID.allCases.filter { has($0) })
    }

    /// 这一块有没有内容。**加模块时这个 switch 编译器会替你点名。**
    func has(_ id: DashboardModuleID) -> Bool {
        switch id {
        case .monthToDate: monthToDateContent != nil
        case .composition: compositionContent != nil
        case .anomaly: anomalyContent != nil
        case .balanceAlert: balanceAlertContent != nil
        case .upcomingCharges: upcomingChargesContent != nil
        case .freeQuota: freeQuotaContent != nil
        case .services: servicesContent != nil
        case .subscriptions: subscriptionsContent != nil
        case .heatmap: heatmapContent != nil
        case .categories: categoriesContent != nil
        case .superlatives: superlativesContent != nil
        case .budget: budgetContent != nil
        }
    }
}
