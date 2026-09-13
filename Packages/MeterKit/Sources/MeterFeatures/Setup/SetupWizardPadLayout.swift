import SwiftUI
import MeterDesign

/// 横屏 iPad：左边教程，右边填表。手机仍然一步一页。
struct SetupWizardPadLayout: View {
    @Bindable var model: SetupWizardModel
    @Bindable var inboxModel: InboxHandoffModel
    var onOpenConsole: (URL) -> Void
    var onSaved: () -> Void = {}
    /// 关掉整张 sheet。iPad 进导航栏 X；Mac 进右栏底栏的「取消」。
    var onClose: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            SetupGuideStepView(
                model: model,
                onOpenConsole: onOpenConsole,
                showsAdvanceButton: false
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            Group {
                if model.usesInbox {
                    InboxHandoffStepView(
                        model: inboxModel,
                        onSaved: onSaved,
                        onClose: hostedClose
                    )
                } else {
                    SetupCredentialsStepView(
                        model: model,
                        onSaved: onSaved,
                        onClose: hostedClose
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 700, minHeight: 520)
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .meterNavigationContainerBackground(Color.meterGroupedBackground)
        .meterSheetTitle(Text(L("\(model.displayName)连接参考")))
        #if os(iOS)
        .navigationSubtitle(
            Text("\(SetupWizardStep.guide.displayNumber)–\(SetupWizardStep.credentials.displayNumber) / \(SetupWizardStep.totalCount)")
        )
        #endif
        // Mac 关闭已经交给右栏底栏的「取消」。这里再挂一次，会在主按钮下面再画一颗「完成」。
        .meterSheetClose(isActive: hostedClose == nil) { onClose() }
    }

    /// Mac 底栏「取消」由凭据/信箱那一栏上报；iPad 导航栏 X 走整张 sheet 这一颗。
    private var hostedClose: (() -> Void)? {
        #if os(macOS)
        onClose
        #else
        nil
        #endif
    }
}

#Preview("Light") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .credentials,
        outcome: .success(
            title: String(localized: L("本周期至今 $11.05")),
            detail: String(localized: L("周期 8/1 – 8/31 · 日粒度可用"))
        )
    )
    @Previewable @State var inbox = InboxHandoffModel(
        providerID: .cloudflare,
        dashboard: DashboardModel.preview
    )
    NavigationStack {
        SetupWizardPadLayout(
            model: model,
            inboxModel: inbox,
            onOpenConsole: { _ in }
        )
    }
    .environment(\.meterShell, .pad)
    .preferredColorScheme(.light)
}
