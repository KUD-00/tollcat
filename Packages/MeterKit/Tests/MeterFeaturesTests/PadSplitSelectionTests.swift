import Foundation
import Testing
import MeterCore
@testable import MeterFeatures

/// iOS 26 给 `List(selection:)` 的 insetGrouped 选中行描一圈外框。
/// 横屏设置 / 服务列表改走按钮 + `PadRowSelected` 灰底。
///
/// 宽壳详情列靠 `selectedProviderID` 活着，不是导航栈。清空一家之后必须丢掉
/// 选中，第三栏才能回到「选择一项服务」；结束只归档，选中要留。
@MainActor
struct PadSplitSelectionTests {
    @Test("横屏设置和服务列表不用 List(selection:)")
    func padInsetGroupedListsDoNotBindSelection() throws {
        let settings = try GuardrailSourceScan.sourceText(named: "SettingsView.swift")
        let services = try GuardrailSourceScan.sourceText(named: "ServicesView.swift")
        #expect(!settings.contains("List(selection:"))
        #expect(!services.contains("List(selection:"))
        #expect(settings.contains("PadSplitRowButton"))
        #expect(services.contains("PadSplitRowButton"))
    }

    @Test("选中只铺一层系统灰")
    func padRowSelectedUsesSystemFill() throws {
        let text = try GuardrailSourceScan.sourceText(named: "PadRowSelected.swift")
        #expect(text.contains("meterTertiarySystemFill"))
        #expect(text.contains("meterSecondaryGroupedBackground"))
    }

    @Test("清空一家之后宽壳不再选中它")
    func purgeDropsPadSelection() async throws {
        let model = ServicesModel.preview
        let id = try #require(model.connectedRows.first?.id)
        model.selectedProviderID = id
        try await model.dashboard.purgeMembership(id)
        model.reload()
        #expect(model.selectedProviderID == nil)
        #expect(!model.rows.contains { $0.id == id })
    }

    @Test("结束一家之后宽壳还留着详情")
    func archiveKeepsPadSelection() async throws {
        let model = ServicesModel.preview
        let id = try #require(model.connectedRows.first?.id)
        model.selectedProviderID = id
        try await model.dashboard.archiveMembership(id)
        model.reload()
        #expect(model.selectedProviderID == id)
        #expect(model.rows.contains { $0.id == id && $0.isEnded })
    }

    @Test("reload 去重也不挡：选中的已经不是成员，照样丢掉")
    func reloadDropsStaleSelectionEvenWhenStampMatches() {
        let model = ServicesModel.preview
        model.reload()
        model.selectedProviderID = .clerk
        #expect(!model.dashboard.memberships().contains { $0.providerID == .clerk })
        model.reload()
        #expect(model.selectedProviderID == nil)
    }

    @Test("选中变 nil 也要卸掉列内栈，不能只在换成另一家时清")
    func padSelectionChangeClearsColumnStackOnNil() throws {
        let services = try GuardrailSourceScan.sourceText(named: "ServicesView.swift")
        #expect(services.contains("guard usesPadChrome, old != new"))
        #expect(!services.contains("guard usesPadChrome, let new, old != new"))
        let model = try GuardrailSourceScan.sourceText(named: "ServicesModel.swift")
        #expect(model.contains("selectedProviderID = nil"))
        let detail = try GuardrailSourceScan.sourceText(named: "ProviderDetailView.swift")
        #expect(detail.contains("macColumnStack.pop()"))
    }
}
