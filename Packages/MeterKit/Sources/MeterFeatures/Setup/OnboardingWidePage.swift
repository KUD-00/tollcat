import SwiftUI
import MeterCore
import MeterDesign

/// 横屏宽壳的开场页：左边标本，右边说明。不要把手机竖叠拉成通栏。
struct OnboardingWidePage<Stage: View>: View {
    var title: LocalizedStringResource
    var bodyText: LocalizedStringResource
    var spokenProgress: String
    var previewWidth: CGFloat
    var minHeight: CGFloat
    @ViewBuilder var stage: () -> Stage

    var body: some View {
        ScrollView {
            HStack(alignment: .center, spacing: MeterSpacing.xxl) {
                stage()
                    .frame(maxWidth: previewWidth)
                    .frame(maxWidth: .infinity)
                copy
                    .frame(maxWidth: MeterSpacing.readableMeasure, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, MeterSpacing.xl)
            .padding(.vertical, MeterSpacing.lg)
            .frame(maxWidth: .infinity, minHeight: minHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .accessibilityElement(children: .contain)
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.sm) {
            Text(title)
                .font(MeterFont.title2)
                .foregroundStyle(Color.meterLabel)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityValue(spokenProgress)
            Text(bodyText)
                .font(MeterFont.body)
                .foregroundStyle(Color.meterSecondaryLabel)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("Light") {
    OnboardingWidePage(
        title: L("这个月花了多少"),
        bodyText: L("各家云和 AI 的账单收成一个数字。打开就能看见这个月已经花了多少。"),
        spokenProgress: "1 / 4",
        previewWidth: MeterSpacing.onboardingPreviewWidth,
        minHeight: 520
    ) {
        OnboardingDashboardPreview(presentation: .usd)
    }
    .frame(width: 1100, height: 640)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingWidePage(
        title: L("不必打开也能看见"),
        bodyText: L("通知里不放金额，也没有金额告警。把小组件放到主屏或锁屏，划过去就是这个月的数字。"),
        spokenProgress: "3 / 4",
        previewWidth: MeterSpacing.onboardingWidgetWidth,
        minHeight: 520
    ) {
        OnboardingWidgetPreview(presentation: .usd)
    }
    .frame(width: 1100, height: 640)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.dark)
}
