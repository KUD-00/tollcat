import Foundation

/// 一条更新说明是给哪几班车写的。
///
/// `android` / `windows` 在 Swift 侧永远不会是 `current`——它们是别的端在读同一份
/// `shared/changelog.json`。留在枚举里是因为数据要一份，不能每端删一半。
enum WhatsNewPlatform: String, CaseIterable, Hashable, Sendable {
    case ios
    case mac
    case android
    case windows

    /// 这个壳属于哪一班车。iPhone 和 iPad 是同一份（`ios`），Mac 单独一班。
    static var current: WhatsNewPlatform {
        #if os(macOS)
        .mac
        #else
        .ios
        #endif
    }
}
