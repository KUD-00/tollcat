#if DEBUG
import SwiftUI
import MeterDesign

struct GalleryErrorStatesView: View {
    var body: some View {
        MeterGroupedList {
            Section("401") {
                SetupFailureBanner(outcome: GalleryFixtures.unauthorized)
            }
            Section("403") {
                SetupFailureBanner(outcome: GalleryFixtures.forbidden)
            }
            Section {
                SetupFailureBanner(outcome: .network)
            } header: {
                Text(L("断网"))
            }
            Section {
                SetupFailureBanner(outcome: .emptyReading)
            } header: {
                Text(L("空读数"))
            }
            Section {
                ProviderRow(
                    name: "Cloudflare",
                    colorKey: "cloudflare",
                    value: "$11.05",
                    subtitle: "12 分钟前",
                    staleLabel: String(localized: L("数据陈旧")),
                    spokenValue: "11 美元 5 美分",
                    amountValue: 11.05
                )
                Text(L("刷新失败，仍显示上次的数字"))
                    .font(MeterFont.footnote)
                    .foregroundStyle(MeterColor.warn)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text(L("刷新失败 · 数据陈旧"))
            }
            Section {
                PersistenceNoticeList(
                    status: PersistenceStatus(persistsToDisk: false, containsDemoData: false)
                )
            } header: {
                Text(L("没能保存到本机"))
            }
        }
        .navigationTitle(L("错误态"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryErrorStatesView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryErrorStatesView()
    }
    .preferredColorScheme(.dark)
}
#endif
