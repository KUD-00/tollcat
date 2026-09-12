import Foundation

/// 这家在所属品类里的市占位置。目录里每家标一个，不在展示层猜。
///
/// 判定相对的是 `ProviderCategory` 对应的产品市场，不是公司全球规模。
/// 理由写在 `ProviderDescriptor.tierReason`，给人读，不进 String Catalog。
public enum ProviderTier: Int, Hashable, Sendable, Codable, Comparable, CaseIterable {
    /// 绝对垄断，或和其他几家几分天下
    case one = 1
    /// 强有力的业界挑战者
    case two = 2
    /// 规模较小但未来可期
    case three = 3
    /// 规模较小但持续下滑
    case four = 4

    public static func < (lhs: ProviderTier, rhs: ProviderTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
