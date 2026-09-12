import SwiftUI
import MeterDesign
import MeterProviders

struct AboutView: View {
    var versionCaption: String
    @Environment(\.appUpdateChecker) private var updateChecker

    var body: some View {
        MeterGroupedList {
            Section {
                LabeledContent(L("版本")) {
                    Text(versionCaption)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .monospacedDigit()
                }
                // 只有 Mac 直发壳挂了更新器才有这一行。App Store 版由系统更新，不该在这里再放一个入口。
                if let updateChecker {
                    Button(L("检查更新…")) {
                        updateChecker.checkForUpdates()
                    }
                    .disabled(!updateChecker.canCheck)
                }
                LabeledContent(L("开源许可")) {
                    Text("MIT")
                        .foregroundStyle(Color.meterSecondaryLabel)
                }
                SafariLink(L("源代码"), destination: LegalURL.source)
            } footer: {
                Text(L("服务图标来自 Simple Icons，以 CC0 1.0 公共领域许可使用。\n\n凭据和账单只存在这台设备上，不会上传，也不进 iCloud 备份。"))
            }

            Section {
                SafariLink(L("隐私政策"), destination: LegalURL.privacy)
                SafariLink(L("支持"), destination: LegalURL.support)
            }

            Section {
                // `visible` 不是 `all`：只有 Mac 直发版会连的更新通道不列在 iPhone 上。
                ForEach(OutboundHosts.visible) { item in
                    VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                        Text(item.host)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(item.purpose)
                            .font(MeterFont.footnote)
                            .foregroundStyle(Color.meterSecondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                // 名单太长，这段说明不能再放 section footer，进页就要看见。
                // `.textCase(.none)`：这段跟着 header 会被改成全大写。
                VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                    Text(L("出站域名"))
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .textCase(.uppercase)
                        .accessibilityAddTraits(.isHeader)
                    Text(L("App 只会向这些域名发起请求。账单凭据和账单数据留在这台设备上；打赏留言、反馈和匿名页面计数只发到清单里标注给我们自己服务器的那一项。内购由系统走 Apple，不在这张表里。"))
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .multilineTextAlignment(.leading)
                        .textCase(.none)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(L("关于"))
        .toolbarTitleDisplayMode(.inlineLarge)
    }
}

#Preview("Light") {
    NavigationStack {
        AboutView(versionCaption: "0.1.0 (1)")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        AboutView(versionCaption: "0.1.0 (1)")
    }
    .preferredColorScheme(.dark)
}
