import SwiftUI

/// 列里常显的搜索框。iOS 钉在导航栏底下（`navigationBarDrawer`）；
/// Mac 没有列内导航栏，`.searchable` 会跑进窗口工具栏——顶栏是空着的，
/// 一颗搜索框孤零零挂在窗口右上，离列表隔着半个窗口。所以 Mac 上画在列顶：
/// 一颗圆角搜索框，水平内距和 `meterMacColumnBar` 的标题同一档。
struct MeterColumnSearch: ViewModifier {
    @Binding var text: String
    var prompt: Text

    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(spacing: MeterSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .accessibilityHidden(true)
                    TextField(text: $text, prompt: prompt) {
                        prompt
                    }
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    // 这个字段只在 Mac 出现，没有软件键盘要收；挂它是 Mac 空操作，
                    // 让「有输入框就得能收键盘」那道闸（按字面量扫）过。
                    .meterKeyboardDismiss {}
                    if !text.isEmpty {
                        Button {
                            text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.meterTertiaryLabel)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(L("清空")))
                    }
                }
                .font(MeterFont.body)
                .padding(.horizontal, MeterSpacing.sm)
                .frame(height: MeterSpacing.macBarButton)
                .background(
                    Color.meterTertiarySystemFill,
                    in: RoundedRectangle(cornerRadius: MeterRadius.searchField, style: .continuous)
                )
                // 和分组卡的左右沿对齐，不和列头标题（md）对齐——框和卡是同一层东西。
                .padding(.horizontal, MeterSpacing.pageHorizontal)
                .padding(.bottom, MeterSpacing.xs)
                .background(Color.meterGroupedBackground)
            }
        #else
        content
            .searchable(
                text: $text,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: prompt
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        #endif
    }
}

public extension View {
    func meterColumnSearchable(text: Binding<String>, prompt: Text) -> some View {
        modifier(MeterColumnSearch(text: text, prompt: prompt))
    }
}

#Preview("Light") {
    @Previewable @State var text = ""
    NavigationStack {
        List(0..<8, id: \.self) { index in
            Text(verbatim: "Row \(index)")
        }
        .meterColumnSearchable(text: $text, prompt: Text(verbatim: "Search"))
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var text = "Ne"
    NavigationStack {
        List(0..<8, id: \.self) { index in
            Text(verbatim: "Row \(index)")
        }
        .meterColumnSearchable(text: $text, prompt: Text(verbatim: "Search"))
    }
    .preferredColorScheme(.dark)
}
