import Foundation
import MeterCore

/// 仪表模块。第一块永远是本月合计，其余由用户在「编辑」里开关、排序，
/// 顺序落在 `DashboardLayout.order`；没数据的模块仍然自动不出现。
public enum DashboardModuleID: String, CaseIterable, Identifiable, Sendable, Hashable {
    case monthToDate
    case composition
    case anomaly
    case balanceAlert
    case upcomingCharges
    case freeQuota
    /// 钉出来的几家服务，每家一行 / 一张卡：金额、较上月、迷你走势。
    case services
    /// 固定订阅折算每月，附下一笔什么时候扣。
    case subscriptions
    /// 日历热力图，哪天花得多一眼看出来，可翻到有数据的月份。
    case heatmap
    /// 按类别构成：AI 推理 / 托管 / 数据库…… 一条构成条加图例。
    case categories
    /// 之最：涨得最多、占比最大、最久没刷新。节标题跟着期间走。
    case superlatives
    /// 预算线：本月花了预算的几成。
    case budget

    public var id: String { rawValue }

    /// SPEC 第 04 节：第一块永远是本月合计，不进编辑列表。
    public var isPinned: Bool { self == .monthToDate }

    /// 位置不由顺序决定的模块：构成画在英雄区（手机是猫台下面那半张，宽壳是
    /// bento 第一张卡），怎么排都在那儿。所以它在清单里也永远紧跟本月合计，
    /// 编辑面照着这份清单画——不给一个拖了不动的手柄。开关照常。
    public var isFixedSlot: Bool { self == .composition }

    /// 暂时下架的模块：case 留着（旧版式里存过它的 id，`shared/widgets.json`
    /// 也要求每块模块都表态），但既不进仪表盘也不进编辑面。
    /// 判据只有一处，在 `DashboardModuleThresholds`。
    public var isRetired: Bool {
        switch self {
        case .upcomingCharges: !DashboardModuleThresholds.showsUpcomingCharges
        default: false
        }
    }

    /// SPEC 第 05 节表格顺序。本月合计永远默认第一。
    public static let defaultOrder: [DashboardModuleID] = [
        .monthToDate, .composition, .anomaly, .balanceAlert, .upcomingCharges, .freeQuota,
        .services, .subscriptions, .heatmap, .categories, .superlatives, .budget,
    ]

    /// 新装 App 就开着的模块。后加的七个是可选项，用户在「编辑」里自己加。
    public var isOnByDefault: Bool {
        switch self {
        case .monthToDate, .composition, .anomaly, .balanceAlert, .upcomingCharges, .freeQuota:
            true
        case .services, .subscriptions, .heatmap, .categories, .superlatives, .budget:
            false
        }
    }

    /// 「需要注意」那一组：手机上相邻的几块并成同一节，卡上各自成卡。
    public var isAttention: Bool {
        switch self {
        case .anomaly, .balanceAlert, .upcomingCharges, .freeQuota: true
        default: false
        }
    }

    /// 能钉到侧栏底部的：一格宽的那些。本月合计和构成留在主区。
    public var canSitInSidebar: Bool {
        !isPinned && self != .composition
    }

    /// 只在本月才有意义的模块：回看过去月份时不建内容（和 `filter.showsPresentTenseModules` 同一条）。
    public var isPresentTenseOnly: Bool {
        switch self {
        case .balanceAlert, .upcomingCharges, .freeQuota, .budget: true
        default: false
        }
    }

    /// 编辑列表里的名字。也是宽壳卡的小标题。
    public var title: LocalizedStringResource {
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
    public var summary: LocalizedStringResource {
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

    public var systemImage: String {
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

    /// 版式里存的是字符串，落到枚举；不认识的 id（比旧版本新的模块）跳过，
    /// 下架的模块（`isRetired`）也跳过——旧版式里存着它也不再出现。
    /// 定槽的模块（`isFixedSlot`）提到最前：它画在英雄区，顺序说了不算。
    public static func resolvedOrder(from layout: DashboardLayout) -> [DashboardModuleID] {
        let stored = layout.order.compactMap(DashboardModuleID.init(rawValue:))
        let enabled = stored.isEmpty ? defaultOrder.filter(\.isOnByDefault) : stored
        let visible = enabled.filter { !$0.isPinned && !$0.isRetired }
        return [.monthToDate] + visible.filter(\.isFixedSlot) + visible.filter { !$0.isFixedSlot }
    }

    /// 编辑面的候选：除本月合计和下架的以外的全部，开着的按版式顺序在前，
    /// 关着的按默认顺序在后。
    public static func editableOrder(from layout: DashboardLayout) -> [DashboardModuleID] {
        let enabled = resolvedOrder(from: layout).filter { !$0.isPinned }
        let disabled = defaultOrder.filter { !$0.isPinned && !$0.isRetired && !enabled.contains($0) }
        return enabled + disabled
    }
}
