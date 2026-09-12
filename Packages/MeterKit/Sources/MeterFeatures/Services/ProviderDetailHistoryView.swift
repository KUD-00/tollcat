import SwiftUI
import MeterDesign

/// 详情里「读数明细」从右侧推进。列表是每次刷新落下的 Snapshot，不是就地展开。
struct ProviderDetailHistoryView: View {
    @Bindable var model: ProviderDetailModel

    var body: some View {
        MeterGroupedList {
            if model.history.isEmpty {
                Text(L("还没有读数"))
                    .foregroundStyle(Color.meterSecondaryLabel)
            } else {
                ForEach(model.history) { item in
                    LabeledContent(item.dateCaption) {
                        Text(item.amountCaption)
                            .monospacedDigit()
                            .foregroundStyle(Color.meterSecondaryLabel)
                    }
                    .accessibilityLabel(L("\(item.dateCaption)，\(item.spokenAmount)"))
                }
            }
        }
        .navigationTitle(L("读数明细"))
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview("Light") {
    NavigationStack {
        ProviderDetailHistoryView(model: .preview(.cloudflare))
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        ProviderDetailHistoryView(model: .preview(.openai))
    }
    .preferredColorScheme(.dark)
}

#Preview("XXL") {
    NavigationStack {
        ProviderDetailHistoryView(model: .preview(.cloudflare))
    }
    .dynamicTypeSize(.accessibility3)
}

#Preview("Pad") {
    NavigationStack {
        ProviderDetailHistoryView(model: .preview(.cloudflare))
    }
    .environment(\.meterShell, .pad)
}
