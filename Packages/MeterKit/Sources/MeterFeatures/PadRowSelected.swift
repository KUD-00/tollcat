import SwiftUI

/// 横屏主从选中只要一层系统灰。不要绑 `List(selection:)`：iOS 26 会在
/// insetGrouped 行外面再描一圈圆角框。
struct PadRowSelected: ViewModifier {
    var isSelected: Bool

    func body(content: Content) -> some View {
        content.listRowBackground(
            isSelected
                ? Color.meterTertiarySystemFill
                : Color.meterSecondaryGroupedBackground
        )
    }
}
