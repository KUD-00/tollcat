import SwiftUI
import MeterDesign
import MeterUsage

struct UsageGuideListView: View {
    @Bindable var dashboard: DashboardModel

    var body: some View {
        MeterGroupedList {
            Section {
                ForEach(UsageGuide.all) { guide in
                    MeterColumnLink(
                        value: guide.id,
                        title: Text(guide.title),
                        destination: { article(for: guide.id) }
                    ) {
                        Text(guide.title)
                            .foregroundStyle(Color.meterLabel)
                    }
                    .accessibilityHint(L("打开这篇使用指南"))
                }
            }
        }
        .navigationTitle(L("使用指南"))
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: UsageGuideID.self) { id in
            article(for: id)
        }
    }

    private func article(for id: UsageGuideID) -> some View {
        let guide = UsageGuide.make(id)
        return ScrollView {
            UsageGuideArticleView(guide: guide, includesTitle: false)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.meterGroupedBackground)
        .navigationTitle(guide.title)
        .toolbarTitleDisplayMode(.inlineLarge)
        .onAppear {
            dashboard.shell.markUsageGuideSeen(id.rawValue)
        }
        .recordsUsageScreen(.settingsUsageGuide)
    }
}

#Preview("Light") {
    @Previewable @State var dashboard = DashboardModel.preview
    NavigationStack {
        UsageGuideListView(dashboard: dashboard)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var dashboard = DashboardModel.preview
    NavigationStack {
        UsageGuideListView(dashboard: dashboard)
    }
    .preferredColorScheme(.dark)
}

#Preview("XXL") {
    @Previewable @State var dashboard = DashboardModel.preview
    NavigationStack {
        UsageGuideListView(dashboard: dashboard)
    }
    .dynamicTypeSize(.accessibility3)
}

#Preview("Pad") {
    @Previewable @State var dashboard = DashboardModel.preview
    NavigationStack {
        UsageGuideListView(dashboard: dashboard)
    }
    .environment(\.meterShell, .pad)
}
