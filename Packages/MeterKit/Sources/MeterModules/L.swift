import Foundation

/// 用户可见文案走这里。`Text("…")` 默认查 `Bundle.main`，SPM 模块会静默回落成 key。
///
/// 每个 target 一份：`Bundle.module` 是编译进哪个 target 就指哪个 target 的资源包。
/// 模块视图搬到这里之后，它们的字也跟着搬进 `MeterModules/Resources/Localizable.xcstrings`；
/// 折算（builder）留在 MeterFeatures，它们的字也留在那边的目录里。
func L(_ key: String.LocalizationValue) -> LocalizedStringResource {
    LocalizedStringResource(key, bundle: .atURL(Bundle.module.bundleURL))
}
