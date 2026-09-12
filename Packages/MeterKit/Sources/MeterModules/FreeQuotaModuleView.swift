import SwiftUI
import MeterCore
import MeterDesign

public struct FreeQuotaModuleView: View {
    public let content: FreeQuotaModuleContent

    public init(content: FreeQuotaModuleContent) {
        self.content = content
    }
    @Environment(\.moduleHeight) private var height

    public var body: some View {
        if height.prefersCardMetrics, let fullest = content.items.max(by: { $0.usedRatio < $1.usedRatio }) {
            DashboardCardHeadline(
                value: fullest.trailingText,
                caption: String(localized: L("\(fullest.displayName) 用得最多")),
                tone: fullest.usedRatio > 0.8 ? MeterColor.warn : Color.meterLabel,
                animationValue: fullest.usedRatio * 100
            )
        }
        ForEach(content.items) { item in
            ModuleLink(route: .account(item.accountID)) {
                DashboardInsightRow(
                    colorKey: item.colorKey,
                    title: item.displayName,
                    subtitle: item.kindCaption,
                    trailingText: item.trailingText,
                    trailingColor: Color.meterSecondaryLabel,
                    spokenLabel: item.spokenCaption,
                    animationValue: item.usedRatio * 100
                )
            }
            .accessibilityHint(L("查看 \(item.displayName) 详情"))
        }
        .animation(DashboardMotion.number, value: content.animationSignature)
    }
}

#Preview("Light") {
    NavigationStack {
        List {
            Section {
                FreeQuotaModuleView(content: FreeQuotaPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        List {
            Section {
                FreeQuotaModuleView(content: FreeQuotaPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.dark)
}

private enum FreeQuotaPreviewData {
    static let sample = FreeQuotaModuleContent(
        items: [
            FreeQuotaItem(
                accountID: AccountID.fixture(for: .vercel),
                providerID: .vercel,
                displayName: "Vercel",
                colorKey: "vercel",
                usedRatio: 0.84
            )
        ]
    )
}
