import MeterCore
import SwiftUI
import MeterDesign
import MeterPersistence

struct SetupCredentialsStepView: View {
    @Bindable var model: SetupWizardModel
    var onSaved: () -> Void = {}
    /// 宽壳两栏里这一栏带着 sheet 的关闭（Mac 底栏「取消」）。iPad 导航栏 X 走整张 sheet；手机栈走向导页那颗 X。
    var onClose: (() -> Void)? = nil
    @State private var isShowingKeychainExplainer = false
    @FocusState private var focusedField: String?

    var body: some View {
        Form {
            if !model.guide.fields.isEmpty {
                Section {
                    ForEach(model.guide.fields, id: \.key) { field in
                        fieldEditor(field)
                    }
                    result
                    saveCaptions
                } header: {
                    Text(L("凭据"))
                } footer: {
                    keychainExplainerButton
                }
            } else {
                Section {
                    result
                    saveCaptions
                } footer: {
                    keychainExplainerButton
                }
            }
            if model.showsSetupFeedback, let outcome = model.outcome {
                SetupFeedbackSection(
                    providerName: model.displayName,
                    outcome: outcome,
                    exchanges: model.capturedExchanges,
                    focusedField: $focusedField
                )
                .id(feedbackSectionID)
            }
            nicknameSection
            #if DEBUG
            debugExchangesSection
            #endif
        }
        .formStyle(.grouped)
        .meterGroupedRowButtons()
        .meterGroupedSectionCard()
        .meterSheetClose(isActive: onClose != nil) { onClose?() }
        .meterKeyboardDismiss {
            focusedField = nil
        }
        .meterPrimaryActionBar(
            isVisible: model.fingerprintCollisionReason == nil,
            ignoresKeyboard: true
        ) {
            FillProgressButton(
                String(
                    localized: model.showsSavePrimaryAction
                        ? L("保存到 Keychain")
                        : L("测试连接")
                ),
                phase: fillPhase,
                isEnabled: model.isCredentialPrimaryEnabled
            ) {
                performPrimaryAction()
            }
            .animation(.snappy, value: model.showsSavePrimaryAction)
            .accessibilityHint(saveAccessibilityHint)
        }
        .sheet(isPresented: $isShowingKeychainExplainer) {
            KeychainExplainerSheet()
        }
        .sensoryFeedback(.error, trigger: model.testFailureToken)
    }

    @ViewBuilder
    private func fieldEditor(_ field: SetupField) -> some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            CredentialFieldRow(
                title: field.label,
                fieldID: field.key,
                text: binding(for: field.key),
                focusedField: $focusedField,
                onPaste: { paste(into: field.key) }
            )
            if let error = model.fieldErrors[field.key], model.didAttemptTest {
                Text(error)
                    .font(MeterFont.footnote)
                    .foregroundStyle(MeterColor.crit)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var saveCaptions: some View {
        if let failure = model.saveFailureCaption {
            Text(verbatim: failure)
                .font(MeterFont.footnote)
                .foregroundStyle(MeterColor.crit)
                .fixedSize(horizontal: false, vertical: true)
        } else if let reason = model.saveBlockedReason {
            Text(verbatim: reason)
                .font(MeterFont.footnote)
                .foregroundStyle(Color.meterSecondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var keychainExplainerButton: some View {
        Button {
            isShowingKeychainExplainer = true
        } label: {
            Text(
                "\(Text(L("凭据会存进 Keychain，")).foregroundStyle(Color.meterSecondaryLabel))\(Text(L("什么是 Keychain？")).foregroundStyle(.tint))"
            )
            // 热区仍是 44pt。字顶对齐，才不会在系统 footer 和卡片之间再垫半行。
            .frame(maxWidth: .infinity, minHeight: MeterSpacing.minTap, alignment: .topLeading)
            .contentShape(Rectangle())
            .multilineTextAlignment(.leading)
        }
        .buttonStyle(.plain)
        .accessibilityHint(L("了解密钥怎样保存在这台设备上"))
    }

    private var fillPhase: FillProgressPhase {
        if model.isTesting { return .progressing }
        if model.showsSavePrimaryAction { return .completed }
        return .idle
    }

    @ViewBuilder
    private var result: some View {
        if let outcome = model.outcome, !model.isTesting {
            SetupVerifyResultView(
                outcome: outcome,
                onRevisePermissions: model.returnToGuide
            )
            if case .success = outcome {
                if model.showsNicknameFields, let sibling = model.existingSibling {
                    let siblingName = model.trimmedSiblingNickname.isEmpty
                        ? (sibling.nickname ?? String(localized: L("账号 1")))
                        : model.trimmedSiblingNickname
                    Text(L("这是新的一份，不会替换「\(siblingName)」。"))
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if model.showsDuplicateOrgWarning {
                    Text(L("同一组织两把密钥会加两次。"))
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func paste(into key: String) {
        guard let raw = SystemClipboard.string else { return }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        model.updateField(key, value: value)
    }

    #if DEBUG
    @ViewBuilder
    private var debugExchangesSection: some View {
        if model.didAttemptTest, !model.isTesting {
            Section {
                if model.debugExchanges.isEmpty {
                    Text(L("这次测试没有发出 HTTP 请求。"))
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(model.debugExchanges) { exchange in
                        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                            Text(verbatim: exchange.summary)
                                .font(MeterFont.footnote)
                                .foregroundStyle(Color.meterSecondaryLabel)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                            CopyBox(
                                exchange.body.isEmpty
                                    ? String(localized: L("空响应"))
                                    : exchange.body,
                                onCopy: { model.copy(exchange.body) }
                            )
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            } header: {
                Text(L("调试 · HTTP"))
            } footer: {
                Text(L("只在开发构建里出现，正式版没有这一节。"))
            }
        }
    }
    #endif

    @ViewBuilder
    private var nicknameSection: some View {
        if model.showsNicknameFields, model.verifiedSnapshot != nil, model.fingerprintCollisionReason == nil {
            Section {
                TextField(L("已有账号"), text: $model.siblingNickname)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: "siblingNickname")
                TextField(L("新账号"), text: $model.newNickname)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: "newNickname")
            } header: {
                Text(L("怎么区分这两份"))
            } footer: {
                Text(L("第二份必须起个昵称。保存时也会把已有那份现在的名字写回去。"))
            }
        }
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { model.fieldValues[key, default: ""] },
            set: { model.updateField(key, value: $0) }
        )
    }

    private var feedbackSectionID: String {
        switch model.outcome {
        case .success:
            return "success"
        case .http(let errorCase):
            return "http-\(errorCase.httpStatus)"
        case .network:
            return "network"
        case .emptyReading:
            return "empty"
        case .unknown:
            return "unknown"
        case nil:
            return "none"
        }
    }

    private var saveAccessibilityHint: Text {
        if model.showsSavePrimaryAction {
            return Text(verbatim: model.saveBlockedReason ?? "")
        }
        return Text(L("测通后，这颗按钮会变成保存到 Keychain。"))
    }

    private func performPrimaryAction() {
        if model.showsSavePrimaryAction {
            model.save()
            if model.saveToken > 0 {
                onSaved()
            }
        } else {
            focusedField = nil
            Task { await model.testConnection() }
        }
    }
}

#Preview("Idle · Light") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .credentials
    )
    NavigationStack {
        SetupCredentialsStepView(model: model)
            .task { await model.prepare() }
    }
    .preferredColorScheme(.light)
}

#Preview("Idle · Dark") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .credentials
    )
    NavigationStack {
        SetupCredentialsStepView(model: model)
            .task { await model.prepare() }
    }
    .preferredColorScheme(.dark)
}

#Preview("Verified · Light") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .credentials,
        outcome: .success(
            title: String(localized: L("本周期至今 $11.05")),
            detail: String(localized: L("周期 8/1 – 8/31 · 日粒度可用"))
        )
    )
    NavigationStack {
        SetupCredentialsStepView(model: model)
            .task { await model.prepare() }
    }
    .preferredColorScheme(.light)
}

#Preview("Verified · Dark") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .credentials,
        outcome: .success(
            title: String(localized: L("本周期至今 $11.05")),
            detail: String(localized: L("周期 8/1 – 8/31 · 日粒度可用"))
        )
    )
    NavigationStack {
        SetupCredentialsStepView(model: model)
            .task { await model.prepare() }
    }
    .preferredColorScheme(.dark)
}

#Preview("Testing") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .credentials
    )
    NavigationStack {
        SetupCredentialsStepView(model: {
            model.isTesting = true
            model.fieldValues = [
                "apiToken": "preview-token",
                "accountID": "preview-account",
            ]
            return model
        }())
        .task { await model.prepare() }
    }
}

#Preview("Failure · Light") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .credentials,
        outcome: .http(
            ErrorCase(
                httpStatus: 401,
                explanation: String(localized: L("这个 token 无效，或者已经被撤销了。")),
                nextStep: String(localized: L("回上一步重新创建一把，创建后立刻复制——它只显示一次。"))
            )
        )
    )
    NavigationStack {
        SetupCredentialsStepView(model: model)
            .task { await model.prepare() }
    }
    .preferredColorScheme(.light)
}

#Preview("Failure · Dark") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .credentials,
        outcome: .network
    )
    NavigationStack {
        SetupCredentialsStepView(model: model)
            .task { await model.prepare() }
    }
    .preferredColorScheme(.dark)
}

#Preview("Theoretical success") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .vercel,
        step: .credentials,
        outcome: .success(
            title: String(localized: L("本周期至今 $11.05")),
            detail: String(localized: L("周期 8/1 – 8/31 · 日粒度可用"))
        )
    )
    NavigationStack {
        SetupCredentialsStepView(model: model)
            .task { await model.prepare() }
    }
}

#Preview("Theoretical failure") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .vercel,
        step: .credentials,
        outcome: .http(
            ErrorCase(
                httpStatus: 403,
                explanation: String(localized: L("这个 token 缺权限，所以读不到账单。")),
                nextStep: String(localized: L("回上一步检查权限后再测一次。"))
            )
        )
    )
    NavigationStack {
        SetupCredentialsStepView(model: model)
            .task { await model.prepare() }
    }
}
