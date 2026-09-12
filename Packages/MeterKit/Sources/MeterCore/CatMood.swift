import Foundation

/// 猫的表情。由账单数据决定，不是展示层随便搭配。
public enum CatMood: String, CaseIterable, Sendable, Hashable {
    case normal
    case sleeping
    case saved
    case alert
    case shocked
    case awkward
    case dead
}
