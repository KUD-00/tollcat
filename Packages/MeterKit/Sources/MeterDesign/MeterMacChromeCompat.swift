import SwiftUI

#if os(macOS)

/// iOS 导航栏 / 搜索栏 placement 在 Mac 上的空对应。调用点不要写 `#if os`。
public enum MeterSearchDrawerMode {
    case always
}

public extension SearchFieldPlacement {
    static func navigationBarDrawer(
        displayMode: MeterSearchDrawerMode
    ) -> SearchFieldPlacement {
        .automatic
    }
}

public extension ToolbarItemPlacement {
    static var topBarTrailing: ToolbarItemPlacement { .automatic }
    static var topBarLeading: ToolbarItemPlacement { .automatic }
}
#endif

public extension View {
    /// 列的导航栏按钮。iOS 进这一列的导航栏；Mac 上同一批按钮由
    /// `meterMacColumnBar(actions:)` 画在列顶，这里必须什么都不声明——
    /// window toolbar 有没有 item 会让 titlebar 高度逐 tab 重新协商，侧栏跟着跳。
    @ViewBuilder
    func meterNavigationToolbar<C: ToolbarContent>(
        @ToolbarContentBuilder content: () -> C
    ) -> some View {
        #if os(macOS)
        self
        #else
        toolbar(content: content)
        #endif
    }
}

public extension View {
    /// Mac 上 `List` / `Form` 会自己铺一层系统画布（深色 #282828 那档灰），
    /// 和我们铺的 `meterGroupedBackground`（深色 #1E1E1E）拼成两截颜色。
    /// 挂在分栏 detail 根上：整个主区的滚动画布藏掉、统一铺回 token。
    /// `scrollContentBackground` 是环境式修饰符，列内推进和 sheet 都跟着走。
    @ViewBuilder
    func meterMacDetailCanvas() -> some View {
        #if os(macOS)
        scrollContentBackground(.hidden)
            .background(Color.meterGroupedBackground)
        #else
        self
        #endif
    }
}

public extension View {
    /// iOS 把分组背景铺进导航栏底下。Mac 没有 `.navigation` 这个 placement。
    func meterNavigationContainerBackground(_ color: Color) -> some View {
        #if os(macOS)
        background(color)
        #else
        containerBackground(color, for: .navigation)
        #endif
    }
}
