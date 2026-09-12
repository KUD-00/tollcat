import SwiftUI

/// Mac 上 `Toggle` 默认是 checkbox，`List` 行高也按 AppKit 表来。
/// 系统设置用的是 switch + 够点的行；根上钉死，调用点继续写 `Toggle`。
///
/// 只在 Mac 生效。iOS 上这两项本来就是系统默认（`Toggle` 是开关、最小行高 44），
/// 挂上去等于在整棵树上多一条全局覆盖：以后想就近换个 toggle 样式、或者让某处
/// 行更密，都得先绕开它，而系统哪天改了默认值我们已经把它钉住了。
public extension View {
    @ViewBuilder
    func meterControlChrome() -> some View {
        #if os(macOS)
        self
            .toggleStyle(.switch)
            .environment(\.defaultMinListRowHeight, MeterSpacing.minTap)
        #else
        self
        #endif
    }
}
