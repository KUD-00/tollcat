import SwiftUI
import MeterDesign

/// 这台设备此刻是哪一种壳。横屏、regular 宽度才算 iPad 壳；
/// 竖屏、窄分屏、iPhone 一律走手机壳；Mac 没有第二种可能。
///
/// 不能只看 `horizontalSizeClass`：iPad 竖屏也是 `.regular`，和横屏分不出来。
///
/// 判据在这里，值在 `MeterShell`（MeterDesign）。「宽版式与否」是从壳**派生**的
/// （`MeterShell.usesWideChrome`），不再是另一个独立的 Bool——那两样以前
/// 各存一份，于是「只有 Mac」这个问题在展示层根本问不出来，只能写 `#if os`。
enum UsesPadChrome {
    static var platformForcesWideChrome: Bool {
        MeterShell.platformDefault.usesWideChrome
    }

    /// 尺寸类和窗口尺寸决定 iOS 上是手机壳还是 iPad 壳。Mac 直接是 `.mac`。
    static func shell(
        sizeClass: UserInterfaceSizeClass?,
        size: CGSize,
        platform: MeterShell = .platformDefault
    ) -> MeterShell {
        if platform == .mac { return .mac }
        let isWide = sizeClass == .regular && size.width > size.height && size.width > 0
        return isWide ? .pad : .phone
    }

    static func isActive(
        sizeClass: UserInterfaceSizeClass?,
        size: CGSize,
        forcesWideChrome: Bool = platformForcesWideChrome
    ) -> Bool {
        shell(
            sizeClass: sizeClass,
            size: size,
            platform: forcesWideChrome ? .mac : .phone
        ).usesWideChrome
    }

    /// 首帧在 `onGeometryChange` 到来之前用。`.zero` 不会误开 iPad 壳。
    static var initialWindowSize: CGSize { .zero }
}
