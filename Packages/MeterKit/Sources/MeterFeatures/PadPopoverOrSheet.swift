import SwiftUI

/// 横屏 iPad 用 popover，其余用 sheet。筛选这种从工具栏弹出的面板才走这里。
/// 面板用 `meterPhoneDrawerChrome`，不要把 sheet 的抓手和 sizing 套进 popover。
struct PadPopoverOrSheet<Panel: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder var panel: () -> Panel

    @Environment(\.usesPadChrome) private var usesPadChrome

    func body(content: Content) -> some View {
        if usesPadChrome {
            content.popover(isPresented: $isPresented) {
                panel()
                    .meterPopoverChrome()
            }
        } else {
            content.sheet(isPresented: $isPresented, content: panel)
        }
    }
}
