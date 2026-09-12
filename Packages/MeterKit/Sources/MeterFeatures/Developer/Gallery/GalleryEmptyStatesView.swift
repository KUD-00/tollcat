#if DEBUG
import SwiftUI
import MeterDesign

struct GalleryEmptyStatesView: View {
    var body: some View {
        MeterGroupedList {
            Section {
                DashboardEmptyView(onOpenServices: {})
                    .listRowBackground(Color.clear)
            } header: {
                Text(L("仪表页"))
            }

            Section {
                ServicesEmptyView(onAdd: {})
                    .listRowBackground(Color.clear)
            } header: {
                Text(L("服务页"))
            }

            Section {
                InboxEmptyView()
                    .listRowBackground(Color.clear)
            } header: {
                Text(L("读数信箱"))
            }

            Section {
                ContentUnavailableView.search(text: "zzzz")
                    .listRowBackground(Color.clear)
            } header: {
                Text(L("添加服务 · 搜索无结果"))
            }
        }
        .navigationTitle(L("空态"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryEmptyStatesView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryEmptyStatesView()
    }
    .preferredColorScheme(.dark)
}
#endif
