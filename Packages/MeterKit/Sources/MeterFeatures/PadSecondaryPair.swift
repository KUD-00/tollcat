import SwiftUI
import MeterDesign

/// Mac 主从两列的拼法：一级侧栏已经是 `NavigationSplitView`，二级不要再套一层
/// 分栏（里层会自己再留导航栏和收起按钮，整列被顶出一条空白），所以在 detail
/// 这一列里手工并排，列头各自走 `meterMacColumnBar`。
///
/// iPad 不走这条——那边一列一根系统导航栏，服务 / 设置在 `RootView` 里仍是真三栏。
struct PadSecondaryPair<List: View, Detail: View>: View {
    var listWidth: CGFloat = MeterSpacing.phoneColumn
    var list: List
    var detail: Detail

    var body: some View {
        HStack(spacing: 0) {
            list
                .frame(width: listWidth)
            Divider()
            detail
        }
        // 不要在这里 `.toolbar(.hidden, for: .navigationBar)`。这条可见性往下传，
        // 里面两列自己的 `NavigationStack` 会一起哑掉——iPad 的「服务」「设置」
        // 连同推进去的二级页全部没有大标题、没有导航栏按钮，而且列内再声明一次
        // `.visible` 也抢不回来（祖先那条赢）。空的外层栏由这两根列内栈自己顶掉，
        // 剩下要摘的只有收起钮。Mac 上 `.navigationBar` 就是 window toolbar，
        // 窗口 chrome 一律由 `meterSplitViewChrome` + `meterMacColumnBar` 管。
        .toolbar(removing: .sidebarToggle)
    }
}
