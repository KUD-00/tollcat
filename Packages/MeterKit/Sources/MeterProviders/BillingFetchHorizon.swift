import Foundation

/// 取数窗口。仪表刷新只要折得出当前日历月；接入和详情「拉取更多历史」才拉这家肯给的最长一段。
///
/// 每次刷新都拉全年会撞限流，AWS 还会按次收费。窗口必须由调用方选，不能在适配器里擅自拉满。
public enum BillingFetchHorizon: Sendable, Hashable {
    /// 当前日历月，外加刚过去的一个计费周期重叠段。
    case currentMonth
    /// 这家 API 能给的历史。长度看 `ProviderDescriptor.historyLookbackMonths`。
    case availableHistory
}
