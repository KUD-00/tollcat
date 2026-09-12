import SwiftUI
import MeterDesign
import MeterUsage

/// 详情里「连接账单」弹出的连接参考。
///
/// 手机量教程正文 + 导航栏/底栏 inset，按内容收矮、可拉开。横屏 iPad 双栏
/// 走 page sheet，不要再用 detent 或裸 `.fitted`。
struct UsageSetupSheet: View {
    var onFinished: () -> Void

    @Environment(\.usesPadChrome) private var usesPadChrome
    @State private var wizard: SetupWizardModel
    /// 首帧几何还没到。从 0 起 detent 可能不布局；也别从 medium 那么矮起。
    @State private var contentHeight: CGFloat =
        MeterSpacing.catDashboard * 4
        + MeterSpacing.primaryActionMinHeight
    @State private var chromeHeight: CGFloat = MeterSpacing.xxl

    init(model: SetupWizardModel, onFinished: @escaping () -> Void) {
        _wizard = State(initialValue: model)
        self.onFinished = onFinished
    }

    var body: some View {
        NavigationStack {
            SetupWizardView(
                model: wizard,
                onFinished: onFinished,
                reportedContentHeight: $contentHeight
            )
            .meterContainerChromeHeight($chromeHeight)
        }
        .modifier(
            UsageSetupPresentation(
                usesPadChrome: usesPadChrome,
                height: contentHeight + chromeHeight
            )
        )
        .recordsUsageScreen(.servicesSetup)
    }
}

#Preview("Light") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            UsageSetupSheet(
                model: SetupWizardModel.preview(providerID: .cloudflare, step: .guide),
                onFinished: {}
            )
        }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            UsageSetupSheet(
                model: SetupWizardModel.preview(providerID: .openai, step: .guide),
                onFinished: {}
            )
        }
        .preferredColorScheme(.dark)
}

#Preview("XXL") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            UsageSetupSheet(
                model: SetupWizardModel.preview(providerID: .cloudflare, step: .guide),
                onFinished: {}
            )
        }
        .dynamicTypeSize(.accessibility3)
}
