import MeterCore
import SwiftUI
import MeterDesign
import MeterPersistence
import MeterProviders

/// 按量账单的计费模式、当前这一档支持说明、连接凭据。
struct SetupUsageFactsSection: View {
    var descriptor: ProviderDescriptor
    var fields: [SetupField]

    var body: some View {
        Section {
            LabeledContent {
                Text(verbatim: SetupProviderFacts.kindTitle(for: descriptor))
            } label: {
                Text(L("计费模式"))
            }
            supportRow
            credentialBlock
        }
    }

    private var supportRow: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            LabeledContent {
                HStack(spacing: MeterSpacing.xs) {
                    SupportSignalBars(
                        filled: SetupProviderFacts.supportBars(for: descriptor),
                        tint: supportTint
                    )
                    Text(verbatim: SetupProviderFacts.supportTitle(for: descriptor))
                }
            } label: {
                Text(L("支持情况"))
            }
            let caption = SetupProviderFacts.supportCaption(for: descriptor)
            if !caption.isEmpty {
                Text(verbatim: caption)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var credentialBlock: some View {
        if !fields.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.sm) {
                Text(L("连接凭据"))
                Spacer(minLength: MeterSpacing.sm)
                VStack(alignment: .trailing, spacing: MeterSpacing.xxs) {
                    ForEach(fields, id: \.key) { field in
                        Text(verbatim: field.label)
                            .foregroundStyle(Color.meterSecondaryLabel)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var supportTint: Color {
        switch SetupProviderFacts.supportLevel(for: descriptor) {
        case .full: MeterColor.good
        case .theoretical: MeterColor.warn
        case .inbox: Color.accentColor
        case .unavailable: Color.meterTertiaryLabel
        }
    }
}

#Preview("Light") {
    Form {
        SetupUsageFactsSection(
            descriptor: ProviderCatalog.cloudflare,
            fields: [
                SetupField(key: "apiToken", label: "API Token", isSecret: true),
                SetupField(key: "accountID", label: "Account ID", isSecret: false),
            ]
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    Form {
        SetupUsageFactsSection(
            descriptor: ProviderCatalog.aws,
            fields: [
                SetupField(key: "accessKeyID", label: "Access Key ID", isSecret: false),
                SetupField(key: "secretAccessKey", label: "Secret Access Key", isSecret: true),
            ]
        )
    }
    .preferredColorScheme(.dark)
}
