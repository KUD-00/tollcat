import SwiftUI

/// 单选胶囊。一排里选一个的那种。
///
/// 收在设计系统里而不是各页各写：这东西一共就是「圆角、选中填实、最小点按 44」
/// 三件事，但抄第二遍的时候必然有一处的字重或者内边距差一点，而两排 chip
/// 上下挨着时，差 2pt 是看得出来的。
public struct MeterSelectionChip: View {
    private let title: String
    private let isSelected: Bool
    private let action: () -> Void

    public init(title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(MeterFont.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.white : Color.meterLabel)
                .padding(.horizontal, MeterSpacing.md)
                .frame(minHeight: MeterSpacing.minTap)
                .background(isSelected ? Color.accentColor : Color.meterTertiarySystemFill)
                .clipShape(Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// 一排横向滚动的 chip。留白和滚动条设置也只写这一处。
///
/// `listRowInsets` 一并给了：这排东西的落点几乎总是 grouped list 的一行，
/// 而 chip 要从内容边缘起排，不能跟着系统那份行内缩进再缩一次。
public struct MeterSelectionChipRow<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: MeterSpacing.xs) {
                content
            }
            .padding(.vertical, MeterSpacing.xxs)
        }
        .scrollIndicators(.hidden)
        .listRowInsets(EdgeInsets(
            top: MeterSpacing.xs,
            leading: MeterSpacing.md,
            bottom: MeterSpacing.xs,
            trailing: MeterSpacing.md
        ))
    }
}
