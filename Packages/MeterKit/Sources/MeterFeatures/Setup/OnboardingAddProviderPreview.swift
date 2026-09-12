import SwiftUI
import MeterDesign
import MeterProviders

/// 开场第 4 页：真的添加列表行，不是一只得意的猫。
struct OnboardingAddProviderPreview: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, descriptor in
                AddProviderRow(descriptor: descriptor)
                    .padding(.vertical, MeterSpacing.sm)
                if index < rows.count - 1 {
                    Divider()
                        .padding(.leading, MeterSpacing.providerGlyph + MeterSpacing.sm)
                }
            }
        }
        .padding(.horizontal, MeterSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.meterSecondaryGroupedBackground,
            in: RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
        )
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    private var rows: [ProviderDescriptor] {
        OnboardingDemoContent.addPreviewIDs.compactMap { ProviderCatalog.descriptor(id: $0) }
    }
}

#Preview("Light") {
    OnboardingAddProviderPreview()
        .padding(MeterSpacing.pageHorizontal)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingAddProviderPreview()
        .padding(MeterSpacing.pageHorizontal)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.dark)
}