import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

/// 「固定订阅」的详情页：口径、下一笔、全部订阅，每笔进各家详情。
struct SubscriptionsDetailView: View {
    let content: SubscriptionsModuleContent

    var body: some View {
        MeterGroupedList {
            Section {
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    Text(content.monthlyTotalText)
                        .meterAmountStyle()
                        .foregroundStyle(Color.meterLabel)
                        .contentTransition(.numericText(value: content.monthlyTotalValue))
                    Text(content.countCaption)
                        .font(MeterFont.subheadline)
                        .foregroundStyle(Color.meterSecondaryLabel)
                    if let next = content.nextChargeCaption {
                        Text(next)
                            .font(MeterFont.subheadline)
                            .foregroundStyle(Color.meterSecondaryLabel)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
            Section {
                ForEach(content.items) { item in
                    if let accountID = item.accountID {
                        DashboardRouteLink(route: .account(accountID)) { row(item) }
                            .accessibilityHint(L("查看 \(item.name) 详情"))
                    } else if let providerID = item.providerID {
                        DashboardRouteLink(route: .provider(providerID)) { row(item) }
                            .accessibilityHint(L("查看 \(item.name) 详情"))
                    } else {
                        row(item)
                    }
                }
            } header: {
                Text(L("全部订阅"))
            }
        }
        .navigationTitle(L("固定订阅"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ item: SubscriptionRowItem) -> some View {
        DashboardInsightRow(
            colorKey: item.colorKey,
            title: item.name,
            subtitle: item.periodCaption,
            trailingText: item.amountText,
            trailingColor: Color.meterSecondaryLabel,
            spokenLabel: item.spokenLabel,
            animationValue: item.amountValue
        )
    }
}

#Preview("Dark") {
    NavigationStack {
        SubscriptionsDetailView(content: SubscriptionsPreviewData.sample)
    }
    .preferredColorScheme(.dark)
}
