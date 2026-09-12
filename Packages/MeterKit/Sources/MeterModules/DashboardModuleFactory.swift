import SwiftUI
import MeterCore
import MeterDesign

/// 容器只认 id 和一份内容。**仪表盘、分享卡、widget 全走这一个 switch**——
/// 三个壳各写一份「这个 id 画什么」，就是三份会各自漂的清单。
///
/// 加模块：`DashboardModuleID` 加一个 case，编译器会在这里和
/// `DashboardModuleContents.has(_:)` 两处点名，漏一处都编译不过。
@MainActor
public enum DashboardModuleFactory {
    @ViewBuilder
    public static func view(
        id: DashboardModuleID,
        contents: some DashboardModuleContents
    ) -> some View {
        switch id {
        case .monthToDate:
            if let content = contents.monthToDateContent {
                MonthToDateModuleView(content: content)
            }
        case .composition:
            if let content = contents.compositionContent {
                CompositionModuleView(content: content)
            }
        case .anomaly:
            if let content = contents.anomalyContent {
                AnomalyModuleView(content: content)
            }
        case .balanceAlert:
            if let content = contents.balanceAlertContent {
                BalanceAlertModuleView(content: content)
            }
        case .upcomingCharges:
            if let content = contents.upcomingChargesContent {
                UpcomingChargesModuleView(content: content)
            }
        case .freeQuota:
            if let content = contents.freeQuotaContent {
                FreeQuotaModuleView(content: content)
            }
        case .services:
            if let content = contents.servicesContent {
                ServicesModuleView(content: content)
            }
        case .subscriptions:
            if let content = contents.subscriptionsContent {
                SubscriptionsModuleView(content: content)
            }
        case .heatmap:
            if let content = contents.heatmapContent {
                HeatmapModuleView(content: content)
            }
        case .categories:
            if let content = contents.categoriesContent {
                CategoriesModuleView(content: content)
            }
        case .superlatives:
            if let content = contents.superlativesContent {
                SuperlativesModuleView(content: content)
            }
        case .budget:
            if let content = contents.budgetContent {
                BudgetModuleView(content: content)
            }
        }
    }
}
