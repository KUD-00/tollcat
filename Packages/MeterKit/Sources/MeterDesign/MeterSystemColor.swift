import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// 系统语义色。iOS 的 `Color(.label)` 在 Mac 上编不过——对应物叫 `labelColor`。
/// Features / Widget 一律走这些静态属性，不要再写 `Color(.label)`。
public extension Color {
    static var meterLabel: Color {
        #if os(macOS)
        Color(nsColor: .labelColor)
        #else
        Color(.label)
        #endif
    }

    static var meterSecondaryLabel: Color {
        #if os(macOS)
        Color(nsColor: .secondaryLabelColor)
        #else
        Color(.secondaryLabel)
        #endif
    }

    static var meterTertiaryLabel: Color {
        #if os(macOS)
        Color(nsColor: .tertiaryLabelColor)
        #else
        Color(.tertiaryLabel)
        #endif
    }

    static var meterSeparator: Color {
        #if os(macOS)
        Color(nsColor: .separatorColor)
        #else
        Color(.separator)
        #endif
    }

    /// 画布。Mac 浅色的 `windowBackgroundColor` 和 `controlBackgroundColor`
    /// 是同一块 #FFFFFF（macOS 26 实测）——白卡铺白画布，bento 整个消失，
    /// 和深色「同色卡消失」是镜像问题。浅色压一档灰（对齐 iOS
    /// `systemGroupedBackground` 的 #F2F2F7 画布 + 白卡那层关系），深色仍走窗口底色。
    static var meterGroupedBackground: Color {
        #if os(macOS)
        Color(light: Color(hex: 0xF2F2F7), dark: Color(nsColor: .windowBackgroundColor))
        #else
        Color(.systemGroupedBackground)
        #endif
    }

    /// 卡面。Mac 深色的 `controlBackgroundColor` 和 `windowBackgroundColor`
    /// 是同一块 #1E1E1E——画布统一铺窗口底色之后，同色卡会整张消失。
    /// 深色抬一档灰（对齐 iOS 纯黑画布 + #1C1C1E 卡面那层关系），浅色仍走系统白。
    static var meterSecondaryGroupedBackground: Color {
        #if os(macOS)
        Color(light: Color(nsColor: .controlBackgroundColor), dark: Color(hex: 0x2C2C2E))
        #else
        Color(.secondarySystemGroupedBackground)
        #endif
    }

    static var meterSystemGray: Color {
        #if os(macOS)
        Color(nsColor: .systemGray)
        #else
        Color(.systemGray)
        #endif
    }

    static var meterSystemGray2: Color {
        #if os(macOS)
        Color(nsColor: NSColor.systemGray.blended(withFraction: 0.18, of: .white) ?? .systemGray)
        #else
        Color(.systemGray2)
        #endif
    }

    static var meterSystemGray3: Color {
        #if os(macOS)
        Color(nsColor: NSColor.systemGray.blended(withFraction: 0.36, of: .white) ?? .systemGray)
        #else
        Color(.systemGray3)
        #endif
    }

    static var meterSystemGray4: Color {
        #if os(macOS)
        Color(nsColor: NSColor.separatorColor)
        #else
        Color(.systemGray4)
        #endif
    }

    static var meterSecondarySystemBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(.secondarySystemBackground)
        #endif
    }

    static var meterTertiarySystemFill: Color {
        #if os(macOS)
        Color(nsColor: .quaternaryLabelColor)
        #else
        Color(.tertiarySystemFill)
        #endif
    }
}
