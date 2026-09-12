import SwiftUI
import MeterCore
import MeterDesign

public struct UpcomingChargesModuleView: View {
    public let content: UpcomingChargesModuleContent

    public init(content: UpcomingChargesModuleContent) {
        self.content = content
    }
    @Environment(\.moneyPresentation) private var moneyPresentation
    @Environment(\.moduleHeight) private var height

    public var body: some View {
        if height.prefersCardMetrics, let next = content.items.min(by: { $0.chargeDate < $1.chargeDate }) {
            DashboardCardHeadline(
                value: next.amount.formatted(using: moneyPresentation),
                caption: "\(next.displayName)，\(next.dateCaption)",
                animationValue: NSDecimalNumber(decimal: moneyPresentation.amount(from: next.amount)).doubleValue
            )
        }
        ForEach(content.items) { item in
            if let accountID = item.accountID {
                ModuleLink(route: .account(accountID)) {
                    row(item)
                }
                .accessibilityHint(L("查看 \(item.displayName) 详情"))
            } else {
                row(item)
            }
        }
        .animation(DashboardMotion.number, value: content.animationSignature)
    }

    private func row(_ item: UpcomingChargeItem) -> some View {
        DashboardInsightRow(
            colorKey: item.colorKey,
            title: item.displayName,
            subtitle: item.dateCaption,
            trailingText: item.amount.formatted(using: moneyPresentation),
            trailingColor: Color.meterSecondaryLabel,
            spokenLabel: item.spokenCaption,
            animationValue: NSDecimalNumber(decimal: moneyPresentation.amount(from: item.amount)).doubleValue
        )
    }
}

#Preview("Light") {
    NavigationStack {
        List {
            Section {
                UpcomingChargesModuleView(content: UpcomingPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        List {
            Section {
                UpcomingChargesModuleView(content: UpcomingPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.dark)
}

private enum UpcomingPreviewData {
    static let sample = UpcomingChargesModuleContent(
        items: [
            UpcomingChargeItem(
                id: "chatgpt",
                accountID: AccountID.fixture(for: .openai),
                providerID: .openai,
                displayName: "ChatGPT Plus",
                colorKey: "openai",
                amount: Money(usd: 20),
                chargeDate: Date(timeIntervalSince1970: 0),
                dateCaption: String(localized: L("8 月 20 日"))
            )
        ]
    )
}
