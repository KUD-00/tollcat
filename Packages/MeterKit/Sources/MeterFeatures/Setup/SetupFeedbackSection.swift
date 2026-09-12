import MeterCore
import SwiftUI
import MeterDesign
import MeterFeedback
import MeterPersistence
import MeterProviders

/// 测完连接之后出现的那一节。底栏仍是测试 / 保存，发送是这一节里的一行。
struct SetupFeedbackSection: View {
    @State private var model: FeedbackModel
    var focusedField: FocusState<String?>.Binding
    let outcome: SetupVerifyOutcome
    let exchanges: [HTTPExchange]

    init(
        providerName: String,
        outcome: SetupVerifyOutcome,
        exchanges: [HTTPExchange] = [],
        focusedField: FocusState<String?>.Binding,
        submitter: (any FeedbackSubmitting)? = nil
    ) {
        self.outcome = outcome
        self.exchanges = exchanges
        self.focusedField = focusedField
        _model = State(
            initialValue: FeedbackModel.setupReport(
                providerName: providerName,
                outcome: outcome,
                submitter: submitter
            )
        )
    }

    var body: some View {
        Section {
            if model.outcome == .sent {
                Text(L("收到了，谢谢。"))
                    .font(MeterFont.body)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(L("收到了，谢谢。"))
            } else {
                compose
            }
        } header: {
            Text(L("反馈"))
        } footer: {
            if model.outcome != .sent {
                footer
            }
        }
    }

    @ViewBuilder
    private var compose: some View {
        Text(SetupFeedbackCopy.lede(for: outcome))
            .font(MeterFont.footnote)
            .foregroundStyle(Color.meterSecondaryLabel)
            .fixedSize(horizontal: false, vertical: true)

        TextField(
            L("说什么都行"),
            text: $model.message,
            axis: .vertical
        )
        .lineLimit(3...8)
        .focused(focusedField, equals: "setup-feedback-message")
        .accessibilityLabel(L("反馈内容"))

        TextField(L("邮箱或任意联系方式"), text: $model.contact)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.emailAddress)
            .submitLabel(.done)
            .focused(focusedField, equals: "setup-feedback-contact")
            .onSubmit { focusedField.wrappedValue = nil }
            .accessibilityLabel(L("联系方式"))

        LabeledContent(L("服务")) {
            Text(verbatim: model.attachedProviderNames.joined(separator: "、"))
        }

        if !exchanges.isEmpty {
            Toggle(isOn: $model.includesExchange) {
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    Text(L("附带这次测试的 HTTP 响应"))
                    ListRowNote(text: L("密钥和账单数字会打码。用来看接口到底回了什么。"))
                }
            }
            .accessibilityLabel(L("附带这次测试的 HTTP 响应"))
        }

        Button {
            Task { await model.submit(exchange: SetupFeedbackExchange.outboundText(exchanges)) }
        } label: {
            HStack(spacing: MeterSpacing.xs) {
                if model.isSubmitting {
                    ProgressView()
                }
                Text(L("发送"))
            }
        }
        .disabled(!model.canSubmit)
        .accessibilityLabel(L("发送"))

        if let outcome = model.outcome {
            Text(caption(for: outcome))
                .font(MeterFont.footnote)
                .foregroundStyle(MeterColor.crit)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var footer: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            if model.showsRemainingCharacters {
                Text(L("还能写 \(model.remainingCharacters) 字"))
                    .monospacedDigit()
                    .foregroundStyle(
                        model.remainingCharacters < 0
                            ? MeterColor.crit
                            : Color.meterSecondaryLabel
                    )
            }
            Text(
                model.includesExchange
                    ? L("发出去的是服务名、版本、系统、机型、语言，以及打过码的 HTTP 摘要。")
                    : L("发出去的是服务名、版本、系统、机型、语言。没有账单金额，没有密钥。")
            )
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

#Preview("Success · Light") {
    @Previewable @FocusState var focused: String?
    Form {
        SetupFeedbackSection(
            providerName: "Vercel",
            outcome: .success(
                title: String(localized: L("本周期至今 $11.05")),
                detail: String(localized: L("周期 8/1 – 8/31 · 日粒度可用"))
            ),
            exchanges: [
                HTTPExchange(
                    summary: "GET https://api.vercel.com/v2/user\nHTTP 200",
                    body: "{}"
                ),
            ],
            focusedField: $focused,
            submitter: StubFeedbackSubmitter()
        )
    }
    .formStyle(.grouped)
    .meterGroupedRowButtons()
    .meterGroupedSectionCard()
    .preferredColorScheme(.light)
}

#Preview("Failure · Dark") {
    @Previewable @FocusState var focused: String?
    Form {
        SetupFeedbackSection(
            providerName: "Vercel",
            outcome: .http(
                ErrorCase(
                    httpStatus: 403,
                    explanation: String(localized: L("这个 token 缺权限，所以读不到账单。")),
                    nextStep: String(localized: L("回上一步检查权限后再测一次。"))
                )
            ),
            focusedField: $focused,
            submitter: StubFeedbackSubmitter()
        )
    }
    .formStyle(.grouped)
    .meterGroupedRowButtons()
    .meterGroupedSectionCard()
    .preferredColorScheme(.dark)
}
