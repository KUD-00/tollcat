#if DEBUG
import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

struct GalleryOverflowStatesView: View {
    var body: some View {
        MeterGroupedList {
            Section {
                ProviderRow(
                    name: "Cloudflare Workers Paid Plan Plus Extra Long Display Name",
                    colorKey: "cloudflare",
                    value: "$1,234,567.89",
                    subtitle: String(localized: L("上次刷新是很久很久以前的一个下午，长到这一行也要塞进去")),
                    spokenValue: String(localized: L("123 万 4567 美元 89 美分")),
                    amountValue: 1_234_567.89
                )
            } header: {
                Text(L("超长 Provider"))
            }
            Section {
                DashboardInsightRow(
                    colorKey: "openai",
                    title: "ChatGPT Team Annual Seats Super Long Subscription Name",
                    subtitle: String(localized: L("每年 8 月 20 日扣款，名称长到必须被压缩")),
                    trailingText: "$240.00",
                    trailingColor: Color.meterSecondaryLabel,
                    spokenLabel: String(localized: L("超长订阅 240 美元")),
                    animationValue: 240
                )
            } header: {
                Text(L("超长订阅"))
            }
        }
        .navigationTitle(L("超长名称"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryOverflowStatesView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryOverflowStatesView()
    }
    .preferredColorScheme(.dark)
}
#endif
