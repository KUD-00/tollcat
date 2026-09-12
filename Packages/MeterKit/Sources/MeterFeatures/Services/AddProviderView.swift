import SwiftUI
import MeterCore
import MeterDesign
import MeterModules
import MeterProviders

struct AddProviderView: View {
    @Bindable var model: ServicesModel
    var browse: AddProviderBrowse = .featured
    var onAdd: (ProviderID) -> Void
    @State private var query = FeatureLaunchArguments.addSearch ?? ""
    @State private var pendingProviderID: ProviderID?
    @State private var confirmedProviderID: ProviderID?

    var body: some View {
        MeterGroupedList {
            if AddProviderSearch.showsEmptySearch(query: query, excluding: memberIDs, browse: browse) {
                ContentUnavailableView.search(text: query)
            } else {
                ForEach(sections) { section in
                    if let category = section.category {
                        Section {
                            ForEach(section.descriptors, id: \.id) { descriptor in
                                providerButton(descriptor)
                            }
                        } header: {
                            Text(category.title)
                        }
                    } else {
                        // 不要包一层无 header 的 Section：空 Section 会再留一截默认 header 高度。
                        ForEach(section.descriptors, id: \.id) { descriptor in
                            providerButton(descriptor)
                        }
                    }
                }
                if browse == .featured && showsMoreRow {
                    Section {
                        MeterColumnLink(value: ServicesRoute.addMore, title: Text(L("更多服务"))) {
                            AddProviderView(model: model, browse: .more, onAdd: onAdd)
                        } label: {
                            Label(L("更多服务"), systemImage: "ellipsis.circle")
                        }
                    }
                }
                if showsManualRow {
                    Section {
                        MeterColumnLink(value: ServicesRoute.subscription, title: Text(L("手动订阅"))) {
                            SubscriptionEditorForm(
                                model: SubscriptionEditorModel(dashboard: model.dashboard),
                                showsClose: false
                            )
                        } label: {
                            Label(L("手动订阅"), systemImage: "calendar")
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier(UITestID.addProviderList)
        .environment(\.defaultMinListHeaderHeight, 0)
        // 常显搜索栏已经留了呼吸空间。insetGrouped 默认还会再垫约 35pt 顶距，
        // 两截叠在一起大约 60pt；改成 xs，搜索到列表大约一半。
        .contentMargins(.top, MeterSpacing.xs, for: .scrollContent)
        // 默认 `.automatic` 在 iOS 26 会把搜索栏收到屏幕底部，还要上滑才出现。
        // 添加服务就是来找的，进页就该钉在导航栏下面；Mac 画在列顶。
        .meterColumnSearchable(text: $query, prompt: Text(L("搜索服务")))
        .navigationTitle(browse == .more ? L("更多服务") : L("添加服务"))
        .navigationBarTitleDisplayMode(.inline)
        // 关抽屉和换导航栈必须错开：同一拍会把 presenting 的添加页抽掉，
        // 系统拆掉 sheet、详情直接切进来，没有下滑也没有从右推进。
        .sheet(item: $pendingProviderID, onDismiss: addConfirmedProvider) { id in
            if let descriptor = ProviderCatalog.descriptor(id: id) {
                AddProviderConfirmSheet(
                    descriptor: descriptor,
                    summary: model.catalog.guides[id]?.summary ?? "",
                    onAdd: { confirm(id) }
                )
            }
        }
    }

    private func providerButton(_ descriptor: ProviderDescriptor) -> some View {
        Button {
            pendingProviderID = descriptor.id
        } label: {
            AddProviderRow(descriptor: descriptor)
                .meterListRowHitTarget()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(UITestID.addProviderRow(descriptor.id.rawValue))
    }

    private func confirm(_ id: ProviderID) {
        guard confirmedProviderID == nil else { return }
        confirmedProviderID = id
        pendingProviderID = nil
    }

    /// `onDismiss` 仍在 presentation 收尾里。让出当前更新周期，
    /// NavigationStack 才会走推进，而不是跟 sheet 抢同一拍。
    private func addConfirmedProvider() {
        guard let id = confirmedProviderID else { return }
        confirmedProviderID = nil
        Task { @MainActor in
            await Task.yield()
            onAdd(id)
        }
    }

    private var memberIDs: Set<ProviderID> {
        Set(model.dashboard.memberships().map(\.providerID))
    }

    private var sections: [AddProviderCatalogSection] {
        AddProviderSearch.sections(
            from: AddProviderSearch.visibleDescriptors(
                query: query,
                excluding: memberIDs,
                browse: browse
            )
        )
    }

    private var showsMoreRow: Bool {
        AddProviderSearch.showsMoreRow(query: query, excluding: memberIDs)
    }

    private var showsManualRow: Bool {
        AddProviderSearch.matchesManualRow(query)
    }
}

#Preview("Light") {
    @Previewable @State var model = ServicesModel.preview
    NavigationStack {
        AddProviderView(model: model, onAdd: { _ in })
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var model = ServicesModel.preview
    NavigationStack {
        AddProviderView(model: model, onAdd: { _ in })
    }
    .preferredColorScheme(.dark)
}

#Preview("More") {
    @Previewable @State var model = ServicesModel.preview
    NavigationStack {
        AddProviderView(model: model, browse: .more, onAdd: { _ in })
    }
}

#Preview("Empty catalog") {
    @Previewable @State var model = ServicesModel.previewEmpty
    NavigationStack {
        AddProviderView(model: model, onAdd: { _ in })
    }
}
