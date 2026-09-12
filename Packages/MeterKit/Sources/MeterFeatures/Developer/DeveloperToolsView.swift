#if DEBUG
import SwiftUI
import MeterDesign

struct DeveloperToolsView: View {
    /// Mac 列内推目的地要现场组装（`DeveloperToolRegistry` 需要 dashboard），
    /// iPhone / iPad 仍走 `DeveloperSettingsDestinations` 的中央注册。
    var model: SettingsModel

    var body: some View {
        MeterGroupedList {
            ForEach(DeveloperToolSection.allCases) { section in
                Section {
                    ForEach(section.items) { id in
                        MeterColumnLink(
                            value: id,
                            title: Text(id.title),
                            destination: {
                                DeveloperToolRegistry.view(
                                    id: id,
                                    dashboard: model.dashboard,
                                    persistenceStatus: model.persistenceStatus
                                )
                            }
                        ) {
                            Label(id.title, systemImage: id.systemImage)
                        }
                    }
                } header: {
                    if let title = section.title {
                        Text(title)
                    }
                }
            }
        }
        .navigationTitle(L("开发"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Light") {
    NavigationStack {
        DeveloperToolsView(model: .preview)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        DeveloperToolsView(model: .preview)
    }
    .preferredColorScheme(.dark)
}
#endif
