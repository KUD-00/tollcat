import SwiftUI
import MeterDesign

/// iPad 侧栏大标题写应用名。Mac 什么都不放：品牌章和菜单栏、程序坞重复，
/// 猫也不进侧栏——侧栏只有三个入口。
struct PadSidebarIdentity: ViewModifier {
    @Environment(\.meterShell) private var shell

    func body(content: Content) -> some View {
        // 版式选择，不是 API 可用性——走壳，不走 `#if os`。
        if shell == .mac {
            content
        } else {
            content
                .navigationTitle(Text(L("TollCat")))
                .navigationBarTitleDisplayMode(.large)
        }
    }
}
