import SwiftUI
import MeterCore
import MeterDesign

/// 详情里「管理凭据」从右侧推进。列出这家已接入的用量身份：点进去重填，划掉删除，底下再接一份。
struct CredentialManagementSheet: View {
    @Bindable var model: ProviderDetailModel
    @Environment(\.dismiss) private var dismiss
    @State private var setup: SetupPresentation?
    @State private var accountPendingDeletion: AccountID?

    private enum SetupPresentation: Identifiable {
        case rotate(AccountID)
        case create

        var id: String {
            switch self {
            case .rotate(let accountID):
                return "rotate-\(accountID.rawValue.uuidString)"
            case .create:
                return "create"
            }
        }
    }

    var body: some View {
        Form {
            Section {
                ForEach(model.credentialItems) { item in
                    accountRow(item)
                        .swipeActions {
                            Button(L("删除"), role: .destructive) {
                                accountPendingDeletion = item.accountID
                            }
                        }
                        // Mac 的 grouped Form 没有划动：删除走右键菜单。
                        #if os(macOS)
                        .contextMenu {
                            Button(L("删除"), role: .destructive) {
                                accountPendingDeletion = item.accountID
                            }
                        }
                        #endif
                }
                if model.supportsUsageSetup {
                    Button {
                        setup = .create
                    } label: {
                        Text(L("再接一笔按量账单"))
                    }
                }
            } footer: {
                if model.supportsUsageSetup {
                    Text(L("再接一个 \(model.displayName) 账号。测通成功后再起昵称。"))
                }
            }
        }
        .formStyle(.grouped)
        .meterGroupedRowButtons()
        .meterGroupedSectionCard()
        .navigationTitle(L("管理凭据"))
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            L("删除这个账号？"),
            isPresented: isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button(L("删除"), role: .destructive) {
                deletePendingAccount()
            }
            Button(L("取消"), role: .cancel) {
                accountPendingDeletion = nil
            }
        } message: {
            Text(L("会连带删掉 Keychain 里对应的凭据。历史读数留在本机，不再计入总额。"))
        }
        .sheet(item: $setup) { presentation in
            setupSheet(presentation)
        }
        .onChange(of: model.usageAccounts.isEmpty) { _, isEmpty in
            if isEmpty { dismiss() }
        }
    }

    private var isConfirmingDelete: Binding<Bool> {
        Binding(
            get: { accountPendingDeletion != nil },
            set: { if !$0 { accountPendingDeletion = nil } }
        )
    }

    @ViewBuilder
    private func accountRow(_ item: CredentialManagementItem) -> some View {
        if item.canRotate {
            Button {
                setup = .rotate(item.accountID)
            } label: {
                accountLabel(item)
                    .meterListRowHitTarget()
            }
            .buttonStyle(.plain)
            .accessibilityHint(L("重新填写凭据"))
        } else {
            accountLabel(item)
        }
    }

    private func accountLabel(_ item: CredentialManagementItem) -> some View {
        HStack(spacing: MeterSpacing.sm) {
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(item.title)
                Text(item.caption)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
            }
            Spacer(minLength: 0)
            if item.canRotate {
                Image(systemName: "chevron.right")
                    .font(MeterFont.footnote.weight(.semibold))
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func setupSheet(_ presentation: SetupPresentation) -> some View {
        switch presentation {
        case .rotate(let accountID):
            UsageSetupSheet(
                model: SetupWizardModel(
                    mode: .rotate(accountID, model.providerID),
                    dashboard: model.dashboard
                ),
                onFinished: { setup = nil }
            )
        case .create:
            UsageSetupSheet(
                model: SetupWizardModel(
                    mode: .create(model.providerID),
                    dashboard: model.dashboard
                ),
                onFinished: { setup = nil }
            )
        }
    }

    private func deletePendingAccount() {
        guard let accountID = accountPendingDeletion else { return }
        accountPendingDeletion = nil
        Task {
            await model.deleteUsageAccount(accountID)
            if model.usageAccounts.isEmpty {
                dismiss()
            }
        }
    }
}

#Preview("Light") {
    NavigationStack {
        CredentialManagementSheet(model: .preview(.cloudflare))
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        CredentialManagementSheet(model: .preview(.openai))
    }
    .preferredColorScheme(.dark)
}

#Preview("Two accounts") {
    NavigationStack {
        CredentialManagementSheet(
            model: ProviderDetailModel(
                providerID: .cloudflare,
                dashboard: .previewTwoCloudflare
            )
        )
    }
}

#Preview("XXL") {
    NavigationStack {
        CredentialManagementSheet(model: .preview(.cloudflare))
    }
    .dynamicTypeSize(.accessibility3)
}

#Preview("Pad") {
    NavigationStack {
        CredentialManagementSheet(model: .preview(.cloudflare))
    }
    .environment(\.meterShell, .pad)
}
