import MeterCore
import SwiftUI
import MeterDesign
import MeterPersistence

/// 测连接之后写在「凭据」字段下面的那条结果。成功是金额，失败是原因和怎么修。
struct SetupVerifyResultView: View {
    let outcome: SetupVerifyOutcome
    var onRevisePermissions: (() -> Void)? = nil

    var body: some View {
        switch outcome {
        case .success(let title, let detail):
            Label {
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    Text(title)
                        .font(MeterFont.body)
                        .foregroundStyle(Color.meterLabel)
                        .monospacedDigit()
                    Text(detail)
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            .accessibilityElement(children: .combine)
        case .http, .network, .emptyReading, .unknown:
            SetupFailureBanner(outcome: outcome, onRevisePermissions: onRevisePermissions)
        }
    }
}

#Preview("Success · Light") {
    Form {
        Section {
            SetupVerifyResultView(
                outcome: .success(
                    title: String(localized: L("本周期至今 $11.05")),
                    detail: String(localized: L("周期 8/1 – 8/31 · 日粒度可用"))
                )
            )
        } header: {
            Text(L("凭据"))
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Success · Dark") {
    Form {
        Section {
            SetupVerifyResultView(
                outcome: .success(
                    title: String(localized: L("本周期至今 $11.05")),
                    detail: String(localized: L("周期 8/1 – 8/31 · 日粒度可用"))
                )
            )
        } header: {
            Text(L("凭据"))
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("401 · Light") {
    Form {
        Section {
            SetupVerifyResultView(
                outcome: .http(
                    ErrorCase(
                        httpStatus: 401,
                        explanation: String(localized: L("这个 token 无效，或者已经被撤销了。")),
                        nextStep: String(localized: L("回上一步重新创建一把，创建后立刻复制——它只显示一次。"))
                    )
                )
            )
        } header: {
            Text(L("凭据"))
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Network · Dark") {
    Form {
        Section {
            SetupVerifyResultView(outcome: .network)
        } header: {
            Text(L("凭据"))
        }
    }
    .preferredColorScheme(.dark)
}
