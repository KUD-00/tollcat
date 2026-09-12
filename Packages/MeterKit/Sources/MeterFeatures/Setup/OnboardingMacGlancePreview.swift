import SwiftUI
import MeterCore
import MeterDesign

/// Mac 开场第 3 页的标本位。
///
/// TODO: 单独定制菜单栏 / 桌面小组件那张预览。先留空，不要用 iPhone 中号小组件冒充。
struct OnboardingMacGlancePreview: View {
    var presentation: MoneyPresentation

    var body: some View {
        Color.clear
            .frame(
                maxWidth: MeterSpacing.onboardingWidgetWidth,
                minHeight: MeterSpacing.onboardingWidget
            )
            .accessibilityHidden(true)
    }
}

#Preview("Light") {
    OnboardingMacGlancePreview(presentation: .usd)
        .padding(MeterSpacing.pageHorizontal)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingMacGlancePreview(presentation: .usd)
        .padding(MeterSpacing.pageHorizontal)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.dark)
}
