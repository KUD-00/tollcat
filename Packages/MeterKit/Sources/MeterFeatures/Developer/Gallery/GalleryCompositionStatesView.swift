#if DEBUG
import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

struct GalleryCompositionStatesView: View {
    var body: some View {
        MeterGroupedList {
            Section {
                bar(GalleryFixtures.composition([(.aws, 1, 100)]))
            } header: {
                Text(L("1 段"))
            }
            Section {
                bar(GalleryFixtures.composition([
                    (.aws, 0.7, 70),
                    (.cloudflare, 0.3, 30),
                ]))
            } header: {
                Text(L("2 段"))
            }
            Section {
                bar(GalleryFixtures.composition([
                    (.aws, 0.45, 45),
                    (.cloudflare, 0.23, 23),
                    (.openai, 0.16, 16),
                    (.github, 0.09, 9),
                    (.neon, 0.07, 7),
                ]))
            } header: {
                Text(L("5 段"))
            }
            Section {
                bar(GalleryFixtures.eightProviderComposition)
            } header: {
                Text(L("超过 5 家"))
            } footer: {
                Text(L("第 5 名之后合并成「其他」。点卡片从右侧推进构成页。"))
            }
            Section {
                bar(GalleryFixtures.composition([(.openai, 1, 100)]))
            } header: {
                Text(L("一家占 100%"))
            }
        }
        .navigationTitle(L("构成"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func bar(_ content: CompositionModuleContent) -> some View {
        CompositionModuleView(content: content)
            .listRowBackground(Color.clear)
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryCompositionStatesView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryCompositionStatesView()
    }
    .preferredColorScheme(.dark)
}
#endif
