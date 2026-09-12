import Foundation
import MeterCore

struct ServiceRowItem: Identifiable, Equatable, Sendable {
    var id: ProviderID
    var providerID: ProviderID { id }
    var kind: ProviderKind
    /// 这家干什么活。标在服务目录里，展示层不猜。
    var category: ProviderCategory
    var nickname: String?
    var displayName: String
    var spokenName: String
    var colorKey: String
    var value: String
    var spokenValue: String
    var subtitle: String?
    var usesSecondaryValue: Bool
    var isConnected: Bool
    var isStale: Bool
    var valueCaption: String?
    var amountValue: Double
    var supersededByManual: Bool
    /// 这家已经结束了：没有在跑的用量，也没有还在付的订阅，但留着历史。
    /// 服务页据此把它挪进「历史服务」那一节。
    var isEnded: Bool = false
}
