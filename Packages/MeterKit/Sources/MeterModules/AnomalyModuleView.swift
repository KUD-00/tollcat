import SwiftUI
import MeterCore
import MeterDesign

public struct AnomalyModuleView: View {
    public let content: AnomalyModuleContent

    public init(content: AnomalyModuleContent) {
        self.content = content
    }
    @Environment(\.moduleHeight) private var height

    public var body: some View {
        if height.prefersCardMetrics, let top = content.items.max(by: { $0.changeRatio < $1.changeRatio }) {
            DashboardCardHeadline(
                value: top.signedPercent,
                caption: String(localized: L("\(top.displayName) 涨得最多")),
                tone: MeterColor.warn,
                animationValue: top.changeRatio * 100
            )
        }
        ForEach(content.items) { item in
            ModuleLink(route: .account(item.accountID)) {
                DashboardInsightRow(
                    colorKey: item.colorKey,
                    title: item.displayName,
                    subtitle: item.caption,
                    trailingText: item.signedPercent,
                    trailingColor: MeterColor.warn,
                    spokenLabel: item.spokenCaption,
                    animationValue: item.changeRatio * 100
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
                AnomalyModuleView(content: AnomalyPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        List {
            Section {
                AnomalyModuleView(content: AnomalyPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.dark)
}

private enum AnomalyPreviewData {
    static let sample = AnomalyModuleContent(
        items: [
            AnomalyItem(
                accountID: AccountID.fixture(for: .aws),
                providerID: .aws,
                displayName: "AWS",
                colorKey: "aws",
                changeRatio: 0.6212,
                comparisonUSD: Money(roundedUSD: 13.20),
                comparisonMonth: 7
            )
        ]
    )
}
