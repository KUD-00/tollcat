import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 多行输入把 Return 变成换行，数字键盘没有 Return。iPhone 软件键盘本身
/// 也不带关闭键。完成做在键盘附件栏右上，贴着键盘，不进页面或 sheet 导航栏。
///
/// 外接键盘时系统仍会把 `.keyboard` 工具栏贴在屏幕底，软件键盘却不出现。
/// 所以只在软件键盘真正盖住屏幕时才露出这条；列表跟着手指把键盘收掉。
///
/// 收起时不要在 `willHide` / `willChangeFrame` 的终点帧拆掉完成栏：那会先矮一截，
/// 再整块下去。等 `didHide`，附件跟着键盘一起走完。
///
/// 有 `TextField` / `SecureField` / `TextEditor` 的屏幕必须挂这个 modifier。
/// 凭据输入走 SwiftUI `TextField`，完成就在这条工具栏上。若再引入
/// `UITextField`，必须自己挂 `inputAccessoryView` 的「完成」。
/// `KeyboardDismissGuardrailTests` 和 `scripts/check-source-invariants.py` 两边都扫。
public struct KeyboardDismiss: ViewModifier {
    /// 完成键叫什么，只在这里说一次。再引入 `UITextField` 时它的 `inputAccessoryView`
    /// 必须引用这一个，闸只查引用、不钉字面文案。
    public static var doneTitle: LocalizedStringResource { L("完成") }

    var action: () -> Void
    #if os(iOS)
    @State private var isSoftwareKeyboardVisible = false
    #endif

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public func body(content: Content) -> some View {
        #if os(macOS)
        content
        #else
        content
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                if isSoftwareKeyboardVisible {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(Self.doneTitle, action: dismiss)
                    }
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIResponder.keyboardWillChangeFrameNotification
                )
            ) { notification in
                updateSoftwareKeyboard(from: notification)
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIResponder.keyboardDidShowNotification
                )
            ) { notification in
                updateSoftwareKeyboard(from: notification)
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIResponder.keyboardDidHideNotification
                )
            ) { _ in
                setSoftwareKeyboardVisible(false)
            }
            .onDisappear {
                setSoftwareKeyboardVisible(false)
            }
        #endif
    }

    #if os(iOS)
    private func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        action()
    }

    private func setSoftwareKeyboardVisible(_ visible: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isSoftwareKeyboardVisible = visible
        }
    }

    private func updateSoftwareKeyboard(from notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            !frame.isNull,
            !frame.isInfinite
        else {
            return
        }
        // 收起时终点帧已经离开屏幕。这里只负责露出，拆掉交给 didHide。
        guard SoftwareKeyboard.isCoveringScreen(endFrame: frame, screen: screenBounds) else {
            return
        }
        setSoftwareKeyboardVisible(true)
    }

    private var screenBounds: CGRect {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        // 没有窗口谈不上盖住屏幕。不要回落到 UIScreen.main：iOS 26 已弃用。
        return scene?.screen.bounds ?? .zero
    }
    #endif
}

public extension View {
    func meterKeyboardDismiss(action: @escaping () -> Void) -> some View {
        modifier(KeyboardDismiss(action: action))
    }
}

#Preview("Light") {
    NavigationStack {
        KeyboardDismissPreviewForm()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        KeyboardDismissPreviewForm()
    }
    .preferredColorScheme(.dark)
}

private struct KeyboardDismissPreviewForm: View {
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        Form {
            TextField(text: $text, axis: .vertical) {
                Text(verbatim: "Message")
            }
            .lineLimit(5...12)
            .focused($isFocused)
        }
        .meterKeyboardDismiss {
            isFocused = false
        }
        .navigationTitle(Text(verbatim: "Feedback"))
    }
}
