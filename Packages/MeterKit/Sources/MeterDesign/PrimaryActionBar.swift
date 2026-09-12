import SwiftUI

/// 单一主操作钉在底部。
///
/// 不用 iOS 26 的 `safeAreaBar`：那会叠一层滚动边缘模糊，转移页那颗
/// 直接铺在分组背景上的满宽按钮就会变样。这里只做三件事——
/// `safeAreaInset` 把按钮钉住，关掉底边滚动边缘效果，再把分组色铺进
/// Home Indicator。列表行才不会从按钮底下透出来。
///
/// 有输入框的抽屉把 `ignoresKeyboard` 打开：按钮留在抽屉底，不要跟着
/// 软件键盘抬。键盘附件栏已经有「完成」。`safeAreaInset` 一抬，Form 跟着
/// 改高度，再叠一层 detent 把键盘算进高度，整页弹跳。
public struct PrimaryActionBar<BarContent: View>: ViewModifier {
    var isVisible: Bool
    var ignoresKeyboard: Bool
    var barContent: BarContent

    public init(
        isVisible: Bool = true,
        ignoresKeyboard: Bool = false,
        @ViewBuilder barContent: () -> BarContent
    ) {
        self.isVisible = isVisible
        self.ignoresKeyboard = ignoresKeyboard
        self.barContent = barContent()
    }

    @Environment(\.meterInSheetSurface) private var inSheet
    @State private var closeHandler: MeterSheetCloseHandler?

    public func body(content: Content) -> some View {
        #if os(macOS)
        if inSheet {
            macSheetBar(content)
        } else {
            phoneBar(content)
        }
        #else
        phoneBar(content)
        #endif
    }

    #if os(macOS)
    /// Mac 弹出面的底栏：按钮右对齐、按文字收宽，左边是 `meterSheetClose`
    /// 报上来的「取消」（Esc），右边主操作是默认钮（Return）。
    /// 不铺满宽：Mac 对话框的按钮从来不是一整条药丸。
    private func macSheetBar(_ content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.meterSheetCloseHosted, true)
            .onPreferenceChange(MeterSheetClosePreference.self) { closeHandler = $0 }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isVisible {
                    HStack(spacing: MeterSpacing.sm) {
                        Spacer(minLength: 0)
                        if let closeHandler {
                            Button(role: .cancel) {
                                closeHandler.run()
                            } label: {
                                Text(L("取消"))
                            }
                            .keyboardShortcut(.cancelAction)
                        }
                        barContent
                            .environment(\.meterCompactPrimaryAction, true)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .controlSize(.large)
                    .padding(.horizontal, MeterSpacing.pageHorizontal)
                    .padding(.top, MeterSpacing.sm)
                    .padding(.bottom, MeterSpacing.pageHorizontal)
                    .background(Color.meterGroupedBackground)
                }
            }
    }
    #endif

    private func phoneBar(_ content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // List 自己还会为 Home Indicator 留一截。底栏已经 inset 了，
            // 再留就会把按钮抬高，连接参考和连接页对不齐。
            .contentMargins(.bottom, 0, for: .scrollContent)
            .scrollEdgeEffectHidden(true, for: .bottom)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isVisible {
                    barContent
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, MeterSpacing.md)
                        .padding(.vertical, MeterSpacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(Color.meterGroupedBackground)
                        .background(alignment: .bottom) {
                            Color.meterGroupedBackground
                                .frame(height: MeterSpacing.xxl)
                                .offset(y: MeterSpacing.xxl)
                                .ignoresSafeArea(.container, edges: .bottom)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                }
            }
            .ignoresSafeArea(ignoresKeyboard ? .keyboard : [], edges: .bottom)
    }
}

public extension View {
    func meterPrimaryActionBar<BarContent: View>(
        isVisible: Bool = true,
        ignoresKeyboard: Bool = false,
        @ViewBuilder content: () -> BarContent
    ) -> some View {
        modifier(
            PrimaryActionBar(
                isVisible: isVisible,
                ignoresKeyboard: ignoresKeyboard,
                barContent: content
            )
        )
    }

    func meterPrimaryActionStyle() -> some View {
        modifier(MeterPrimaryActionStyle())
    }

    /// 页内胶囊。和底栏同一颗 borderedProminent，高度走 regular，不要跟 50pt 大按钮齐。
    func meterInlineActionStyle() -> some View {
        buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .buttonBorderShape(.capsule)
    }
}

#Preview("Light") {
    NavigationStack {
        PrimaryActionBarPreviewList()
            .navigationTitle(Text(verbatim: "Manual"))
            .meterPrimaryActionBar {
                PrimaryActionBarPreviewButton()
            }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        PrimaryActionBarPreviewList()
            .navigationTitle(Text(verbatim: "Manual"))
            .meterPrimaryActionBar {
                PrimaryActionBarPreviewButton()
            }
    }
    .preferredColorScheme(.dark)
}

#Preview("XXL") {
    NavigationStack {
        PrimaryActionBarPreviewList()
            .navigationTitle(Text(verbatim: "Manual"))
            .meterPrimaryActionBar {
                PrimaryActionBarPreviewButton()
            }
    }
    .dynamicTypeSize(.accessibility3)
}

private struct PrimaryActionBarPreviewButton: View {
    var body: some View {
        Button(action: {}) {
            Text(verbatim: "Save")
                .frame(maxWidth: .infinity)
        }
        .meterPrimaryActionStyle()
    }
}

private struct PrimaryActionBarPreviewList: View {
    var body: some View {
        List(0..<16, id: \.self) { index in
            Text(verbatim: "Row \(index + 1)")
        }
        .listStyle(.insetGrouped)
    }
}

/// 主操作那颗胶囊。iPhone / iPad 底栏：大号、满宽、50pt。
/// Mac 弹出面（`meterCompactPrimaryAction`）：同一颗 borderedProminent，
/// 但按文字收宽、不撑 50pt，Return 触发——那是 Mac 对话框的默认钮。
struct MeterPrimaryActionStyle: ViewModifier {
    @Environment(\.meterCompactPrimaryAction) private var compact

    func body(content: Content) -> some View {
        if compact {
            content
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .buttonBorderShape(.capsule)
                .keyboardShortcut(.defaultAction)
        } else {
            content
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .buttonBorderShape(.capsule)
                .frame(maxWidth: .infinity, minHeight: MeterSpacing.primaryActionMinHeight)
        }
    }
}

public extension EnvironmentValues {
    /// Mac 弹出面底栏打开：主操作按文字收宽，不再是满宽大药丸。
    @Entry var meterCompactPrimaryAction: Bool = false
}
