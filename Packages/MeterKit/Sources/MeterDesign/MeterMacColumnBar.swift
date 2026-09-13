import SwiftUI

/// Mac 没有列内导航栏：窗口工具栏会把三栏的按钮收成一条。这一条只在 Mac
/// 画在列顶，iPad / iPhone 仍走系统 `navigationTitle` / `.toolbar`。
struct MeterMacColumnBar<Actions: View>: ViewModifier {
    /// nil = 这列此刻没有自己的题（详情列空态）。bar 本身保留：
    /// 高度兜底和挡 titlebar 下穿都还要它，只是不画字——
    /// 空态再画一遍列表列的标题就是两个「服务」并排。
    var title: Text?
    var showBack: Bool
    var onBack: () -> Void
    var actions: Actions

    func body(content: Content) -> some View {
        #if os(macOS)
        // Mac 上 `NavigationStack` / `ContentUnavailableView` 都不贪婪：空态列会
        // 收缩成一小块被居中，这条 bar 挂在它的 safe area 上就跟着漂到窗口中间。
        // 先撑满整列，bar 才永远钉在列顶。
        //
        // 列头紧贴红绿灯那一行之下，不画进那一行：titlebar 区域里的东西系统
        // 只当窗口拖拽区，AX 能按、鼠标点不到（实测返回 / 刷新全哑）。
        // 那一行只有 32pt（窗口不带工具栏），列头和侧栏第一行同一水平。
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: MeterSpacing.sm) {
                if showBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.backward")
                    }
                    .buttonStyle(MeterGlassIconButtonStyle())
                    .accessibilityLabel(Text(L("返回")))
                    .help(Text(L("返回")))
                }
                Group {
                    if let title {
                        title
                            .font(MeterFont.title2.weight(.semibold))
                            .foregroundStyle(Color.meterLabel)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // Mac 的列头有整列宽度可用，按钮一律图标加字：鼠标不该靠悬停
                // 才知道一颗图标是干什么的。iPhone / iPad 的同一组按钮仍在系统
                // 导航栏里（`.toolbar`），那边窄，保持只有图标。
                // `fixedSize` 让这一组永远按自己的字宽排，列窄了先截标题。
                HStack(spacing: MeterSpacing.xs) {
                    actions
                }
                .labelStyle(.titleAndIcon)
                .buttonStyle(MeterGlassLabelButtonStyle())
                // 这一组里可能有 `Menu`（服务列的排序）：不指定 `.button`，
                // 菜单不认外面的按钮样式，会在一排玻璃胶囊里露出一颗系统小方钮。
                .menuStyle(.button)
                .fixedSize()
            }
            // 内容行高按玻璃圆钮兜底：没有按钮的列（比如详情列只有标题）
            // 也保持同一条 bar 高，两列的标题基线和列表起点才对得齐。
            .frame(minHeight: MeterSpacing.macBarButton)
            // 左右沿固定 md，三个 tab 的标题一个位置。内容列限宽居中的页面
            // （仪表盘）标题也不跟着内容走——同一个壳，标题不该随页面漂。
            .padding(.horizontal, MeterSpacing.md)
            .padding(.vertical, MeterSpacing.sm)
            .background {
                // 不透明窗口底色，向上贯穿红绿灯那一行：滚动下穿的内容
                // 到这里被整块挡掉，顶上保持素净的一片，没有任何 hairline。
                Rectangle()
                    .fill(Color.meterGroupedBackground)
                    .ignoresSafeArea(edges: .top)
            }
        }
        #else
        content
        #endif
    }
}

/// 列头的液态玻璃圆钮：中性玻璃底、图标用文字色，对齐 iOS 26 导航栏按钮。
/// 不用 `GlassButtonStyle`——它吃全局 accent，渲出来是实心药丸不是玻璃。
struct MeterGlassIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .font(MeterFont.subheadline.weight(.semibold))
            .foregroundStyle(Color.meterLabel)
            .frame(width: MeterSpacing.macBarButton, height: MeterSpacing.macBarButton)
            .contentShape(Circle())
            .glassEffect(.regular.interactive(), in: .circle)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// 列头的液态玻璃胶囊钮：图标加字，和圆钮同高，同一排混排基线也齐。
/// 只有 Mac 列头用它——iOS 那边这组按钮在系统导航栏里，只放图标。
struct MeterGlassLabelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.titleAndIcon)
            .font(MeterFont.subheadline.weight(.semibold))
            .foregroundStyle(Color.meterLabel)
            .padding(.horizontal, MeterSpacing.sm)
            .frame(height: MeterSpacing.macBarButton)
            .contentShape(Capsule())
            .glassEffect(.regular.interactive(), in: .capsule)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

public extension View {
    /// `actions` 必须是最后一个参数并带默认值。`#Preview` 会把最后一个闭包
    /// 收成尾随闭包；若旁边再有一个 `() -> Void` 重载，按钮会绑到 `onBack`，
    /// 预览里变成 unused 结果。
    func meterMacColumnBar<Actions: View>(
        title: Text?,
        showBack: Bool = false,
        onBack: @escaping () -> Void = {},
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) -> some View {
        modifier(
            MeterMacColumnBar(
                title: title,
                showBack: showBack,
                onBack: onBack,
                actions: actions()
            )
        )
    }
}

#Preview("Light") {
    Color.meterGroupedBackground
        .meterMacColumnBar(title: Text("August"), showBack: true, actions: {
            Button("Refresh", systemImage: "arrow.clockwise") {}
            Button("Filter", systemImage: "line.3.horizontal.decrease") {}
        })
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    Color.meterGroupedBackground
        .meterMacColumnBar(title: Text("August"), showBack: true, actions: {
            Button("Refresh", systemImage: "arrow.clockwise") {}
            Button("Filter", systemImage: "line.3.horizontal.decrease") {}
        })
        .preferredColorScheme(.dark)
}
