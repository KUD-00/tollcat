import Foundation

/// 用户可见文案走这里。`Text("…")` 默认查 `Bundle.main`，SPM 模块会静默回落成 key。
#if os(Android)
func L(_ key: String) -> String { key }
#else
func L(_ key: String.LocalizationValue) -> LocalizedStringResource {
    LocalizedStringResource(key, bundle: .atURL(Bundle.module.bundleURL))
}
#endif
