import SwiftUI

/// Mac 的 sheet / popover 没有导航栏：iOS 上塞进导航栏的标题和关闭钮，
/// 在 Mac 上要么被系统甩到另起的一条底栏（关闭钮），要么带着 48pt 的
/// 空 inset 漂在顶上（标题）。所以 Mac 的弹出面自己画头尾：
/// 顶上一行列头样式的标题，底下一行右对齐的按钮（`meterPrimaryActionBar`）。
///
/// 这个环境值由 `meterDrawerChrome` / `meterPopoverChrome` 在弹出面的根上打开，
/// `meterSheetTitle` / `meterSheetClose` / `meterPrimaryActionBar` 据此切 Mac 版式。
/// 列内推进的同一张表单（比如服务页的「手动订阅」）不在弹出面里，
/// 标题由列头接管，不再画一遍。
public extension EnvironmentValues {
    @Entry var meterInSheetSurface: Bool = false
}

public extension View {
    /// 从工具栏弹出的面板（筛选）。横屏 iPad 是 popover，尺寸沿用；
    /// Mac 也是 popover，但要钉死宽度、封顶高度——不封顶的话 Form 会按内容
    /// 的理想高度把 popover 拉成一条 900pt 的长条，顶出屏幕。
    @ViewBuilder
    func meterPopoverChrome() -> some View {
        #if os(macOS)
        self
            .frame(width: MeterSpacing.macPopoverWidth)
            .frame(maxHeight: MeterSpacing.macPopoverMaxHeight)
            .scrollContentBackground(.hidden)
            .environment(\.meterInSheetSurface, true)
        #else
        self
            .frame(minWidth: 380, idealWidth: 420, minHeight: 520)
        #endif
    }
}

/// 弹出面的标题。iOS 进导航栏（inline）；Mac 的 sheet 里自己画一行，
/// 和 `meterMacColumnBar` 同一套字号与内距，左沿对齐分组卡。
struct MeterSheetTitle: ViewModifier {
    var title: Text
    @Environment(\.meterInSheetSurface) private var inSheet

    func body(content: Content) -> some View {
        #if os(macOS)
        if inSheet {
            content
                .safeAreaInset(edge: .top, spacing: 0) {
                    title
                        .font(MeterFont.title2.weight(.semibold))
                        .foregroundStyle(Color.meterLabel)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: MeterSpacing.macBarButton)
                        .padding(.horizontal, MeterSpacing.pageHorizontal)
                        .padding(.vertical, MeterSpacing.sm)
                        .background(Color.meterGroupedBackground)
                        .accessibilityAddTraits(.isHeader)
                }
        } else {
            // 列内推进：标题在列头（`meterMacColumnBar`），这里不重复。
            content
        }
        #else
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

public extension View {
    func meterSheetTitle(_ title: Text) -> some View {
        modifier(MeterSheetTitle(title: title))
    }
}

#Preview("Light") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                List {
                    Text(verbatim: "Row")
                }
                .meterSheetTitle(Text(verbatim: "Title"))
            }
            .meterDrawerChrome(.large, usesPadChrome: true)
        }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                List {
                    Text(verbatim: "Row")
                }
                .meterSheetTitle(Text(verbatim: "Title"))
            }
            .meterDrawerChrome(.large, usesPadChrome: true)
        }
        .preferredColorScheme(.dark)
}
