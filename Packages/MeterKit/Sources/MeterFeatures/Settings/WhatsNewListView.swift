import SwiftUI
import MeterCore
import MeterDesign
import MeterUsage

/// 设置 → 关于 → 更新说明。抽屉弹过的、被跳过的、当初决定不弹的，这里都在。
///
/// 读的是同一份 `WhatsNewCatalog`，只按端筛——所以「安静发布」不等于「藏起来」。
struct WhatsNewListView: View {
    var entries: [WhatsNewEntry] = WhatsNewLaunch.history()

    private var language: CatalogLanguage { CatalogDisplay.language }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    L("还没有正式版"),
                    systemImage: "shippingbox",
                    description: Text(L("发了就会按版本记在这里。"))
                )
            } else {
                MeterGroupedList {
                    Section {
                        ForEach(entries) { entry in
                            MeterColumnLink(
                                value: entry,
                                title: Text(verbatim: entry.version),
                                destination: { detail(for: entry) }
                            ) {
                                VStack(alignment: .leading, spacing: MeterSpacing.xs / 2) {
                                    Text(verbatim: entry.version)
                                        .font(MeterFont.bodyEmphasized)
                                        .foregroundStyle(Color.meterLabel)
                                    Text(entry.title.resolved(language))
                                        .font(MeterFont.subheadline)
                                        .foregroundStyle(Color.meterSecondaryLabel)
                                }
                            }
                            .accessibilityHint(L("打开这一版的更新说明"))
                        }
                    }
                }
            }
        }
        .navigationTitle(L("更新说明"))
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: WhatsNewEntry.self) { entry in
            detail(for: entry)
        }
    }

    private func detail(for entry: WhatsNewEntry) -> some View {
        ScrollView {
            WhatsNewEntryView(entry: entry, includesTitle: false)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.meterGroupedBackground)
        .navigationTitle(Text(entry.title.resolved(language)))
        .toolbarTitleDisplayMode(.inlineLarge)
        .recordsUsageScreen(.settingsWhatsNew)
    }
}

#Preview("Light") {
    NavigationStack {
        WhatsNewListView(entries: [.preview, .previewOlder])
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        WhatsNewListView(entries: [.preview, .previewOlder])
    }
    .preferredColorScheme(.dark)
}

#Preview("空态") {
    NavigationStack {
        WhatsNewListView(entries: [])
    }
}

#Preview("XXL") {
    NavigationStack {
        WhatsNewListView(entries: [.preview, .previewOlder])
    }
    .dynamicTypeSize(.accessibility3)
}

#Preview("Pad") {
    NavigationStack {
        WhatsNewListView(entries: [.preview, .previewOlder])
    }
    .environment(\.meterShell, .pad)
}
