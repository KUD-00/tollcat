#if DEBUG
import SwiftUI
import MeterCore
import MeterDesign
import MeterPersistence
import MeterProviders

/// 八家向导的只读目录。不 new DashboardModel，避免画廊碰到真实 store。
struct GallerySetupGuidesView: View {
    @State private var catalog: Catalog?

    var body: some View {
        MeterGroupedList {
            ForEach(ProviderCatalog.all, id: \.id) { descriptor in
                MeterColumnLink(
                    value: descriptor.id,
                    title: Text(descriptor.displayName),
                    destination: {
                        GallerySetupGuideDetailView(
                            descriptor: ProviderCatalog.descriptor(id: descriptor.id),
                            guide: catalog?.guides[descriptor.id]
                        )
                    }
                ) {
                    Label {
                        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                            Text(descriptor.displayName)
                            if let reason = descriptor.declineReason, !reason.isEmpty {
                                Text(reason)
                                    .font(MeterFont.caption)
                                    .foregroundStyle(Color.meterSecondaryLabel)
                            } else if let catalog, catalog.guides[descriptor.id] == nil {
                                Text(L("接入说明还没写好"))
                                    .font(MeterFont.caption)
                                    .foregroundStyle(Color.meterSecondaryLabel)
                            }
                        }
                    } icon: {
                        ProviderGlyph(colorKey: descriptor.colorKey)
                    }
                }
            }
        }
        .navigationTitle(L("接入向导"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: ProviderID.self) { id in
            GallerySetupGuideDetailView(
                descriptor: ProviderCatalog.descriptor(id: id),
                guide: catalog?.guides[id]
            )
        }
        .task {
            catalog = (try? await BundledCatalogSource().load())?
                .localized(for: CatalogDisplay.language)
        }
    }
}

#Preview("Light") {
    NavigationStack {
        GallerySetupGuidesView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GallerySetupGuidesView()
    }
    .preferredColorScheme(.dark)
}
#endif
