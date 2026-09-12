import Foundation
import Testing

/// iOS 26 给 `List(selection:)` 的 insetGrouped 选中行描一圈外框。
/// 横屏设置 / 服务列表改走按钮 + `PadRowSelected` 灰底。
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
}
