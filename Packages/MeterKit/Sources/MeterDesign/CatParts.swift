import Foundation

/// 一只猫的图层组合。命名表情是它的预设；画廊可以拆开拧。
public struct CatParts: Equatable, Sendable, Hashable {
    public var eyes: CatEyes
    public var mouth: CatMouth
    public var accessory: CatAccessory
    public var isUpsideDown: Bool
    public var wearsGlasses: Bool

    public init(
        eyes: CatEyes = .normal,
        mouth: CatMouth = .neutral,
        accessory: CatAccessory = .none,
        isUpsideDown: Bool = false,
        wearsGlasses: Bool = false
    ) {
        self.eyes = eyes
        self.mouth = mouth
        self.accessory = accessory
        self.isUpsideDown = isUpsideDown
        self.wearsGlasses = wearsGlasses
    }

    public init(_ mood: CatMood) {
        switch mood {
        case .normal:
            self.init(eyes: .normal, mouth: .neutral)
        case .sleeping:
            self.init(eyes: .closed, mouth: .none, accessory: .zzz)
        case .saved:
            self.init(eyes: .sparkle, mouth: .smallO)
        case .alert:
            self.init(eyes: .alert, mouth: .flat)
        case .shocked:
            self.init(eyes: .normal, mouth: .o, accessory: .bang)
        case .awkward:
            self.init(eyes: .normal, mouth: .wave)
        case .dead:
            self.init(eyes: .x, mouth: .o, accessory: .skull, isUpsideDown: true)
        }
    }
}
