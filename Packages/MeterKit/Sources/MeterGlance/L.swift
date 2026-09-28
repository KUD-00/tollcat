import Foundation

/// 用户可见文案走这里。`Text("…")` 默认查 `Bundle.main`，SPM 模块会静默回落成 key。
///
/// 手表壳和手表小组件都没有自己的 catalog：表盘上的字全在这个模块里，
/// 所以壳只摆视图，不写一句话。
func L(_ key: String.LocalizationValue) -> LocalizedStringResource {
    LocalizedStringResource(key, bundle: .atURL(Bundle.module.bundleURL))
}
