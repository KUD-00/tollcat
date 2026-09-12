import SwiftUI

#if os(macOS)
/// Mac 上 grouped Form / List 行里的裸 `Button` 默认渲成凸起的 NSButton 胶囊；
/// iOS 的 List 把同一颗画成一行 tint 色的字。这个样式把 Mac 压回 iOS 那种行：
/// 去掉 bezel 和内边距，字色跟 role / tint，按下变淡。
/// 不在这里撑满行宽——教程里的小「拷贝」钮也会走到这个默认值，撑满会毁版式。
struct MeterGroupedRowButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.role == .destructive ? MeterColor.crit : Color.accentColor)
            .opacity(configuration.isPressed || !isEnabled ? 0.4 : 1)
            .contentShape(Rectangle())
    }
}
#endif

public extension View {
    /// 挂在分组容器（grouped `Form` / inset `List`）上，给里面的裸按钮当默认值。
    /// `MeterGroupedList` 自带；直接写 `Form` / `List` 的分组页要自己挂——
    /// `MacColumnGuardrailTests` 按这个规则扫。行内就近声明的
    /// `.plain` / 玻璃圆钮 / 主操作钮照常覆盖。
    @ViewBuilder
    func meterGroupedRowButtons() -> some View {
        #if os(macOS)
        buttonStyle(MeterGroupedRowButtonStyle())
        #else
        self
        #endif
    }
}
