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
        title: OnboardingPage.number.title,
        bodyText: OnboardingPage.number.body,
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
        title: OnboardingPage.source.title,
        bodyText: OnboardingPage.source.body,
        spokenProgress: "2 / 4",
        previewWidth: MeterSpacing.onboardingPreviewWidth,
        minHeight: 520
    ) {
        OnboardingSourcePreview(shell: .mac)
    }
    .frame(width: 1100, height: 640)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.dark)
}
