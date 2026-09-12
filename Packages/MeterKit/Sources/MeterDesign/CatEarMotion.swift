import Foundation

/// 耳朵动效。生产界面默认钉住；画廊可以打开试。
public enum CatEarMotion: String, CaseIterable, Sendable, Hashable {
    /// 0 度，和静帧剪影一致。
    case still
    /// 左右不同步的轻晃，偶尔弹一下。
    case twitch
}
