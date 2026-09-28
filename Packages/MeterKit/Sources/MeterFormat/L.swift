import Foundation

/// 这个 target 的用户可见文案，四个平台都能编（见 `PortableText`）。
/// 桥上设了 `PortableLocale.languageTag` 时查生成的 `MeterFormatCopy` 表，否则走 String Catalog。
func L(_ text: PortableText) -> String {
    MeterFormatCopy.catalog.resolve(text)
}

#if canImport(Darwin)
/// 交给 SwiftUI `Text` 的那一种：要 `LocalizedStringResource`，只在 Apple 平台有。
/// `Text("…")` 默认查 `Bundle.main`，SPM 模块会静默回落成 key，所以带上本模块的 bundle。
func LR(_ key: String.LocalizationValue) -> LocalizedStringResource {
    LocalizedStringResource(key, bundle: .atURL(Bundle.module.bundleURL))
}

/// Widget 这类薄壳没有自己的 catalog，模块外拿这份 catalog 的资源走这里。
public enum MeterFormatText {
    public static func resource(_ key: String.LocalizationValue) -> LocalizedStringResource {
        LR(key)
    }
}
#endif
