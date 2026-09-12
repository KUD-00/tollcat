import MeterCore
import SwiftUI
import MeterDesign
import MeterPersistence

/// 六种失败/空读数靠图标和文案区分，不铺色块。
struct SetupFailureBanner: View {
    let outcome: SetupVerifyOutcome
    var onRevisePermissions: (() -> Void)? = nil

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(title)
                    .font(MeterFont.body)
                    .foregroundStyle(Color.meterLabel)
                if !explanation.isEmpty {
                    Text(explanation)
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let nextStep, !nextStep.isEmpty {
                    Text(nextStep)
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if outcome.offersRevisePermissions, let onRevisePermissions {
                    Button(L("回上一步改权限"), action: onRevisePermissions)
                        .padding(.top, MeterSpacing.xxs)
                        .accessibilityLabel(L("回上一步改权限"))
                }
            }
        } icon: {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
        }
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        switch outcome {
        case .success:
            return ""
        case .emptyReading:
            return String(localized: L("连上了，但没有读到金额"))
        case .http(let errorCase):
            return "\(errorCase.httpStatus)"
        case .network:
            return String(localized: L("网络不可用"))
        case .unknown:
            return String(localized: L("没能完成测试"))
        }
    }

    private var explanation: String {
        switch outcome {
        case .success:
            return ""
        case .emptyReading:
            return String(localized: L("这次返回里没有任何账单数字，不能当成 $0。"))
        case .http(let errorCase):
            return errorCase.explanation
        case .network:
            return String(localized: L("请求没有到达服务器，不是凭据或权限的问题。"))
        case .unknown:
            return String(localized: L("没有取到账单，也没有对应的 HTTP 状态。"))
        }
    }

    private var nextStep: String? {
        switch outcome {
        case .success:
            return nil
        case .emptyReading:
            return String(localized: L("先别保存，回上一步检查权限后再测一次。"))
        case .http(let errorCase):
            return errorCase.nextStep
        case .network:
            return String(localized: L("过一会儿再试。如果一直这样，先确认设备在线。"))
        case .unknown:
            return String(localized: L("回上一步检查填写的内容，再测一次。"))
        }
    }

    private var tint: Color {
        switch outcome {
        case .success:
            return .green
        case .emptyReading:
            return .orange
        case .http(let errorCase):
            return errorCase.httpStatus == 401 ? .red : .orange
        case .network:
            return Color.meterSecondaryLabel
        case .unknown:
            return .red
        }
    }

    private var symbolName: String {
        switch outcome {
        case .success:
            return "checkmark.circle.fill"
        case .emptyReading:
            return "questionmark.circle.fill"
        case .http(let errorCase):
            return errorCase.httpStatus == 401
                ? "person.crop.circle.badge.xmark"
                : "lock.slash.fill"
        case .network:
            return "wifi.slash"
        case .unknown:
            return "exclamationmark.circle.fill"
        }
    }
}

#Preview("401 · Light") {
    Form {
        Section {
            SetupFailureBanner(
                outcome: .http(
                    ErrorCase(
                        httpStatus: 401,
                        explanation: String(localized: L("这个 token 无效，或者已经被撤销了。")),
                        nextStep: String(localized: L("回上一步重新创建一把，创建后立刻复制——它只显示一次。"))
                    )
                )
            )
        }
    }
    .preferredColorScheme(.light)
}

#Preview("403 · Dark") {
    Form {
        Section {
            SetupFailureBanner(
                outcome: .http(
                    ErrorCase(
                        httpStatus: 403,
                        explanation: String(localized: L("这个 token 缺 Billing:Read 权限，所以读不到账单。")),
                        nextStep: String(localized: L("回上一步按 Custom token 重建，只勾 Account · Billing · Read，不要给任何 Edit。"))
                    )
                )
            )
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Network") {
    Form {
        Section {
            SetupFailureBanner(outcome: .network)
        }
    }
}

#Preview("Empty") {
    Form {
        Section {
            SetupFailureBanner(outcome: .emptyReading)
        }
    }
}

#Preview("Unknown") {
    Form {
        Section {
            SetupFailureBanner(outcome: .unknown)
        }
    }
}
