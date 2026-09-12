import Foundation
import MeterCore

/// 仪表 `NavigationStack` 的去处。构成页、对比页和账号详情共用这一条路。
public enum DashboardRoute: Hashable {
    case composition
    case comparison
    case account(AccountID)
    /// 没有账号可推进的段（挂厂商的无主订阅）走这条：详情页本来就按厂商开，
    /// 仅订阅的家也有订阅节可看。
    case provider(ProviderID)
    /// 「固定订阅」整块点进去：全部订阅一页，每笔再进各家详情。
    case subscriptions
    /// 「日历热力图」整块点进去：有读数的每个月一张日历，一页翻完。
    case heatmap
    /// 「按类别构成」整块点进去：每个类别的金额、占比、含哪几家。
    case categories
}
