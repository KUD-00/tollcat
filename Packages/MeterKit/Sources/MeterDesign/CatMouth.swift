import Foundation

/// 嘴图层。`smallO` 是省到了那只小圆嘴，`o` 是吓到 / 翻肚皮的大张嘴。
public enum CatMouth: String, CaseIterable, Sendable, Hashable {
    case none
    case neutral
    case smile
    case flat
    case smallO
    case o
    case wave
}
