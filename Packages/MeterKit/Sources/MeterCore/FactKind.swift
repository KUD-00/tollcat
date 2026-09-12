import Foundation

/// 事实类型用枚举而不是句子，措辞留给展示层。
public enum FactKind: String, Hashable, Sendable, Codable, CaseIterable {
    /// 本月用量
    case monthToDateUsage
    /// 余额消耗
    case prepaidConsumption
    /// 订阅计入
    case subscriptionIncluded
    /// API 订阅被同 provider 的手动录入取代，金额是被忽略的那笔
    case subscriptionSuperseded
    /// 免费额度
    case freeQuota
    /// 取数失败
    case fetchFailed
}
