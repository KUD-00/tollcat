import SwiftUI
import MeterCore
import MeterDesign

public struct BalanceAlertModuleView: View {
    public let content: BalanceAlertModuleContent

    public init(content: BalanceAlertModuleContent) {
        self.content = content
    }
    @Environment(\.moduleHeight) private var height

    public var body: some View {
        if height.prefersCardMetrics, let tightest = content.items.min(by: { $0.daysRemaining < $1.daysRemaining }) {
            DashboardCardHeadline(
                value: tightest.trailingText,
                caption: String(localized: L("\(tightest.displayName) 最紧")),
                tone: tightest.daysRemaining < 7 ? MeterColor.crit : Color.meterLabel,
                animationValue: Double(tightest.daysRemaining)
            )
        }
        ForEach(content.items) { item in
            ModuleLink(route: .account(item.accountID)) {
                DashboardInsightRow(
                    colorKey: item.colorKey,
                    title: item.displayName,
                    subtitle: item.balanceCaption,
                    trailingText: item.trailingText,
                    trailingColor: Color.meterSecondaryLabel,
                    spokenLabel: item.spokenCaption,
                    animationValue: Double(item.daysRemaining)
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
                BalanceAlertModuleView(content: BalanceAlertPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        List {
            Section {
                BalanceAlertModuleView(content: BalanceAlertPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.dark)
}

private enum BalanceAlertPreviewData {
    static let sample = BalanceAlertModuleContent(
        items: [
            BalanceAlertItem(
                accountID: AccountID.fixture(for: .openai),
                providerID: .openai,
                displayName: "OpenAI",
                colorKey: "openai",
                balanceUSD: Money(usd: 42),
                daysRemaining: 18
            )
        ]
    )
}
