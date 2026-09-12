import Foundation

/// 五种「钱」不能走同一套折算，必须先在类型上拆开。
///
/// `planAndUsage` 是一家服务同时回答两问：固定月费 + 从量超额。
/// 同一笔美元不许同时写进 `committedMonthlyUSD` 和 `currentSpendUSD` / `dailyUSD`。
public enum ProviderKind: String, Hashable, Sendable, Codable {
    case usage
    case prepaid
    case subscription
    case freeTier
    case planAndUsage

    public var contributesUsageComparison: Bool {
        self == .usage || self == .planAndUsage
    }

    /// 手填 / 信箱投递的读数只能落成哪一种 kind。
    ///
    /// 这两条路只有 `currentSpendUSD` 一格（「这个月花了多少」），而
    /// `hasBillableMetrics` 里只有 `.usage` 和 `.planAndUsage` 认这一格。
    /// 照目录的 kind 原样落盘，`.subscription`（Notion / Figma / Slack / Linear）
    /// 那几家会写出一条**永远不算数**的快照：保存成功、无报错、仪表显示 $0
    /// 并把这家标成「取数失败」。
    ///
    /// 所以规则收成一处：能装下 `currentSpendUSD` 的原样留着，别的一律降成
    /// `.usage`。`InboxSnapshotMapper.canRepresent` 是同一份规则的另一种问法。
    public var manualEntryKind: ProviderKind {
        switch self {
        case .usage, .planAndUsage:
            return self
        case .prepaid, .subscription, .freeTier:
            return .usage
        }
    }
}
