import SwiftUI
import MeterDesign
import MeterProviders

struct AddProviderRow: View {
    let descriptor: ProviderDescriptor

    var body: some View {
        HStack(spacing: MeterSpacing.sm) {
            ProviderGlyph(
                colorKey: descriptor.colorKey,
                accessibilityName: descriptor.displayName
            )
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(descriptor.displayName)
                    .font(MeterFont.body)
                    .foregroundStyle(Color.meterLabel)
                Text(caption)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: MeterSpacing.sm)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(descriptor.displayName)，\(caption)")
    }

    private var caption: String {
        ProviderListingCopy.caption(for: descriptor)
    }
}

#Preview("Light") {
    List {
        AddProviderRow(descriptor: ProviderCatalog.cloudflare)
        AddProviderRow(descriptor: ProviderCatalog.aws)
        AddProviderRow(descriptor: ProviderCatalog.openai)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        AddProviderRow(descriptor: ProviderCatalog.github)
        AddProviderRow(descriptor: ProviderCatalog.fly)
    }
    .preferredColorScheme(.dark)
}
