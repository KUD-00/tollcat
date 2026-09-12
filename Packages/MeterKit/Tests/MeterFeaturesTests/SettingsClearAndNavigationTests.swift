import Foundation
import Testing
@testable import MeterFeatures

@MainActor
struct SettingsClearAndNavigationTests {
    @Test("清全部数据会发成功令牌，仪表空态记得清过")
    func clearAllDataSetsSuccessAndEmptyCaption() {
        let dashboard = DashboardModel.preview
        let model = SettingsModel(
            dashboard: dashboard,
            persistenceStatus: .preview,
            reminderScheduler: InMemoryReminderScheduler()
        )
        #expect(!dashboard.didClearAllData)
        #expect(model.clearSuccessToken == 0)

        model.confirmClearAllData()

        #expect(model.clearErrorMessage == nil)
        #expect(model.clearSuccessToken == 1)
        #expect(dashboard.didClearAllData)
        #expect(dashboard.isEmpty)
    }

    @Test("深链 nil 落到设置列表；有路由就推进那一页")
    func presentStoresNavigation() {
        let model = SettingsModel.preview
        model.present(nil)
        #expect(model.pendingSettingsNavigation == .root)
        #expect(model.settingsNavigationGeneration == 1)

        model.present(.feedback)
        #expect(model.pendingSettingsNavigation == .route(.feedback))
        #expect(model.settingsNavigationGeneration == 2)
        #expect(model.consumePendingSettingsNavigation() == .route(.feedback))
        #expect(model.pendingSettingsNavigation == nil)
    }

    @Test("清除全部数据在设置列表最后一节")
    func clearAllDataIsLastSettingsSection() throws {
        let text = try GuardrailSourceScan.sourceText(named: "SettingsView.swift")
        let list = try #require(text.range(of: "private var settingsList: some View"))
        let body = text[list.lowerBound...]
        let tip = try #require(body.range(of: "tipSection"))
        let general = try #require(body.range(of: "generalSection"))
        let reminder = try #require(body.range(of: "ReminderSettingsSection"))
        let data = try #require(body.range(of: "dataSection"))
        let other = try #require(body.range(of: "otherSection"))
        let danger = try #require(body.range(of: "dangerSection"))
        #expect(tip.lowerBound < general.lowerBound)
        #expect(general.lowerBound < reminder.lowerBound)
        #expect(reminder.lowerBound < data.lowerBound)
        #expect(data.lowerBound < other.lowerBound)
        #expect(other.lowerBound < danger.lowerBound)
        #expect(!text.contains("dangerSection\n            otherSection"))
    }

    @Test("切 tab 有选择触感")
    func rootTabSelectionHaptic() throws {
        let root = try GuardrailSourceScan.sourceText(named: "RootView.swift")
        #expect(root.contains("sensoryFeedback(.selection, trigger: selectedTab)"))
    }

    @Test("添加服务搜索关掉自动更正")
    func addSearchDisablesAutocorrect() throws {
        let text = try GuardrailSourceScan.sourceText(named: "MeterColumnSearch.swift")
        #expect(text.contains("autocorrectionDisabled()"))
        #expect(text.contains("textInputAutocapitalization(.never)"))
    }

    @Test("向导两步有数字进度和系统关闭")
    func wizardShowsStepDigitsAndSystemClose() throws {
        let view = try GuardrailSourceScan.sourceText(named: "SetupWizardView.swift")
        let step = try GuardrailSourceScan.sourceText(named: "SetupWizardStep.swift")
        #expect(view.contains("navigationSubtitle"))
        #expect(view.contains("meterSheetClose"))
        #expect(view.contains("displayNumber"))
        #expect(step.contains("static var totalCount: Int { 2 }"))
        #expect(SetupWizardStep.guide.displayNumber == 1)
        #expect(SetupWizardStep.credentials.displayNumber == 2)
        #expect(SetupWizardStep.totalCount == 2)
    }
}
