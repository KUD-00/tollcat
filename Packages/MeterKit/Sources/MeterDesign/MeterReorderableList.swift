import SwiftUI

/// 能拖动排序的分组列表（仪表盘「编辑」）。`MeterGroupedList` 在 Mac 是 grouped `Form`，
/// Form 不接 `onMove`；这里两端都是 `List`：iOS insetGrouped 并常开编辑态露出拖柄，
/// Mac 用 inset 表，行靠拖拽换位。
public struct MeterReorderableList<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        #if os(macOS)
        List {
            content
        }
        .listStyle(.inset)
        .meterGroupedRowButtons()
        .scrollContentBackground(.hidden)
        .background(Color.meterGroupedBackground)
        // Mac 的 sheet 按内容报理想高，List 的理想高是 0，会缩成一条 80pt 的横条。
        // 给它一个像窗口的最小尺寸，剩下的交给 sheet 自己滚。
        .frame(minWidth: MeterSpacing.macSheetListWidth, minHeight: MeterSpacing.macSheetListHeight)
        #else
        List {
            content
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(.active))
        #endif
    }
}
