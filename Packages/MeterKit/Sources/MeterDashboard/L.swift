import Foundation
import MeterFormat

/// MeterDashboard 的用户可见文案，四个平台都能编（见 MeterFormat 的 `PortableText`）。
///
/// 这个 target 里的 builder 要编进 Android / Windows / CLI 的桥，所以不用
/// `LocalizedStringResource`：桥上设了 `PortableLocale.languageTag` 时查生成的
/// `MeterDashboardCopy` 表，App 和 widget 不设，走本模块的 String Catalog。
func L(_ text: PortableText) -> String {
    MeterDashboardCopy.catalog.resolve(text)
}
