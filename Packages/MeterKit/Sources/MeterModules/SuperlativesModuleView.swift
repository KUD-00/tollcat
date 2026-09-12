import SwiftUI
import MeterCore
import MeterDesign

/// 「之最」：三行，各指一家，点进详情。节标题在外面，跟着期间走。
public struct SuperlativesModuleView: View {
    public let content: SuperlativesModuleContent

    public init(content: SuperlativesModuleContent) {
        self.content = content
    }

    public var body: some View {
        ForEach(content.items) { item in
            if let accountID = item.accountID {
                ModuleLink(route: .account(accountID)) { row(item) }
                    .accessibilityHint(L("查看 \(item.displayName) 详情"))
            } else if let providerID = item.providerID {
                ModuleLink(route: .provider(providerID)) { row(item) }
                    .accessibilityHint(L("查看 \(item.displayName) 详情"))
            } else {
                row(item)
            }
        }
        .animation(DashboardMotion.number, value: content.animationSignature)
    }

    private func row(_ item: SuperlativeItem) -> some View {
        DashboardInsightRow(
            colorKey: item.colorKey,
            title: item.displayName,
            subtitle: String(localized: item.title),
            trailingText: item.value,
            trailingColor: item.kind == .biggestRise ? MeterColor.warn : Color.meterSecondaryLabel,
            spokenLabel: item.spokenLabel,
            animationValue: 0
        )
    }
}

#Preview("Light") {
    NavigationStack {
        List {
            Section {
                SuperlativesModuleView(content: SuperlativesPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        List {
            Section {
                SuperlativesModuleView(content: SuperlativesPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.dark)
}

public enum SuperlativesPreviewData {
    public static let sample = SuperlativesModuleContent(items: [
        SuperlativeItem(kind: .biggestRise, displayName: "AWS", value: "+62%", colorKey: "aws", accountID: AccountID.fixture(for: .aws), providerID: .aws),
        SuperlativeItem(kind: .biggestShare, displayName: "Cloudflare", value: "45%", colorKey: "cloudflare", accountID: AccountID.fixture(for: .cloudflare), providerID: .cloudflare),
        SuperlativeItem(kind: .stalest, displayName: "Neon", value: "3 天前", colorKey: "neon", accountID: AccountID.fixture(for: .neon), providerID: .neon),
    ])
}
