#if DEBUG
import SwiftUI
import MeterDesign

struct GalleryUsageGuidesView: View {
    @State private var drawerID: UsageGuideID?

    var body: some View {
        MeterGroupedList {
            Section {
                ForEach(UsageGuide.all) { guide in
                    MeterColumnLink(
                        value: guide.id,
                        title: Text(guide.title),
                        destination: { galleryArticle(for: guide.id) }
                    ) {
                        UsageGuideArticlePreviewRow(guide: guide)
                    }
                }
            }
            Section {
                Button(L("启动抽屉")) {
                    drawerID = .heroExcludesSubscriptions
                }
                .accessibilityHint(L("用第一篇演示冷启动那张抽屉"))
            }
        }
        .navigationTitle(L("使用指南"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: UsageGuideID.self) { id in
            galleryArticle(for: id)
        }
        .sheet(item: $drawerID) { id in
            UsageGuideDrawerView(guide: .make(id), onAcknowledge: { drawerID = nil })
        }
    }

    private func galleryArticle(for id: UsageGuideID) -> some View {
        ScrollView {
            UsageGuideArticleView(guide: .make(id), includesTitle: false)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.meterGroupedBackground)
        .navigationTitle(UsageGuide.make(id).title)
        .toolbarTitleDisplayMode(.inlineLarge)
    }
}

private struct UsageGuideArticlePreviewRow: View {
    var guide: UsageGuide

    var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            Text(guide.title)
            Text(guide.body)
                .font(MeterFont.footnote)
                .foregroundStyle(Color.meterSecondaryLabel)
                .lineLimit(2)
        }
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryUsageGuidesView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryUsageGuidesView()
    }
    .preferredColorScheme(.dark)
}
#endif
