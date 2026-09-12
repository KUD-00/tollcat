#if DEBUG
import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

struct GalleryRowStatesView: View {
    var body: some View {
        MeterGroupedList {
            Section {
                DashboardInsightRow(
                    colorKey: "aws",
                    title: "AWS",
                    subtitle: String(localized: L("对比 7 月同期 $13.20")),
                    trailingText: "+62%",
                    trailingColor: MeterColor.warn,
                    spokenLabel: String(localized: L("AWS 较上月同期上升百分之 62")),
                    animationValue: 62
                )
            } header: {
                Text(L("百分比"))
            }
            Section {
                DashboardInsightRow(
                    colorKey: "openai",
                    title: "OpenAI",
                    subtitle: String(localized: L("余额 $42.00")),
                    trailingText: String(localized: L("18 天")),
                    trailingColor: Color.meterSecondaryLabel,
                    spokenLabel: String(localized: L("OpenAI 余额 42 美元，还能用 18 天")),
                    animationValue: 18
                )
            } header: {
                Text(L("天数"))
            }
            Section {
                DashboardInsightRow(
                    colorKey: "openai",
                    title: "ChatGPT Plus",
                    subtitle: String(localized: L("8 月 20 日")),
                    trailingText: "$20.00",
                    trailingColor: Color.meterSecondaryLabel,
                    spokenLabel: String(localized: L("ChatGPT Plus 20 美元，8 月 20 日扣款")),
                    animationValue: 20
                )
            } header: {
                Text(L("金额"))
            }
            Section {
                DashboardInsightRow(
                    colorKey: "vercel",
                    title: "Vercel",
                    subtitle: String(localized: L("免费额度")),
                    trailingText: "84%",
                    trailingColor: Color.meterSecondaryLabel,
                    spokenLabel: String(localized: L("Vercel 免费额度用了百分之 84")),
                    animationValue: 84
                )
            } header: {
                Text(L("额度比例"))
            }
        }
        .navigationTitle(L("列表行"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryRowStatesView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryRowStatesView()
    }
    .preferredColorScheme(.dark)
}
#endif
