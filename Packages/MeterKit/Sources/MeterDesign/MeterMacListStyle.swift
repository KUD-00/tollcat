#if os(macOS)
import SwiftUI

/// Mac 没有 `InsetGroupedListStyle`。这个别名只为让 iPhone 单列路径
/// （和随它编译的预览）在 Mac 也编得过——渲出来是密表。
/// **Mac 真正显示的页面一律走 `MeterGroupedList`（grouped `Form`）**，
/// 别再给任何 Mac 可达页面用这个别名；guardrail 见 `MacColumnGuardrailTests`。
public extension ListStyle where Self == InsetListStyle {
    static var insetGrouped: InsetListStyle { .inset }
}
#endif
