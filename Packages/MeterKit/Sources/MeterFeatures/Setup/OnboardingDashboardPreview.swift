import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

/// 开场第 1 页：真仪表的上半截，不是猫。
struct OnboardingDashboardPreview: View {
    var presentation: MoneyPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.md) {
            MonthToDateModuleView(content: OnboardingDemoContent.monthToDateModule(presentation: presentation))
            if let composition = OnboardingDemoContent.composition(presentation: presentation) {
                CompositionModuleView(content: composition)
            }
        }
        .padding(MeterSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.meterSecondaryGroupedBackground,
            in: RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
        )
        .environment(\.moneyPresentation, presentation)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    OnboardingDashboardPreview(presentation: .usd)
        .padding(MeterSpacing.pageHorizontal)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingDashboardPreview(presentation: .usd)
        .padding(MeterSpacing.pageHorizontal)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.dark)
}
