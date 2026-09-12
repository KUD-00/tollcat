import Foundation

/// 眼睛图层。生产界面由命名表情选用，画廊可以单独拧。
public enum CatEyes: String, CaseIterable, Sendable, Hashable {
    case normal
    case closed
    case sparkle
    case alert
    case x

    var canBlink: Bool {
        switch self {
        case .normal, .sparkle, .alert:
            true
        case .closed, .x:
            false
        }
    }
}
