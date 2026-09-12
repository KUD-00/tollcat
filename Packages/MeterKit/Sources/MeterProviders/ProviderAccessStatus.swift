import Foundation

/// 这家能不能进 v1，是编译期就知道的事实，不是一次 fetch 的结果。
public enum ProviderAccessStatus: String, Hashable, Sendable, Codable {
    case available
    /// 拿不到可对账的官方金额：接口未核实、账号前提不够，或核实后没有账单字段。
    case pendingVerification
    /// 已核实接不上。目录里留身份、图标和理由；iOS / Android / 落地页的产品列表都滤掉。
    case declined
}
