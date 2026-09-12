import MeterCore
import SwiftUI
import MeterDesign
import MeterPersistence

struct SetupWizardView: View {
    @State private var model: SetupWizardModel
    /// 信箱那条路的状态机。和 `model` 并存而不是塞进去：
    /// 它没有凭据、没有测试连接，硬合并会让两条流程互相污染。
    @State private var inboxModel: InboxHandoffModel
    var onFinished: (() -> Void)? = nil
    /// 连接参考抽屉按正文收高度。Pad 并排、预览不用。
    var reportedContentHeight: Binding<CGFloat>? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.usesPadChrome) private var usesPadChrome

    init(
        model: SetupWizardModel,
        onFinished: (() -> Void)? = nil,
        reportedContentHeight: Binding<CGFloat>? = nil
    ) {
        _model = State(initialValue: model)
        _inboxModel = State(
            initialValue: InboxHandoffModel(
                providerID: model.providerID,
                dashboard: model.dashboard,
                attachingAccountID: model.attachingAccountID ?? model.rotatingAccountID
            )
        )
        self.onFinished = onFinished
        self.reportedContentHeight = reportedContentHeight
    }

    var body: some View {
        @Bindable var model = model
        @Bindable var inboxModel = inboxModel
        Group {
            if usesPadChrome {
                SetupWizardPadLayout(
                    model: model,
                    inboxModel: inboxModel,
                    onOpenConsole: { openURL($0) },
                    onSaved: { finish() },
                    onClose: { finish() }
                )
            } else {
                phoneWizard
            }
        }
        .task {
            await model.prepare()
            // 已经是 true 的 isPresented 在首帧不会推页，所以凭据步要在 prepare 之后再切。
            if FeatureLaunchArguments.openSetupCredentials {
                model.step = .credentials
            }
            model.applyLaunchOutcome(FeatureLaunchArguments.setupOutcome)
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: model.copyToken)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: model.saveToken)
        .onChange(of: model.saveToken) { _, token in
            if token > 0 { finish() }
        }
        .onChange(of: inboxModel.saveToken) { _, token in
            if token > 0 { finish() }
        }
    }

    private func finish() {
        // sheet 里再推 NavigationStack 时，这里的 dismiss 往往只 pop 凭据页。
        // 关掉整个抽屉必须走 onFinished 写回 isPresented。
        if let onFinished {
            onFinished()
        } else {
            dismiss()
        }
    }

    private var credentialsPresented: Binding<Bool> {
        Binding(
            get: { model.step == .credentials },
            set: { presented in
                if !presented {
                    model.returnToGuide()
                }
            }
        )
    }

    private var phoneWizard: some View {
        guidePages
    }

    private var guidePages: some View {
        wizardPage {
            SetupGuideStepView(
                model: model,
                onOpenConsole: { openURL($0) },
                reportedContentHeight: reportedContentHeight
            )
        }
        .navigationTitle(L("\(model.displayName)连接参考"))
        // 先收成一个元素再挂 id，否则 id 会铺给页内所有子元素、盖掉主按钮的 setup.next。
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(UITestID.setupGuide)
        .navigationDestination(isPresented: credentialsPresented) {
            wizardPage {
                if model.usesInbox {
                    InboxHandoffStepView(model: inboxModel, onSaved: { finish() })
                } else {
                    SetupCredentialsStepView(model: model, onSaved: { finish() })
                }
            }
            .navigationTitle(L("连接\(model.displayName)"))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(UITestID.setupCredentials)
        }
    }

    private func wizardPage<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .meterNavigationContainerBackground(Color.meterGroupedBackground)
            .navigationSubtitle(Text(wizardProgressDigits))
            .accessibilityHint(wizardProgressSpoken)
            .meterSheetClose { finish() }
    }

    private var wizardProgressDigits: String {
        "\(model.step.displayNumber) / \(SetupWizardStep.totalCount)"
    }

    private var wizardProgressSpoken: String {
        String(
            localized: L(
                "第 \(model.step.displayNumber) 步，共 \(SetupWizardStep.totalCount) 步"
            )
        )
    }
}

#Preview("Guide · Light") {
    @Previewable @State var model = SetupWizardModel.preview(providerID: .cloudflare, step: .guide)
    NavigationStack {
        SetupWizardView(model: model)
    }
    .preferredColorScheme(.light)
}

#Preview("Guide · Dark") {
    @Previewable @State var model = SetupWizardModel.preview(providerID: .anthropic, step: .guide)
    NavigationStack {
        SetupWizardView(model: model)
    }
    .preferredColorScheme(.dark)
}

#Preview("Guide · AWS") {
    @Previewable @State var model = SetupWizardModel.preview(providerID: .aws, step: .guide)
    NavigationStack {
        SetupWizardView(model: model)
    }
}

#Preview("Credentials · Light") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .credentials,
        outcome: .success(title: String(localized: L("本周期至今 $11.05")), detail: String(localized: L("周期 8/1 – 8/31 · 日粒度可用")))
    )
    NavigationStack {
        SetupWizardView(model: model)
    }
    .preferredColorScheme(.light)
}

#Preview("401") {
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
        SetupWizardView(model: model)
    }
}

#Preview("403") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .credentials,
        outcome: .http(
            ErrorCase(
                httpStatus: 403,
                explanation: String(localized: L("这个 token 缺 Billing:Read 权限，所以读不到账单。")),
                nextStep: String(localized: L("回上一步按 Custom token 重建，只勾 Account · Billing · Read，不要给任何 Edit。"))
            )
        )
    )
    NavigationStack {
        SetupWizardView(model: model)
    }
}

#Preview("Network") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .credentials,
        outcome: .network
    )
    NavigationStack {
        SetupWizardView(model: model)
    }
}

#Preview("Slow") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .credentials
    )
    NavigationStack {
        SetupWizardView(model: {
            model.isTesting = true
            model.fieldValues = ["apiToken": "preview-token", "accountID": "preview-account"]
            return model
        }())
    }
}

#Preview("Empty reading") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .credentials,
        outcome: .emptyReading
    )
    NavigationStack {
        SetupWizardView(model: model)
    }
}

#Preview("XXL") {
    @Previewable @State var model = SetupWizardModel.preview(providerID: .cloudflare, step: .guide)
    NavigationStack {
        SetupWizardView(model: model)
    }
    .dynamicTypeSize(.accessibility3)
}
