import SwiftUI
import MeterCore
import MeterDesign

/// 不再花钱、但过去花过的那些。
///
/// 单开一页而不是在服务列表底下挂两节：主列表回答的是「我现在每个月付多少」，
/// 已经停掉的东西留在那儿只是噪音。它们又必须留着——过去几个月的账里有它们，
/// 删掉才是真的把那段历史抹了——所以给一个入口，想查再进来。
struct PastServicesView: View {
    let rows: [ServiceRowItem]
    let subscriptions: [ManualSubscriptionItem]
    let onOpenProvider: (ProviderID) -> Void
    let onEditSubscription: (ManualSubscriptionItem) -> Void

    var body: some View {
        MeterGroupedList {
            if !rows.isEmpty {
                Section {
                    ForEach(rows) { row in
                        Button {
                            onOpenProvider(row.id)
                        } label: {
                            ProviderRow(
                                name: row.displayName,
                                colorKey: row.colorKey,
                                value: row.value,
                                subtitle: row.subtitle,
                                isConnected: row.isConnected,
                                usesSecondaryValue: row.usesSecondaryValue,
                                staleLabel: nil,
                                valueCaption: row.valueCaption,
                                spokenValue: row.spokenValue,
                                amountValue: row.amountValue,
                                accessibilityName: row.spokenName
                            )
                            .meterListRowHitTarget()
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(L("查看这家的账单和接入"))
                    }
                } header: {
                    Text(L("历史服务"))
                }
            }
            if !subscriptions.isEmpty {
                Section {
                    ForEach(subscriptions) { item in
                        Button {
                            onEditSubscription(item)
                        } label: {
                            HStack(spacing: MeterSpacing.sm) {
                                ManualSubscriptionRow(item: item)
                                Image(systemName: "chevron.right")
                                    .font(MeterFont.footnote.weight(.semibold))
                                    .foregroundStyle(Color.meterTertiaryLabel)
                                    .accessibilityHidden(true)
                            }
                            .meterListRowHitTarget()
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(L("编辑这笔订阅"))
                    }
                } header: {
                    Text(L("历史订阅"))
                }
            }
        }
        .navigationTitle(L("历史服务"))
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview("Light") {
    NavigationStack {
        PastServicesView(
            rows: [PastServicesPreview.row],
            subscriptions: [PastServicesPreview.subscription],
            onOpenProvider: { _ in },
            onEditSubscription: { _ in }
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        PastServicesView(
            rows: [PastServicesPreview.row],
            subscriptions: [PastServicesPreview.subscription],
            onOpenProvider: { _ in },
            onEditSubscription: { _ in }
        )
    }
    .preferredColorScheme(.dark)
}

@MainActor
private enum PastServicesPreview {
    static let row = ServiceRowItem(
        id: .openai,
        kind: .prepaid,
        category: .aiInference,
        nickname: nil,
        displayName: "OpenAI",
        spokenName: "OpenAI",
        colorKey: "openai",
        value: "—",
        spokenValue: "已结束",
        subtitle: "已结束 · 2026年6月",
        usesSecondaryValue: true,
        isConnected: true,
        isStale: false,
        valueCaption: nil,
        amountValue: 0,
        supersededByManual: false,
        isEnded: true
    )

    static var subscription: ManualSubscriptionItem {
        var item = DashboardModel.preview.subscriptionItems().first!
        item.endDate = Date(timeIntervalSince1970: 1_780_000_000)
        item.hasEnded = true
        return item
    }
}
