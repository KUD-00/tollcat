import Foundation
import Testing
@testable import MeterFeatures

struct DeviceTransferSettingsTests {
    @Test("设置数据一组：读数信箱在最上，导入与导出合成一项")
    func dataSectionPutsInboxFirstAndMergesTransfer() throws {
        let text = try String(contentsOf: settingsView, encoding: .utf8)
        let inbox = try #require(text.range(of: "L(\"读数信箱\")"))
        let transfer = try #require(text.range(of: "L(\"导入与导出\")"))
        #expect(inbox.lowerBound < transfer.lowerBound)
        #expect(!text.contains("L(\"转移到新设备\")"))
        #expect(!text.contains("L(\"从旧设备导入\")"))
        #expect(!text.contains("route: .transferExport"))
        #expect(!text.contains("route: .transferImport"))
        #expect(!text.contains("open(.transferExport)"))
        #expect(!text.contains("open(.transferImport)"))
    }

    @Test("导入与导出页用分段控件切导出和导入")
    func combinedPageUsesSegmentedTabs() throws {
        let page = try String(contentsOf: deviceTransferView, encoding: .utf8)
        let tab = try String(contentsOf: deviceTransferTab, encoding: .utf8)
        #expect(page.contains("pickerStyle(.segmented)"))
        #expect(page.contains("safeAreaInset(edge: .top"))
        #expect(page.contains("labelsHidden()"))
        #expect(!page.contains("placement: .principal"))
        #expect(!page.contains("Color.meterGroupedBackground"))
        #expect(page.contains("L(\"导入与导出\")"))
        #expect(page.contains("DeviceTransferExportView"))
        #expect(page.contains("DeviceTransferImportView"))
        #expect(tab.contains("L(\"导出\")"))
        #expect(tab.contains("L(\"导入\")"))
    }

    @Test("打开迁移文件落在导入那一档；平时默认导出")
    func inboundFileSelectsImportTab() {
        let file = URL(fileURLWithPath: "/tmp/TollCat-transfer.tollcat")
        #expect(DeviceTransferTab.initial(inboundURL: file, prefersImport: false) == .importing)
        #expect(DeviceTransferTab.initial(inboundURL: nil, prefersImport: true) == .importing)
        #expect(DeviceTransferTab.initial(inboundURL: nil, prefersImport: false) == .exporting)
    }

    @Test("路由只留导入与导出一项")
    func settingsRouteMergesTransfer() throws {
        let text = try String(contentsOf: settingsRoute, encoding: .utf8)
        #expect(text.contains("case importExport"))
        #expect(!text.contains("case transferExport"))
        #expect(!text.contains("case transferImport"))
    }

    private var settingsRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/MeterFeatures/Settings")
    }

    private var settingsView: URL {
        settingsRoot.appending(path: "SettingsView.swift")
    }

    private var deviceTransferView: URL {
        settingsRoot.appending(path: "DeviceTransferView.swift")
    }

    private var deviceTransferTab: URL {
        settingsRoot.appending(path: "DeviceTransferTab.swift")
    }

    private var settingsRoute: URL {
        settingsRoot.appending(path: "SettingsRoute.swift")
    }
}
