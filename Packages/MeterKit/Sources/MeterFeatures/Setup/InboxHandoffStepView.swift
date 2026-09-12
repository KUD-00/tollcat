import SwiftUI
import MeterDesign

/// 走读数信箱那几家的连接页。
///
/// 这一页交出去两样东西，而且**故意分开**：
/// 上面是任务书（不含密钥，粘到哪个 LLM 都无所谓），下面是投递 key
/// （单独一次点按，配一句为什么不建议直接贴给 AI）。
struct InboxHandoffStepView: View {
    @Bindable var model: InboxHandoffModel
    var onSaved: () -> Void = {}
    /// 同 `SetupCredentialsStepView.onClose`。
    var onClose: (() -> Void)? = nil
    @State private var isPromptExpanded = false
    @FocusState private var focusedNickname: NicknameField?

    private enum NicknameField: Hashable {
        case sibling
        case new
    }

    /// 折叠时露出的行数。够看出「这是一段给 AI 的中文任务书」，又不占满屏。
    private static let collapsedLineLimit = 6

    var body: some View {
        Form {
            switch model.phase {
            case .idle, .provisioning:
                provisioningSection
            case .failed:
                failureSection
            case .issued:
                promptSection
                keySection
                nicknameSection
            }
        }
        .formStyle(.grouped)
        .meterGroupedRowButtons()
        .meterGroupedSectionCard()
        .meterSheetClose(isActive: onClose != nil) { onClose?() }
        .meterKeyboardDismiss {
            focusedNickname = nil
        }
        .meterPrimaryActionBar(ignoresKeyboard: true) {
            Button {
                Task {
                    try? await model.connect()
                    if model.saveToken > 0 {
                        onSaved()
                    }
                }
            } label: {
                Text(L("接入，等第一次投递"))
                    .frame(maxWidth: .infinity)
            }
            .meterPrimaryActionStyle()
            .disabled(!model.canConnect)
        }
        .task { await model.prepare() }
        .onDisappear {
            Task { await model.discardIfUnconnected() }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: model.copyToken)
        .sensoryFeedback(.success, trigger: model.saveToken)
    }

    private var provisioningSection: some View {
        Section {
            HStack(spacing: MeterSpacing.sm) {
                ProgressView()
                Text(L("正在创建你的读数信箱…"))
                    .foregroundStyle(Color.meterSecondaryLabel)
            }
            .frame(minHeight: MeterSpacing.minTap)
        }
    }

    private var failureSection: some View {
        Section {
            VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                Text(L("没能创建信箱"))
                    .font(MeterFont.bodyEmphasized)
                Text(failureExplanation)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
            }
            Button(L("重试")) {
                Task { await model.retry() }
            }
        }
    }

    /// 任务书直接露出来，右上角一个复制图标，下面「展开全文」。
    ///
    /// 不用「大按钮 + 默认什么都不显示的折叠行」：那样用户在点复制之前
    /// 完全不知道自己要复制的是什么东西。先让他看见，再让他复制。
    private var promptSection: some View {
        Section {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                    Text(model.prompt)
                        // footnote 而不是 body：body 尺寸的 mono 会把那条 URL 断成三行。
                        .font(.footnote.monospaced())
                        .foregroundStyle(Color.meterLabel)
                        .textSelection(.enabled)
                        .lineLimit(isPromptExpanded ? nil : Self.collapsedLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                        // 给右上角那个图标让出位置，免得首行文字压在它下面。
                        .padding(.trailing, MeterSpacing.xl)

                    Button {
                        withAnimation(.snappy) { isPromptExpanded.toggle() }
                    } label: {
                        Text(isPromptExpanded ? L("收起") : L("展开全文"))
                            .font(MeterFont.footnote)
                            .frame(minHeight: MeterSpacing.minTap)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                }

                Button {
                    model.copyPrompt()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .frame(width: MeterSpacing.minTap, height: MeterSpacing.minTap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
                .accessibilityLabel(L("复制任务书"))
            }
        } header: {
            Text(L("交给 AI 的任务书"))
        } footer: {
            Text(L("把这段话粘给 Claude Code、Cursor 或者任何能上网的 AI，让它替你写抓取脚本。这段话里没有密钥，可以放心粘。"))
        }
    }

    private var keySection: some View {
        Section {
            if let key = model.issuedKey {
                CopyBox(key.secret, copyTitle: String(localized: L("复制"))) {
                    model.copyIngestKey()
                }
            }
        } header: {
            Text(L("投递 key"))
        } footer: {
            Text(L("这是密钥，只显示这一次。建议把它放进脚本的环境变量 TOLL_INGEST_KEY，而不是直接贴给 AI。丢了不要紧，回设置里再签一把就行。接入之后这家会先显示「等待投递」，等你的脚本第一次上报，数字就出来了。"))
        }
    }

    @ViewBuilder
    private var nicknameSection: some View {
        if model.showsNicknameFields {
            Section {
                TextField(L("已有账号"), text: $model.siblingNickname)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedNickname, equals: .sibling)
                TextField(L("新账号"), text: $model.newNickname)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedNickname, equals: .new)
            } header: {
                Text(L("怎么区分这两份"))
            } footer: {
                Text(L("第二份必须起个昵称。保存时也会把已有那份现在的名字写回去。"))
            }
        }
    }

    private var failureExplanation: LocalizedStringResource {
        switch model.failure?.code {
        case .unreachable, .none:
            L("连不上服务器。检查一下网络，已经接入的其它服务不受影响。")
        case .rateLimited:
            L("创建得太频繁了，等一会儿再试。")
        case .unauthorized, .malformedResponse:
            L("服务器返回了意料之外的结果。稍后再试一次。")
        }
    }
}

#Preview("Light · 拿到 key") {
    NavigationStack {
        InboxHandoffStepView(model: .preview(phase: .issued))
            .navigationTitle("Render")
            .navigationBarTitleDisplayMode(.inline)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark · 拿到 key") {
    NavigationStack {
        InboxHandoffStepView(model: .preview(phase: .issued))
            .navigationTitle("Render")
            .navigationBarTitleDisplayMode(.inline)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light · 建信箱失败") {
    NavigationStack {
        InboxHandoffStepView(model: .preview(phase: .failed))
            .navigationTitle("Render")
            .navigationBarTitleDisplayMode(.inline)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark · 正在创建") {
    NavigationStack {
        InboxHandoffStepView(model: .preview(phase: .provisioning))
            .navigationTitle("Render")
            .navigationBarTitleDisplayMode(.inline)
    }
    .preferredColorScheme(.dark)
}
