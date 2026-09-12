#if os(macOS)
import SwiftUI

/// Mac 没有 iPad 那种 `.large` 列内大标题（`ToolbarTitleDisplayMode.large` 不可用）。
/// `.inline` 转给工具栏；`.large` 保持无操作，标题走 `navigationTitle`，窗口标题
/// 由 `meterSplitViewChrome` 摘掉，避免三栏抢一条 top bar。
public enum NavigationBarItem {
    public enum TitleDisplayMode {
        case automatic
        case inline
        case large
        case inlineLarge
    }
}

public extension View {
    @ViewBuilder
    func navigationBarTitleDisplayMode(
        _ displayMode: NavigationBarItem.TitleDisplayMode
    ) -> some View {
        switch displayMode {
        case .inline, .inlineLarge:
            toolbarTitleDisplayMode(.inline)
        case .automatic, .large:
            self
        }
    }
}
#endif
