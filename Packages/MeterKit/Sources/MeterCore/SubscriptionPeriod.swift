import Foundation

/// 周期决定金额是每月扣还是一年扣一次，不能从扣款日反推。
public enum SubscriptionPeriod: String, Hashable, Sendable, Codable {
    case monthly
    case annual
}
