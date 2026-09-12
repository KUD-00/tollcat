#if DEBUG
import SwiftUI
import MeterDesign
import MeterFeedback
import MeterProviders

/// 测试连接的铺色和成败消息。点一下就能看，不必走真实 API。
struct GalleryVerifyConnectionView: View {
    @State private var phase: FillProgressPhase = .idle
    @State private var outcome: SetupVerifyOutcome?
    @State private var failureToken = 0
    @State private var runID = 0
    @State private var token = ""
    @State private var account = ""
    @FocusState private var focused: String?

    var body: some View {
        MeterGroupedList {
            Section {
                SetupVerifyResultView(outcome: GalleryFixtures.verified)
            } header: {
                Text(L("测一次成功"))
            }
            Section {
                SetupVerifyResultView(outcome: GalleryFixtures.unauthorized)
            } header: {
                Text(L("测一次失败"))
            }

            Section {
                CredentialFieldRow(
                    title: "API Token",
                    fieldID: "token",
                    text: $token,
                    focusedField: $focused
                )
                CredentialFieldRow(
                    title: "Account ID",
                    fieldID: "account",
                    text: $account,
                    focusedField: $focused
                )
                if let outcome {
                    SetupVerifyResultView(outcome: outcome)
                }
            } header: {
                Text(L("凭据"))
            } footer: {
                Text(L("绿色从左到右盖住按钮。失败会震动一次。画廊不会写入 Keychain。"))
            }

            if let outcome {
                SetupFeedbackSection(
                    providerName: "Vercel",
                    outcome: outcome,
                    exchanges: [
                        HTTPExchange(
                            summary: "GET https://api.vercel.com/v2/user\nHTTP 200",
                            body: #"{"spend": 11.05}"#
                        ),
                    ],
                    focusedField: $focused,
                    submitter: StubFeedbackSubmitter()
                )
                .id(String(describing: outcome))
            }

            Section {
                Button(L("测一次成功")) { run(succeed: true) }
                    .disabled(phase == .progressing)
                    .accessibilityHint(L("主按钮被绿色从左到右盖住，然后在凭据下面写出金额"))
                Button(L("测一次失败")) { run(succeed: false) }
                    .disabled(phase == .progressing)
                    .accessibilityHint(L("绿色走完后凭据下面出现错误，并震动一次"))
                Button(L("重置")) { reset() }
                    .disabled(phase == .progressing)
            } header: {
                Text(L("交互"))
            }
        }
        .meterKeyboardDismiss {
            focused = nil
        }
        .navigationTitle(L("测试连接"))
        .navigationBarTitleDisplayMode(.inline)
        .meterPrimaryActionBar {
            FillProgressButton(
                String(
                    localized: phase == .completed
                        ? L("保存到 Keychain")
                        : L("测试连接")
                ),
                phase: phase,
                isEnabled: phase != .completed && !token.isEmpty && !account.isEmpty
            ) {
                run(succeed: true)
            }
        }
        .sensoryFeedback(.error, trigger: failureToken)
    }

    private func run(succeed: Bool) {
        runID += 1
        let id = runID
        outcome = nil
        phase = .progressing
        Task {
            try? await Task.sleep(for: .milliseconds(1200))
            guard id == runID else { return }
            if succeed {
                outcome = GalleryFixtures.verified
                phase = .completed
            } else {
                outcome = GalleryFixtures.unauthorized
                phase = .idle
                failureToken += 1
            }
        }
    }

    private func reset() {
        runID += 1
        phase = .idle
        outcome = nil
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryVerifyConnectionView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryVerifyConnectionView()
    }
    .preferredColorScheme(.dark)
}
#endif
