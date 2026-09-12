import SwiftUI

/// 分栏外壳。Mac 窗口不带工具栏：标题摘掉，返回、刷新都在列里
/// （`meterMacColumnBar`）。顶上只剩红绿灯那一行（32pt），列头紧贴其下。
/// 不要 `.toolbar(.hidden, for: .windowToolbar)`——那会把整条 titlebar 连红绿灯
/// 一起折没；也不要再声明任何 `ToolbarItem`——哪怕一颗不可见的占位，窗口就会
/// 长出一条 52pt 的工具栏，列头被压下去 20pt，titlebar 高度还会逐 tab 重新协商。
/// 系统 `NavigationStack` 一 push 就会往工具栏塞返回钮、把这条长出来，
/// 所以 Mac 上列内推页一律走 `MacColumnStack`，不走系统栈。
public extension View {
    func meterSplitColumnChrome() -> some View {
        toolbar(removing: .sidebarToggle)
    }

    func meterSplitViewChrome() -> some View {
        #if os(macOS)
        self
            .toolbar(removing: .title)
            // 没有工具栏，主区顶上那 32pt 仍会铺一层 titlebar 材质（亮色近白、
            // 深色偏蓝灰），和列底拼成两截。藏掉它，露出的才是窗口底色（同一个 token）。
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        #else
        self
        #endif
    }
}
