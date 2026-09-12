import Foundation

/// 用户可见文案走这里。`Text("…")` 默认查 `Bundle.main`，SPM 模块会静默回落成 key。
func L(_ key: String.LocalizationValue) -> LocalizedStringResource {
    LocalizedStringResource(key, bundle: .atURL(Bundle.module.bundleURL))
}
