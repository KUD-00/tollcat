import Foundation
import MeterDashboard

/// 模块在界面上的名字、说明和图标。只给 SwiftUI 用（`LocalizedStringResource`、SF Symbol），
/// 所以住在视图层；模块本身（id、开关规则）在 MeterDashboard，桥上也编得过。
public extension DashboardModuleID {
    /// 编辑列表里的名字。也是宽壳卡的小标题。
    var title: LocalizedStringResource {
        switch self {
        case .monthToDate: L("本月合计")
        case .composition: L("构成")
        case .anomaly: L("异常")
        case .balanceAlert: L("余额告急")
        case .upcomingCharges: L("即将扣款")
        case .freeQuota: L("免费额度")
        case .services: L("特别关心")
        case .subscriptions: L("固定订阅")
        case .heatmap: L("日历热力图")
        case .categories: L("按类别构成")
        case .superlatives: L("本月之最")
        case .budget: L("预算线")
        }
    }

    /// 编辑列表里一句话说明这块回答什么。
    var summary: LocalizedStringResource {
        switch self {
        case .monthToDate: L("始终在最上面。")
        case .composition: L("钱花在哪几家，附较上月同期和近几个月。")
        case .anomaly: L("哪家比上月同期涨得反常。")
        case .balanceAlert: L("预充值的余额还能用几天。")
        case .upcomingCharges: L("几天后要扣一笔什么钱。")
        case .freeQuota: L("免费额度用了几成。")
        case .services: L("盯住几家，各自的金额和这一个月的日线。")
        case .subscriptions: L("固定订阅折算每月多少，下一笔什么时候。")
        case .heatmap: L("哪天花得多，一格一天。")
        case .categories: L("按 AI 推理、托管、数据库这样的类别分。")
        case .superlatives: L("涨得最多、占比最大、最久没刷新的那家。")
        case .budget: L("本月花了预算的几成。")
        }
    }

    var systemImage: String {
        switch self {
        case .monthToDate: "sum"
        case .composition: "chart.pie"
        case .anomaly: "exclamationmark.triangle"
        case .balanceAlert: "battery.25percent"
        case .upcomingCharges: "calendar.badge.clock"
        case .freeQuota: "gauge.with.dots.needle.33percent"
        case .services: "pin"
        case .subscriptions: "repeat"
        case .heatmap: "calendar"
        case .categories: "square.grid.2x2"
        case .superlatives: "trophy"
        case .budget: "target"
        }
    }
}
