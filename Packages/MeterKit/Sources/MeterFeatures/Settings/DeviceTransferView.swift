import SwiftUI
import MeterDesign

/// 设置 → 导入与导出。导出和导入共用这一页，分段切换。
struct DeviceTransferView: View {
    @Bindable var settings: SettingsModel
    @State private var tab: DeviceTransferTab
    @State private var exportModel: DeviceTransferExportModel
    @State private var importModel: DeviceTransferImportModel

    init(
        dashboard: DashboardModel,
        settings: SettingsModel,
        initialURL: URL? = nil,
        initialTab: DeviceTransferTab? = nil
    ) {
        self.settings = settings
        let prefersImport = FeatureLaunchArguments.openTransferImport
            || FeatureLaunchArguments.transferImportBanner != nil
        _tab = State(
            initialValue: initialTab ?? DeviceTransferTab.initial(
                inboundURL: initialURL,
                prefersImport: prefersImport
            )
        )
        _exportModel = State(initialValue: DeviceTransferExportModel(dashboard: dashboard))
        _importModel = State(
            initialValue: DeviceTransferImportModel(
                dashboard: dashboard,
                settings: settings,
                initialURL: initialURL
            )
        )
    }

    init(
        tab: DeviceTransferTab,
        exportModel: DeviceTransferExportModel,
        importModel: DeviceTransferImportModel,
        settings: SettingsModel
    ) {
        self.settings = settings
        _tab = State(initialValue: tab)
        _exportModel = State(initialValue: exportModel)
        _importModel = State(initialValue: importModel)
    }

    var body: some View {
        Group {
            switch tab {
            case .exporting:
                DeviceTransferExportView(model: exportModel)
            case .importing:
                DeviceTransferImportView(model: importModel)
            }
        }
        .navigationTitle(L("导入与导出"))
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .top, spacing: 0) {
            tabPicker
        }
        .onChange(of: settings.inboundTransferURL) { _, url in
            guard let url else { return }
            tab = .importing
            importModel.load(url: url)
        }
        .onDisappear {
            exportModel.cleanup()
        }
    }

    private var tabPicker: some View {
        Picker(selection: $tab) {
            ForEach(DeviceTransferTab.allCases) { item in
                Text(item.title).tag(item)
            }
        } label: {
            Text(L("导入与导出"))
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityLabel(L("导入与导出"))
        .padding(.horizontal, MeterSpacing.md)
        .padding(.vertical, MeterSpacing.xs)
    }
}

#Preview("Export Light") {
    NavigationStack {
        DeviceTransferView(
            tab: .exporting,
            exportModel: .previewReady,
            importModel: .previewIdle,
            settings: .preview
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Export Dark") {
    NavigationStack {
        DeviceTransferView(
            tab: .exporting,
            exportModel: .previewReady,
            importModel: .previewIdle,
            settings: .preview
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Import Light") {
    NavigationStack {
        DeviceTransferView(
            tab: .importing,
            exportModel: .previewReady,
            importModel: .previewIdle,
            settings: .preview
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Import Dark") {
    NavigationStack {
        DeviceTransferView(
            tab: .importing,
            exportModel: .previewReady,
            importModel: .previewIdle,
            settings: .preview
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Wrong code") {
    NavigationStack {
        DeviceTransferView(
            tab: .importing,
            exportModel: .previewReady,
            importModel: .previewWrongCode,
            settings: .preview
        )
    }
}

#Preview("Expired") {
    NavigationStack {
        DeviceTransferView(
            tab: .importing,
            exportModel: .previewReady,
            importModel: .previewExpired,
            settings: .preview
        )
    }
}

#Preview("Old schema") {
    NavigationStack {
        DeviceTransferView(
            tab: .importing,
            exportModel: .previewReady,
            importModel: .previewOldSchema,
            settings: .preview
        )
    }
}
