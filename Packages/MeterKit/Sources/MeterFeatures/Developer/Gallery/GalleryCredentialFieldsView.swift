#if DEBUG
import SwiftUI
import MeterDesign

/// 凭据输入行：两行布局、点标题唤起键盘、右侧粘贴。
struct GalleryCredentialFieldsView: View {
    @State private var token = ""
    @State private var account = ""
    @FocusState private var focused: String?

    var body: some View {
        MeterGroupedList {
            Section {
                CredentialFieldRow(
                    title: "API Token",
                    fieldID: "token",
                    text: $token,
                    focusedField: $focused,
                    onPaste: { paste(into: $token) }
                )
                CredentialFieldRow(
                    title: "Account ID",
                    fieldID: "account",
                    text: $account,
                    focusedField: $focused,
                    onPaste: { paste(into: $account) }
                )
            } header: {
                Text(L("凭据"))
            } footer: {
                Text(L("点标题会弹出键盘。右侧粘贴从剪贴板填入。"))
            }
        }
        .meterKeyboardDismiss {
            focused = nil
        }
        .navigationTitle(L("凭据输入"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func paste(into target: Binding<String>) {
        guard let raw = SystemClipboard.string else { return }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        target.wrappedValue = value
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryCredentialFieldsView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryCredentialFieldsView()
    }
    .preferredColorScheme(.dark)
}
#endif
