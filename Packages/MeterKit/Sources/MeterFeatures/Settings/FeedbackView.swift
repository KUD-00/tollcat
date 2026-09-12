import SwiftUI
import MeterDesign
import MeterFeedback

struct FeedbackView: View {
    @State private var model: FeedbackModel
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case message
        case contact
    }

    init(model: FeedbackModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        MeterGroupedList {
            categorySection
            messageSection
            contactSection
            environmentSection
        }
        .navigationTitle(L("反馈"))
        .navigationBarTitleDisplayMode(.large)
        .meterKeyboardDismiss {
            focusedField = nil
        }
        .meterPrimaryActionBar {
            VStack(spacing: MeterSpacing.xs) {
                Button {
                    Task { await model.submit() }
                } label: {
                    HStack(spacing: MeterSpacing.xs) {
                        if model.isSubmitting {
                            ProgressView()
                        }
                        Text(L("发送"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .meterPrimaryActionStyle()
                .disabled(!model.canSubmit)

                if let outcome = model.outcome {
                    Text(caption(for: outcome))
                        .font(MeterFont.footnote)
                        .foregroundStyle(
                            outcome == .sent ? Color.meterSecondaryLabel : MeterColor.crit
                        )
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var categorySection: some View {
        Section {
            Picker(L("类型"), selection: $model.category) {
                ForEach(FeedbackCategory.allCases, id: \.self) { category in
                    Text(title(for: category)).tag(category)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel(L("反馈类型"))
        }
    }

    private var messageSection: some View {
        Section {
            TextField(
                L("说什么都行"),
                text: $model.message,
                axis: .vertical
            )
            .lineLimit(5...12)
            .focused($focusedField, equals: .message)
            .accessibilityLabel(L("反馈内容"))
        } footer: {
            if model.showsRemainingCharacters {
                Text(L("还能写 \(model.remainingCharacters) 字"))
                    .monospacedDigit()
                    .foregroundStyle(
                        model.remainingCharacters < 0 ? MeterColor.crit : Color.meterSecondaryLabel
                    )
            }
        }
    }

    private var contactSection: some View {
        Section {
            TextField(L("邮箱或任意联系方式"), text: $model.contact)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .submitLabel(.done)
                .focused($focusedField, equals: .contact)
                .onSubmit { focusedField = nil }
                .accessibilityLabel(L("联系方式"))
        } header: {
            Text(L("联系方式（可留空）"))
        }
    }

    /// 会一起发出去的东西，一项不落地摆出来。
    ///
    /// 这一节不是免责声明，是这个 App 的立场：其他地方一直在说
    /// 「凭据只存在你自己的手机上」，那么唯一一条主动往外发的路
    /// 就必须能被逐项看清，否则前面那句话不值钱。
    private var environmentSection: some View {
        Section {
            LabeledContent(L("版本")) {
                Text(model.environment.appVersion).monospacedDigit()
            }
            LabeledContent(L("系统")) {
                Text(model.environment.osVersion).monospacedDigit()
            }
            LabeledContent(L("机型")) {
                Text(verbatim: model.environment.deviceModel)
            }
            LabeledContent(L("语言")) {
                Text(verbatim: model.environment.locale)
            }
            Toggle(isOn: $model.includesProviderList) {
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    Text(L("附带已接入的服务名单"))
                    ListRowNote(text: attachedCaption)
                }
            }
        } header: {
            Text(L("会一起发过去"))
        } footer: {
            Text(L("没有账单金额，没有 API 密钥，没有设备标识。这一节列出的就是全部。"))
        }
    }

    private var attachedCaption: LocalizedStringResource {
        let names = model.attachedProviderNames
        guard !names.isEmpty else {
            return L("只有服务名，没有金额也没有凭据。")
        }
        return L("会带上：\(names.joined(separator: "、"))")
    }

    private func title(for category: FeedbackCategory) -> LocalizedStringResource {
        switch category {
        case .bug: L("哪里坏了")
        case .idea: L("想要什么")
        case .provider: L("想接哪家服务")
        case .other: L("其他")
        }
    }

    private func caption(for outcome: FeedbackModel.Outcome) -> LocalizedStringResource {
        switch outcome {
        case .sent: L("收到了，谢谢。")
        case .rateLimited: L("刚才提得有点密，过十分钟再来。")
        case .failed: L("没发出去。内容还在，检查一下网络再试。")
        }
    }
}

#Preview("Light") {
    NavigationStack {
        FeedbackView(
            model: FeedbackModel(
                submitter: StubFeedbackSubmitter(),
                environment: .preview,
                connectedProviderNames: { ["AWS", "Cloudflare", "OpenAI"] }
            )
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        FeedbackView(
            model: FeedbackModel(
                submitter: StubFeedbackSubmitter(),
                environment: .preview,
                connectedProviderNames: { ["AWS", "Cloudflare", "OpenAI"] }
            )
        )
    }
    .preferredColorScheme(.dark)
}

extension FeedbackEnvironmentInfo {
    static let preview = FeedbackEnvironmentInfo(
        appVersion: "0.1.0 (1)",
        osVersion: "iOS 26.0",
        deviceModel: "iPhone17,1",
        locale: "zh-Hans_CN"
    )
}
