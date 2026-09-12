#if DEBUG
import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

struct GalleryComparisonStatesView: View {
    var body: some View {
        MeterGroupedList {
            Section {
                tile(GalleryFixtures.comparisonComplete)
            } header: {
                Text(L("全都能比"))
            }

            Section {
                tile(GalleryFixtures.comparisonPartial)
                MeterColumnPushLink(title: Text(L("较上月同期"))) {
                    ComparisonDetailView(content: GalleryFixtures.comparisonPartial)
                } label: {
                    Text(L("打开详情"))
                }
            } header: {
                Text(L("一家缺同期"))
            } footer: {
                Text(L("还不能对比的本月金额也算进柱和涨跌幅。点进详情看是哪几家。"))
            }

            Section {
                tile(GalleryFixtures.comparisonUnknown)
                MeterColumnPushLink(title: Text(L("较上月同期"))) {
                    ComparisonDetailView(content: GalleryFixtures.comparisonUnknown)
                } label: {
                    Text(L("打开详情"))
                }
            } header: {
                Text(L("都不能比"))
            }
        }
        .navigationTitle(L("较上月同期"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tile(_ content: ComparisonModuleContent) -> some View {
        ComparisonTileView(content: content)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryComparisonStatesView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryComparisonStatesView()
    }
    .preferredColorScheme(.dark)
}
#endif
