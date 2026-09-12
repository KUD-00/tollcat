import SwiftUI

/// 猫的命名表情。和 `MeterCore.CatMood` 一一对应，本模块不认识账单。
public enum CatMood: String, CaseIterable, Sendable, Hashable {
    case normal
    case sleeping
    case saved
    case alert
    case shocked
    case awkward
    case dead

    public var parts: CatParts { CatParts(self) }

    public var motion: CatMotionKind { CatMotionKind(self) }

    public var accessibilityLabel: LocalizedStringResource {
        switch self {
        case .normal:
            L("猫猫看起来一切正常")
        case .sleeping:
            L("猫猫在睡觉，还没有账单数据")
        case .saved:
            L("猫猫很高兴，这个月比上个月省了")
        case .alert:
            L("猫猫有点紧张，有余额告急或异常")
        case .shocked:
            L("猫猫吓到了，账单涨得很快")
        case .awkward:
            L("猫猫有点尴尬，显示的是陈旧数据")
        case .dead:
            L("猫猫被账单送走了，这个月涨了一倍以上")
        }
    }
}
