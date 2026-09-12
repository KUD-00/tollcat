import SwiftUI

/// 凭据输入：名字一行，输入一行。明文 `TextField`，不要掩码。
///
/// 掩码会换成 `UITextField`，光标高度、热区和键盘「完成」都会和旁边的
/// Account ID 对不上。Token 存进 Keychain 之前看一眼，比假安全更重要。
///
/// 输入行是 44pt 热区。字段名矮一截，才贴得住卡片上沿；点名字同样唤起键盘。
/// 输入框本身保持正文行高，光标才不会被撑成整行那么长；点到空白处靠底层
/// `onTapGesture` 把焦点拉过来。
public struct CredentialFieldRow: View {
    /// 这一栏里填的是什么。字体、大写、键盘和回车键跟着它走，
    /// 调用点不用各写一遍，也就不会各写歪一点。
    public enum Kind: Sendable {
        /// API Token / Account ID：正文字体，原样大小写。
        case credential
        /// 迁移一次性码：等宽字体对齐 10 位，整串大写，回车即导入。
        case transferCode
    }

    private let title: String
    private let fieldID: String
    private let kind: Kind
    private let isEnabled: Bool
    @Binding private var text: String
    private var focusedField: FocusState<String?>.Binding
    private let onPaste: (() -> Void)?
    private let onSubmit: (() -> Void)?

    public init(
        title: String,
        fieldID: String,
        text: Binding<String>,
        focusedField: FocusState<String?>.Binding,
        kind: Kind = .credential,
        isEnabled: Bool = true,
        onPaste: (() -> Void)? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.title = title
        self.fieldID = fieldID
        self.kind = kind
        self.isEnabled = isEnabled
        self._text = text
        self.focusedField = focusedField
        self.onPaste = onPaste
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            Text(title)
                .font(MeterFont.subheadline)
                .foregroundStyle(Color.meterSecondaryLabel)
                .frame(maxWidth: .infinity, minHeight: MeterSpacing.fieldLabel, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: activate)
                .accessibilityHidden(true)

            ZStack(alignment: .leading) {
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: MeterSpacing.minTap)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: activate)
                HStack(alignment: .center, spacing: MeterSpacing.xs) {
                    TextField("", text: $text)
                        .font(kind.font)
                        .focused(focusedField, equals: fieldID)
                        .meterDisablesPasswordSave()
                        .textInputAutocapitalization(kind.autocapitalization)
                        .keyboardType(kind.keyboardType)
                        .submitLabel(kind.submitLabel)
                        .autocorrectionDisabled()
                        .fixedSize(horizontal: false, vertical: true)
                        .modifier(MacCredentialFieldStyle())
                        .accessibilityLabel(title)
                        .disabled(!isEnabled)
                        .onSubmit {
                            onSubmit?()
                        }
                    if let onPaste {
                        Button(L("粘贴"), action: onPaste)
                            .font(MeterFont.subheadline)
                            .frame(minWidth: MeterSpacing.minTap, minHeight: MeterSpacing.minTap)
                            .contentShape(Rectangle())
                            .disabled(!isEnabled)
                            .accessibilityLabel(L("粘贴"))
                            .accessibilityHint(L("从剪贴板填入这一栏"))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: MeterSpacing.minTap, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func activate() {
        guard isEnabled else { return }
        focusedField.wrappedValue = fieldID
    }
}

private extension CredentialFieldRow.Kind {
    var font: Font {
        switch self {
        case .credential: MeterFont.body
        case .transferCode: MeterFont.transferCodeField
        }
    }

    var autocapitalization: TextInputAutocapitalization {
        switch self {
        case .credential: .never
        case .transferCode: .characters
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .credential: .default
        case .transferCode: .asciiCapable
        }
    }

    var submitLabel: SubmitLabel {
        switch self {
        case .credential: .done
        case .transferCode: .go
        }
    }
}

public extension View {
    /// 声明这不是用户名 / 密码，避免系统弹出「存储密码？」。
    func meterDisablesPasswordSave() -> some View {
        textContentType(.oneTimeCode)
    }
}

#Preview("Light") {
    CredentialFieldRowPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CredentialFieldRowPreview()
        .preferredColorScheme(.dark)
}

private struct CredentialFieldRowPreview: View {
    @State private var token = "secret-token"
    @State private var account = "a1b2c3d4e5f6a7b8"
    @State private var code = "K7QP2-9WX4M"
    @FocusState private var focused: String?

    var body: some View {
        Form {
            Section {
                CredentialFieldRow(
                    title: "API Token",
                    fieldID: "token",
                    text: $token,
                    focusedField: $focused,
                    onPaste: { token = "preview-token" }
                )
                CredentialFieldRow(
                    title: "Account ID",
                    fieldID: "account",
                    text: $account,
                    focusedField: $focused,
                    onPaste: { account = "a1b2c3d4e5f6a7b8" }
                )
            } header: {
                Text(verbatim: "凭据")
            }
            Section {
                CredentialFieldRow(
                    title: "一次性码",
                    fieldID: "code",
                    text: $code,
                    focusedField: $focused,
                    kind: .transferCode,
                    onPaste: { code = "K7QP2-9WX4M" }
                )
            } header: {
                Text(verbatim: "导入")
            }
        }
        .meterKeyboardDismiss {
            focused = nil
        }
    }
}

/// Mac 的 grouped Form 把裸 `TextField` 画成无边框、文字右对齐的「值」——
/// 名字在上、框在下的凭据行里就只剩一根光标贴在「粘贴」旁边，看不出哪里能输。
/// 给它一个圆角边框、铺满行宽、文字左对齐，才是 Mac 上一眼认得出的输入框。
private struct MacCredentialFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity)
        #else
        content
        #endif
    }
}
