import Foundation
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// 程序化写入剪贴板。iOS 26 仍然没有对等的 SwiftUI API（`CopyButton` 只在 Mac）。
enum SystemClipboard {
    static var string: String? {
        #if os(macOS)
        NSPasteboard.general.string(forType: .string)
        #else
        UIPasteboard.general.string
        #endif
    }

    static func copy(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
    }

    static func copyPNG(_ data: Data) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setData(data, forType: .png)
        #else
        UIPasteboard.general.setData(data, forPasteboardType: UTType.png.identifier)
        #endif
    }
}
