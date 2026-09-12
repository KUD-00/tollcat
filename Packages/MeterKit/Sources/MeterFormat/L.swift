import Foundation

// Android 的 swift-foundation 没有 LocalizedStringResource，这个文件不进 .so。
#if !os(Android)
/// 用户可见文案走这里。`Text("…")` 默认查 `Bundle.main`，SPM 模块会静默回落成 key。
func L(_ key: String.LocalizationValue) -> LocalizedStringResource {
    LocalizedStringResource(key, bundle: .atURL(Bundle.module.bundleURL))
}

/// Widget 这类薄壳没有自己的 catalog，模块外拿这份 catalog 的资源走这里。
public enum MeterFormatText {
    public static func resource(_ key: String.LocalizationValue) -> LocalizedStringResource {
        L(key)
    }
}
#endif
