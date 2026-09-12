import Foundation

/// 动效循环。和图层无关：睡觉的身体也可以播吓到那一套。
public enum CatMotionKind: String, CaseIterable, Sendable, Hashable {
    /// 眨眼、视线、带着惯性的嘴、摆尾。身体不压扁。
    case idle
    /// 摆尾、ZZZ 上浮。
    case sleeping
    /// 绷直、颤抖。
    case shocked
    /// 完全不动。
    case still

    public init(_ mood: CatMood) {
        switch mood {
        case .normal, .saved, .alert, .awkward:
            self = .idle
        case .sleeping:
            self = .sleeping
        case .shocked:
            self = .shocked
        case .dead:
            self = .still
        }
    }
}
