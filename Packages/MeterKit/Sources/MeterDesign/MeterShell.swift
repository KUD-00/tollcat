import SwiftUI

/// 现在是哪一种壳。**「Mac 吗」和「宽版式吗」是两个问题。**
///
/// 以前只有一个 `usesPadChrome: Bool`，Mac 恒 true。于是：
///
/// - 想说「宽版式」的地方读它，对；
/// - 想说「**只有 Mac**」的地方读不出来，只能写 `#if os(macOS)`。
///
/// 一个纯粹的版式选择（Mac 上换一句话、换一个预览图）就这样变成编译期分叉，
/// 而编译期分叉的代价是：另一边的代码**根本不编译**，改错了要等切平台才知道，
/// 预览也没法在一份文件里同时看两种。29 个文件 107 处 `usesPadChrome`
/// 加 20 个文件 37 处 `#if os` 就是这么攒出来的。
///
/// 现在壳是一个值：想问哪一个问哪一个。
///
/// ## `#if os` 什么时候仍然是对的
///
/// **只有 API 可用性。**`NSPasteboard` / `SMAppService` / `UIPageControl` /
/// `.tabBarMinimizeBehavior` 在另一边根本不存在，运行时判断救不了编译。
/// 这类 `#if os` 留着，而且应该越集中越好（`SystemClipboard`、`LoginItem`
/// 这种一个文件包一层）。
///
/// 剩下的——「Mac 上这句话不一样」「Mac 上不画这个标题」——一律走 `MeterShell`。
public enum MeterShell: String, Sendable, Hashable, CaseIterable {
    /// iPhone，以及 iPad 上竖屏 / 窄分屏。
    case phone
    /// iPad 横屏且宽度 regular。
    case pad
    /// 原生 Mac 壳。
    case mac

    /// 用 iPad / Mac 那套宽版式：分栏、popover、可读宽度收窄。
    ///
    /// 这是原来那个 `usesPadChrome` 的语义，一个字没变——**它现在是派生的**，
    /// 只有一个出处。
    public var usesWideChrome: Bool { self != .phone }

    /// 这台机器上壳的下限。iOS 上还要看尺寸类和横竖屏才知道是 `.phone` 还是 `.pad`，
    /// Mac 上没有第二种可能。
    public static var platformDefault: MeterShell {
        #if os(macOS)
        .mac
        #else
        .phone
        #endif
    }
}

private struct MeterShellKey: EnvironmentKey {
    static let defaultValue = MeterShell.platformDefault
}

extension EnvironmentValues {
    public var meterShell: MeterShell {
        get { self[MeterShellKey.self] }
        set { self[MeterShellKey.self] = newValue }
    }

    /// 宽版式与否。**只读派生**：要改壳就设 `meterShell`，别在两处各存一份。
    public var usesPadChrome: Bool { meterShell.usesWideChrome }
}
