#if DEBUG
import SwiftUI
import MeterDesign

/// 画廊样品不要 `.listRowInsets(EdgeInsets())`。
/// insetGrouped 的 section 按圆角裁切，归零 inset 会让内容贴边，四周被剃。
/// 仪表页归零 inset 是为了和导航标题对齐，画廊没有这条约束。
struct ComponentGalleryView: View {
    var body: some View {
        MeterGroupedList {
            ForEach(GallerySection.allCases) { section in
                Section {
                    ForEach(section.items) { id in
                        MeterColumnLink(
                            value: id,
                            title: Text(id.title),
                            destination: { GalleryRegistry.view(id: id) }
                        ) {
                            Text(id.title)
                        }
                    }
                } header: {
                    Text(section.title)
                }
            }
        }
        .navigationTitle(L("组件画廊"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Light") {
    NavigationStack {
        ComponentGalleryView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        ComponentGalleryView()
    }
    .preferredColorScheme(.dark)
}
#endif
