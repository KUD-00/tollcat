#if DEBUG
import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

struct GalleryAttentionStatesView: View {
    var body: some View {
        MeterGroupedList {
            Section {
                Text(L("0 行时整个「需要注意」section 不出现。"))
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text(L("0 行"))
            }

            Section {
                AnomalyModuleView(content: GalleryFixtures.anomaly([(.aws, 0.62)]))
            } header: {
                Text(L("1 行"))
            }

            Section {
                AnomalyModuleView(content: GalleryFixtures.anomaly([
                    (.aws, 0.62),
                    (.openai, 0.41),
                    (.cloudflare, 0.33),
                    (.neon, 0.28),
                ]))
            } header: {
                Text(L("4 行"))
            }
        }
        .navigationTitle(L("需要注意"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryAttentionStatesView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryAttentionStatesView()
    }
    .preferredColorScheme(.dark)
}
#endif
