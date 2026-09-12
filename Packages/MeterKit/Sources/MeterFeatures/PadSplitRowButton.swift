import SwiftUI
import MeterDesign

/// 横屏主从列表的一行。不用 `List(selection:)`：iOS 26 会在 insetGrouped
/// 选中行外面再描一圈圆角框。选中只靠 [PadRowSelected] 铺一层系统灰。
struct PadSplitRowButton<Label: View>: View {
    var isSelected: Bool
    var hint: LocalizedStringResource
    var action: () -> Void
    var label: Label

    init(
        isSelected: Bool,
        hint: LocalizedStringResource,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.isSelected = isSelected
        self.hint = hint
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: MeterSpacing.sm) {
                label
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(MeterFont.footnote.weight(.semibold))
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .accessibilityHidden(true)
            }
            .meterListRowHitTarget()
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.meterLabel)
        .accessibilityHint(hint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .modifier(PadRowSelected(isSelected: isSelected))
    }
}

#Preview("Light") {
    List {
        PadSplitRowButton(
            isSelected: true,
            hint: L("打开关于页"),
            action: {}
        ) {
            Text(L("关于"))
        }
        PadSplitRowButton(
            isSelected: false,
            hint: L("提一条反馈"),
            action: {}
        ) {
            Text(L("反馈"))
        }
    }
    .listStyle(.insetGrouped)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        PadSplitRowButton(
            isSelected: true,
            hint: L("打开关于页"),
            action: {}
        ) {
            Text(L("关于"))
        }
        PadSplitRowButton(
            isSelected: false,
            hint: L("提一条反馈"),
            action: {}
        ) {
            Text(L("反馈"))
        }
    }
    .listStyle(.insetGrouped)
    .preferredColorScheme(.dark)
}
