#if DEBUG
import Observation
import SwiftUI
import MeterDesign

/// 画廊里拼猫的一份状态。预设会整套覆盖；高级页拆开拧。
@MainActor
@Observable
final class GalleryCatStudio {
    var mood: CatMood
    var parts: CatParts
    var pose: CatMotionFrame
    var motion: CatMotionKind
    var ears: CatEarMotion
    var isAnimated: Bool
    var size: CGFloat

    init(
        mood: CatMood = FeatureLaunchArguments.catMood.flatMap(CatMood.init(rawValue:)) ?? .normal,
        isAnimated: Bool = FeatureLaunchArguments.catMood == nil,
        size: CGFloat = MeterSpacing.catGallery
    ) {
        self.mood = mood
        self.parts = mood.parts
        self.pose = .still(for: mood)
        self.motion = mood.motion
        self.ears = .still
        self.isAnimated = isAnimated
        self.size = size
    }

    func apply(_ mood: CatMood) {
        self.mood = mood
        parts = mood.parts
        pose = .still(for: mood)
        motion = mood.motion
    }

    func cat(size override: CGFloat? = nil, animated: Bool? = nil) -> CatView {
        CatView(
            parts: parts,
            size: override ?? size,
            accessibilityLabel: L("猫猫"),
            isAnimated: animated ?? isAnimated,
            motion: motion,
            pose: pose,
            ears: ears
        )
    }
}

extension CatEyes {
    var galleryTitle: LocalizedStringResource {
        switch self {
        case .normal: L("圆眼")
        case .closed: L("闭眼")
        case .sparkle: L("星眼")
        case .alert: L("吊眼")
        case .x: L("叉眼")
        }
    }
}

extension CatMouth {
    var galleryTitle: LocalizedStringResource {
        switch self {
        case .none: L("没有")
        case .neutral: L("中性")
        case .smile: L("微笑")
        case .flat: L("一字")
        case .smallO: L("小O")
        case .o: L("大O")
        case .wave: L("波浪")
        }
    }
}

extension CatAccessory {
    var galleryTitle: LocalizedStringResource {
        switch self {
        case .none: L("没有")
        case .zzz: L("ZZZ")
        case .bang: L("惊叹号")
        case .skull: L("骷髅")
        }
    }
}

extension CatMotionKind {
    var galleryTitle: LocalizedStringResource {
        switch self {
        case .idle: L("待机")
        case .sleeping: L("睡觉")
        case .shocked: L("吓到")
        case .still: L("静止")
        }
    }
}

extension CatEarMotion {
    var galleryTitle: LocalizedStringResource {
        switch self {
        case .still: L("不动")
        case .twitch: L("会动")
        }
    }
}
#endif
